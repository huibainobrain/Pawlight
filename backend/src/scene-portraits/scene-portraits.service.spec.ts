import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ScenePortraitsService } from './scene-portraits.service';
import { ScenePortraitProviderNotConfiguredError } from './providers/errors';
import {
  MAX_GENERATION_ATTEMPTS,
  MAX_VIDEO_POLL_ATTEMPTS,
  VIDEO_POLL_INTERVAL_MS,
} from './scene-portraits.constants';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods
// ScenePortraitsService actually calls. Naturally typed (no `any`) so
// `.mockResolvedValue(...)` stays permissive; cast to PrismaService only at
// the point each test constructs the service, since the mock is
// intentionally not a full PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    pet: { findUnique: jest.fn(), update: jest.fn() },
    entitlement: { findUnique: jest.fn() },
    photo: { findFirst: jest.fn() },
    scenePortraitJob: {
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      findMany: jest.fn(),
    },
    scenePortraitCandidate: { findUnique: jest.fn(), findMany: jest.fn() },
    $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

// StorageService/ImageGenProvider/VideoGenProvider are plain interfaces (see
// storage.interface.ts, image-gen.provider.ts, video-gen.provider.ts), so
// these objects satisfy them structurally — no cast needed.
function makeStorage() {
  return {
    upload: jest
      .fn()
      .mockImplementation(({ key }: { key: string }) =>
        Promise.resolve({ key, url: `https://r2.example/${key}` }),
      ),
    delete: jest.fn().mockResolvedValue(undefined),
  };
}

function makeImageGen() {
  return { generateCandidates: jest.fn() };
}

function makeVideoGen() {
  return { submitImageToVideo: jest.fn(), pollTask: jest.fn() };
}

function makeService(
  prisma = makePrisma(),
  storage = makeStorage(),
  imageGen = makeImageGen(),
  videoGen = makeVideoGen(),
) {
  const service = new ScenePortraitsService(
    asPrismaService(prisma),
    storage,
    imageGen,
    videoGen,
  );
  return { service, prisma, storage, imageGen, videoGen };
}

describe('ScenePortraitsService.startJob', () => {
  it('rejects a FREE-tier user with PAID_ONLY', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.entitlement.findUnique.mockResolvedValue({ tier: 'FREE' });

    const promise = service.startJob('user-1', 'pet-1', 'a sunny window');
    await expect(promise).rejects.toBeInstanceOf(ForbiddenException);
    await promise.catch((err: ForbiddenException) => {
      expect(err.getResponse()).toMatchObject({ code: 'PAID_ONLY' });
    });
  });

  it('rejects when the pet has no MAIN photo', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.entitlement.findUnique.mockResolvedValue({ tier: 'PAID' });
    prisma.photo.findFirst.mockResolvedValue(null);

    const promise = service.startJob('user-1', 'pet-1', 'a sunny window');
    await expect(promise).rejects.toBeInstanceOf(BadRequestException);
    await promise.catch((err: BadRequestException) => {
      expect(err.getResponse()).toMatchObject({ code: 'NO_MAIN_PHOTO' });
    });
  });

  it(`rejects at the ${MAX_GENERATION_ATTEMPTS}-attempt cap`, async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.entitlement.findUnique.mockResolvedValue({ tier: 'PAID' });
    prisma.photo.findFirst.mockResolvedValue({
      id: 'photo-1',
      r2Url: 'https://r2/main.jpg',
    });
    prisma.scenePortraitJob.count.mockResolvedValue(MAX_GENERATION_ATTEMPTS);

    const promise = service.startJob('user-1', 'pet-1', 'a sunny window');
    await expect(promise).rejects.toBeInstanceOf(BadRequestException);
    await promise.catch((err: BadRequestException) => {
      expect(err.getResponse()).toMatchObject({
        code: 'SCENE_PORTRAIT_ATTEMPTS_EXHAUSTED',
        maxAttempts: MAX_GENERATION_ATTEMPTS,
      });
    });
    expect(prisma.scenePortraitJob.create).not.toHaveBeenCalled();
  });

  it('does not count FAILED jobs against the attempt cap', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.entitlement.findUnique.mockResolvedValue({ tier: 'PAID' });
    prisma.photo.findFirst.mockResolvedValue({
      id: 'photo-1',
      r2Url: 'https://r2/main.jpg',
    });
    prisma.scenePortraitJob.create.mockResolvedValue({
      id: 'job-1',
      status: 'QUEUED',
    });
    jest
      .spyOn(service as any, 'runImageGeneration')
      .mockResolvedValue(undefined);

    await service.startJob('user-1', 'pet-1', 'a sunny window');

    expect(prisma.scenePortraitJob.count).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { petId: 'pet-1', status: { not: 'FAILED' } },
      }),
    );
  });

  it('rejects a non-owner', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'owner-1' });

    await expect(
      service.startJob('intruder-1', 'pet-1', 'x'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects a nonexistent pet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue(null);

    await expect(
      service.startJob('user-1', 'missing-pet', 'x'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('creates a QUEUED job and triggers image generation on success', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.entitlement.findUnique.mockResolvedValue({ tier: 'PAID' });
    prisma.photo.findFirst.mockResolvedValue({
      id: 'photo-1',
      r2Url: 'https://r2/main.jpg',
    });
    prisma.scenePortraitJob.count.mockResolvedValue(0);
    prisma.scenePortraitJob.create.mockResolvedValue({
      id: 'job-1',
      status: 'QUEUED',
      candidates: [],
    });
    const runImageGeneration = jest
      .spyOn(service as any, 'runImageGeneration')
      .mockResolvedValue(undefined);

    const job = await service.startJob('user-1', 'pet-1', 'a sunny window');

    expect(job).toMatchObject({ id: 'job-1', status: 'QUEUED' });
    expect(prisma.scenePortraitJob.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { petId: 'pet-1', sceneText: 'a sunny window', status: 'QUEUED' },
      }),
    );
    expect(runImageGeneration).toHaveBeenCalledWith(
      'job-1',
      'https://r2/main.jpg',
      'a sunny window',
    );
  });
});

describe('ScenePortraitsService.runImageGeneration (called directly)', () => {
  it('uploads every generated candidate to R2 and reaches CANDIDATES_READY', async () => {
    const { service, prisma, storage, imageGen } = makeService();
    imageGen.generateCandidates.mockResolvedValue([
      { buffer: Buffer.from('a'), contentType: 'image/png' },
      { buffer: Buffer.from('b'), contentType: 'image/png' },
    ]);
    prisma.scenePortraitJob.update.mockResolvedValue({});

    await (service as any).runImageGeneration(
      'job-1',
      'https://r2/main.jpg',
      'a sunny window',
    );

    expect(storage.upload).toHaveBeenCalledTimes(2);
    const finalUpdateCall = prisma.scenePortraitJob.update.mock.calls[1][0];
    expect(finalUpdateCall.where).toEqual({ id: 'job-1' });
    expect(finalUpdateCall.data.status).toBe('CANDIDATES_READY');
    expect(finalUpdateCall.data.candidates.create).toHaveLength(2);
  });

  it('marks the job FAILED with GENERATION_FAILED when the provider throws', async () => {
    const { service, prisma, imageGen } = makeService();
    imageGen.generateCandidates.mockRejectedValue(new Error('vendor 500'));
    prisma.scenePortraitJob.update.mockResolvedValue({});

    await (service as any).runImageGeneration(
      'job-1',
      'https://r2/main.jpg',
      'x',
    );

    const failCall = prisma.scenePortraitJob.update.mock.calls.find(
      (c: any[]) => c[0].data.status === 'FAILED',
    );
    expect(failCall[0]).toMatchObject({
      where: { id: 'job-1' },
      data: {
        status: 'FAILED',
        errorCode: 'GENERATION_FAILED',
        errorMessage: 'vendor 500',
      },
    });
  });

  it('marks the job FAILED with PROVIDER_NOT_CONFIGURED for a missing-key error', async () => {
    const { service, prisma, imageGen } = makeService();
    imageGen.generateCandidates.mockRejectedValue(
      new ScenePortraitProviderNotConfiguredError('ArkImageGenProvider'),
    );
    prisma.scenePortraitJob.update.mockResolvedValue({});

    await (service as any).runImageGeneration(
      'job-1',
      'https://r2/main.jpg',
      'x',
    );

    const failCall = prisma.scenePortraitJob.update.mock.calls.find(
      (c: any[]) => c[0].data.status === 'FAILED',
    );
    expect(failCall[0].data.errorCode).toBe('PROVIDER_NOT_CONFIGURED');
  });
});

describe('ScenePortraitsService.selectCandidate', () => {
  it('rejects when the job is not CANDIDATES_READY', async () => {
    const { service, prisma } = makeService();
    prisma.scenePortraitJob.findUnique.mockResolvedValue({
      id: 'job-1',
      status: 'GENERATING_IMAGE',
      pet: { userId: 'user-1' },
    });

    const promise = service.selectCandidate('user-1', 'job-1', 'candidate-1');
    await expect(promise).rejects.toBeInstanceOf(BadRequestException);
    await promise.catch((err: BadRequestException) => {
      expect(err.getResponse()).toMatchObject({ code: 'JOB_NOT_READY' });
    });
  });

  it('rejects a candidate that does not belong to this job', async () => {
    const { service, prisma } = makeService();
    prisma.scenePortraitJob.findUnique.mockResolvedValue({
      id: 'job-1',
      status: 'CANDIDATES_READY',
      pet: { userId: 'user-1' },
    });
    prisma.scenePortraitCandidate.findUnique.mockResolvedValue({
      id: 'candidate-1',
      jobId: 'other-job',
    });

    await expect(
      service.selectCandidate('user-1', 'job-1', 'candidate-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects a job belonging to another user', async () => {
    const { service, prisma } = makeService();
    prisma.scenePortraitJob.findUnique.mockResolvedValue({
      id: 'job-1',
      status: 'CANDIDATES_READY',
      pet: { userId: 'owner-1' },
    });

    await expect(
      service.selectCandidate('intruder-1', 'job-1', 'candidate-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('advances to GENERATING_VIDEO and triggers video generation', async () => {
    const { service, prisma } = makeService();
    prisma.scenePortraitJob.findUnique.mockResolvedValue({
      id: 'job-1',
      status: 'CANDIDATES_READY',
      pet: { userId: 'user-1' },
    });
    prisma.scenePortraitCandidate.findUnique.mockResolvedValue({
      id: 'candidate-1',
      jobId: 'job-1',
      r2Url: 'https://r2/candidate-1.png',
    });
    prisma.scenePortraitJob.update.mockResolvedValue({
      id: 'job-1',
      status: 'GENERATING_VIDEO',
    });
    const runVideoGeneration = jest
      .spyOn(service as any, 'runVideoGeneration')
      .mockResolvedValue(undefined);

    const result = await service.selectCandidate(
      'user-1',
      'job-1',
      'candidate-1',
    );

    expect(result).toMatchObject({ status: 'GENERATING_VIDEO' });
    expect(runVideoGeneration).toHaveBeenCalledWith(
      'job-1',
      'https://r2/candidate-1.png',
    );
  });
});

describe('ScenePortraitsService.runVideoGeneration (called directly)', () => {
  it('uploads the finished video and DONE-transitions job + pet in one transaction', async () => {
    const { service, prisma, storage, videoGen } = makeService();
    videoGen.submitImageToVideo.mockResolvedValue({ providerTaskId: 'task-1' });
    videoGen.pollTask.mockResolvedValue({
      status: 'succeeded',
      video: { buffer: Buffer.from('video-bytes'), contentType: 'video/mp4' },
    });
    prisma.scenePortraitJob.findUniqueOrThrow.mockResolvedValue({
      id: 'job-1',
      petId: 'pet-1',
    });
    prisma.scenePortraitJob.update.mockResolvedValue({});
    prisma.pet.update.mockResolvedValue({});

    await (service as any).runVideoGeneration(
      'job-1',
      'https://r2/candidate-1.png',
    );

    expect(storage.upload).toHaveBeenCalledWith(
      expect.objectContaining({
        buffer: Buffer.from('video-bytes'),
        contentType: 'video/mp4',
      }),
    );
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    // Both updates were made (and wrapped together in the $transaction call above)
    // so job completion and Pet activation are atomic.
    expect(prisma.scenePortraitJob.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'job-1' },
        data: expect.objectContaining({ status: 'DONE' }),
      }),
    );
    expect(prisma.pet.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'pet-1' },
        data: expect.objectContaining({
          observationVideoJobId: 'job-1',
          observationVideoUrl: expect.stringContaining('https://r2.example/'),
        }),
      }),
    );
  });

  it('marks the job FAILED when the video provider reports failed', async () => {
    const { service, prisma, videoGen } = makeService();
    videoGen.submitImageToVideo.mockResolvedValue({ providerTaskId: 'task-1' });
    videoGen.pollTask.mockResolvedValue({
      status: 'failed',
      errorMessage: 'moderation rejected',
    });
    prisma.scenePortraitJob.update.mockResolvedValue({});

    await (service as any).runVideoGeneration(
      'job-1',
      'https://r2/candidate-1.png',
    );

    expect(prisma.scenePortraitJob.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'job-1' },
        data: expect.objectContaining({
          status: 'FAILED',
          errorMessage: 'moderation rejected',
        }),
      }),
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it(
    `marks the job FAILED after ${MAX_VIDEO_POLL_ATTEMPTS} consecutive ` +
      'pending polls, without touching Pet',
    async () => {
      jest.useFakeTimers();
      try {
        const { service, prisma, videoGen } = makeService();
        videoGen.submitImageToVideo.mockResolvedValue({
          providerTaskId: 'task-1',
        });
        // Never reports 'succeeded' or 'failed' — exercises the timeout path
        // in ScenePortraitsService.pollVideoUntilDone, not a vendor error.
        videoGen.pollTask.mockResolvedValue({ status: 'pending' });
        prisma.scenePortraitJob.update.mockResolvedValue({});

        const generation = (service as any).runVideoGeneration(
          'job-1',
          'https://r2/candidate-1.png',
        );

        // pollVideoUntilDone sleeps VIDEO_POLL_INTERVAL_MS after every
        // pending poll, including the last one before giving up — advancing
        // by the full ceiling in one go lets Jest's fake-timer/microtask
        // interleaving drive all of them without a real 3-minute wait.
        await jest.advanceTimersByTimeAsync(
          VIDEO_POLL_INTERVAL_MS * MAX_VIDEO_POLL_ATTEMPTS,
        );
        await generation;

        expect(videoGen.pollTask).toHaveBeenCalledTimes(
          MAX_VIDEO_POLL_ATTEMPTS,
        );
        // Failure path only — the DONE/Pet-activation transition is a
        // completely separate code path (see the 'succeeded' test above).
        expect(prisma.$transaction).not.toHaveBeenCalled();
        expect(prisma.pet.update).not.toHaveBeenCalled();
        expect(prisma.scenePortraitJob.update).toHaveBeenCalledWith(
          expect.objectContaining({
            where: { id: 'job-1' },
            data: expect.objectContaining({
              status: 'FAILED',
              errorCode: 'GENERATION_FAILED',
              errorMessage: 'Video generation timed out',
            }),
          }),
        );
        expect(jest.getTimerCount()).toBe(0);
      } finally {
        jest.useRealTimers();
      }
    },
  );
});

describe('ScenePortraitsService.revertObservationWindow', () => {
  it('clears the three observationVideo* fields', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.pet.update.mockResolvedValue({});

    const result = await service.revertObservationWindow('user-1', 'pet-1');

    expect(prisma.pet.update).toHaveBeenCalledWith({
      where: { id: 'pet-1' },
      data: {
        observationVideoJobId: null,
        observationVideoKey: null,
        observationVideoUrl: null,
      },
    });
    expect(result).toEqual({ status: 'success', petId: 'pet-1' });
  });

  it('rejects a non-owner', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'owner-1' });

    await expect(
      service.revertObservationWindow('intruder-1', 'pet-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});

describe('ScenePortraitsService.deleteAllForUser', () => {
  it('deletes R2 objects for every candidate and every completed job video', async () => {
    const { service, prisma, storage } = makeService();
    prisma.scenePortraitCandidate.findMany.mockResolvedValue([
      { r2Key: 'c1' },
      { r2Key: 'c2' },
    ]);
    prisma.scenePortraitJob.findMany.mockResolvedValue([{ videoR2Key: 'v1' }]);

    await service.deleteAllForUser('user-1');

    expect(storage.delete).toHaveBeenCalledWith('c1');
    expect(storage.delete).toHaveBeenCalledWith('c2');
    expect(storage.delete).toHaveBeenCalledWith('v1');
    expect(storage.delete).toHaveBeenCalledTimes(3);
  });
});
