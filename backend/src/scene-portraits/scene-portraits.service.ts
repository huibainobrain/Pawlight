import {
  Inject,
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from '../storage/r2-storage.service';
import { IMAGE_GEN_PROVIDER } from './providers/image-gen.provider';
import type { ImageGenProvider } from './providers/image-gen.provider';
import { VIDEO_GEN_PROVIDER } from './providers/video-gen.provider';
import type { VideoGenProvider } from './providers/video-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './providers/errors';
import { buildMotionPrompt } from './prompts';
import {
  CANDIDATE_COUNT,
  MAX_GENERATION_ATTEMPTS,
  VIDEO_DURATION_SECONDS,
  VIDEO_POLL_INTERVAL_MS,
  MAX_VIDEO_POLL_ATTEMPTS,
} from './scene-portraits.constants';

@Injectable()
export class ScenePortraitsService {
  private readonly logger = new Logger(ScenePortraitsService.name);

  constructor(
    private prisma: PrismaService,
    private storage: R2StorageService,
    @Inject(IMAGE_GEN_PROVIDER) private imageGen: ImageGenProvider,
    @Inject(VIDEO_GEN_PROVIDER) private videoGen: VideoGenProvider,
  ) {}

  async startJob(userId: string, petId: string, sceneText: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();

    const entitlement = await this.prisma.entitlement.findUnique({ where: { userId } });
    if (entitlement?.tier !== 'PAID') {
      throw new ForbiddenException({
        code: 'PAID_ONLY',
        message: '这是完整纪念空间的功能',
      });
    }

    const mainPhoto = await this.prisma.photo.findFirst({ where: { petId, type: 'MAIN' } });
    if (!mainPhoto) {
      throw new BadRequestException({
        code: 'NO_MAIN_PHOTO',
        message: '请先上传一张主照片',
      });
    }

    const attemptCount = await this.prisma.scenePortraitJob.count({
      where: { petId, status: { not: 'FAILED' } },
    });
    if (attemptCount >= MAX_GENERATION_ATTEMPTS) {
      throw new BadRequestException({
        code: 'SCENE_PORTRAIT_ATTEMPTS_EXHAUSTED',
        message: '生成次数已用完',
        maxAttempts: MAX_GENERATION_ATTEMPTS,
      });
    }

    const job = await this.prisma.scenePortraitJob.create({
      data: { petId, sceneText, status: 'QUEUED' },
      include: { candidates: true },
    });

    void this.runImageGeneration(job.id, mainPhoto.r2Url, sceneText);

    return job;
  }

  async getJob(userId: string, jobId: string) {
    const job = await this.assertJobOwner(userId, jobId);
    return this.prisma.scenePortraitJob.findUnique({
      where: { id: job.id },
      include: { candidates: { orderBy: { sortOrder: 'asc' } } },
    });
  }

  async selectCandidate(userId: string, jobId: string, candidateId: string) {
    const job = await this.assertJobOwner(userId, jobId);
    if (job.status !== 'CANDIDATES_READY') {
      throw new BadRequestException({
        code: 'JOB_NOT_READY',
        message: '候选画像还没准备好',
      });
    }
    const candidate = await this.prisma.scenePortraitCandidate.findUnique({
      where: { id: candidateId },
    });
    if (!candidate || candidate.jobId !== jobId) {
      throw new NotFoundException('Candidate not found');
    }

    const updated = await this.prisma.scenePortraitJob.update({
      where: { id: jobId },
      data: { selectedCandidateId: candidateId, status: 'GENERATING_VIDEO' },
      include: { candidates: { orderBy: { sortOrder: 'asc' } } },
    });

    void this.runVideoGeneration(jobId, candidate.r2Url);

    return updated;
  }

  async revertObservationWindow(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();

    await this.prisma.pet.update({
      where: { id: petId },
      data: {
        observationVideoJobId: null,
        observationVideoKey: null,
        observationVideoUrl: null,
      },
    });
    return { status: 'success', petId };
  }

  // Used by account deletion (AuthService.deleteAccount): removes every
  // scene-portrait R2 object owned by this user's pet(s). DB rows are left to
  // the Pet -> User cascade delete, which can't reach into R2 on its own.
  async deleteAllForUser(userId: string) {
    const candidates = await this.prisma.scenePortraitCandidate.findMany({
      where: { job: { pet: { userId } } },
      select: { r2Key: true },
    });
    const jobsWithVideo = await this.prisma.scenePortraitJob.findMany({
      where: { pet: { userId }, videoR2Key: { not: null } },
      select: { videoR2Key: true },
    });
    await Promise.all([
      ...candidates.map((c) => this.storage.delete(c.r2Key)),
      ...jobsWithVideo.map((j) => this.storage.delete(j.videoR2Key as string)),
    ]);
  }

  private async assertJobOwner(userId: string, jobId: string) {
    const job = await this.prisma.scenePortraitJob.findUnique({
      where: { id: jobId },
      include: { pet: true },
    });
    if (!job) throw new NotFoundException('Job not found');
    if (job.pet.userId !== userId) throw new ForbiddenException();
    return job;
  }

  // Fire-and-forget (called without await) — no queue/worker infra exists in
  // this backend, so generation runs in-process. Known tradeoff: a job stuck
  // mid-flight is lost if the server process restarts; accepted as an MVP
  // limitation (see the plan doc).
  private async runImageGeneration(jobId: string, referenceImageUrl: string, sceneText: string) {
    try {
      await this.prisma.scenePortraitJob.update({
        where: { id: jobId },
        data: { status: 'GENERATING_IMAGE' },
      });

      const images = await this.imageGen.generateCandidates({
        referenceImageUrl,
        sceneText,
        count: CANDIDATE_COUNT,
      });

      const uploaded = await Promise.all(
        images.map((image, index) => this.uploadCandidate(jobId, image, index)),
      );

      await this.prisma.scenePortraitJob.update({
        where: { id: jobId },
        data: {
          status: 'CANDIDATES_READY',
          candidates: { create: uploaded },
        },
      });
    } catch (err) {
      await this.markFailed(jobId, err);
    }
  }

  private async uploadCandidate(
    jobId: string,
    image: { buffer: Buffer; contentType: string },
    index: number,
  ) {
    const ext = image.contentType.includes('png') ? 'png' : 'jpg';
    const key = `scene-portraits/${jobId}/candidate-${index}-${randomBytes(4).toString('hex')}.${ext}`;
    const { url } = await this.storage.upload({
      key,
      buffer: image.buffer,
      contentType: image.contentType,
    });
    return { r2Key: key, r2Url: url, sortOrder: index };
  }

  private async runVideoGeneration(jobId: string, selectedImageUrl: string) {
    try {
      const { providerTaskId } = await this.videoGen.submitImageToVideo({
        imageUrl: selectedImageUrl,
        motionPrompt: buildMotionPrompt(),
        durationSeconds: VIDEO_DURATION_SECONDS,
      });

      const video = await this.pollVideoUntilDone(providerTaskId);

      const ext = video.contentType.includes('mp4') ? 'mp4' : 'mov';
      const key = `scene-portraits/${jobId}/video-${randomBytes(4).toString('hex')}.${ext}`;
      const { url } = await this.storage.upload({
        key,
        buffer: video.buffer,
        contentType: video.contentType,
      });

      const job = await this.prisma.scenePortraitJob.findUniqueOrThrow({ where: { id: jobId } });

      // Job completion auto-activates the observation window — no separate
      // "confirm" endpoint, matching "pick one, no further confirmation".
      await this.prisma.$transaction([
        this.prisma.scenePortraitJob.update({
          where: { id: jobId },
          data: { status: 'DONE', videoR2Key: key, videoR2Url: url },
        }),
        this.prisma.pet.update({
          where: { id: job.petId },
          data: {
            observationVideoJobId: jobId,
            observationVideoKey: key,
            observationVideoUrl: url,
          },
        }),
      ]);
    } catch (err) {
      await this.markFailed(jobId, err);
    }
  }

  private async pollVideoUntilDone(providerTaskId: string) {
    for (let attempt = 0; attempt < MAX_VIDEO_POLL_ATTEMPTS; attempt++) {
      const result = await this.videoGen.pollTask(providerTaskId);
      if (result.status === 'succeeded') return result.video;
      if (result.status === 'failed') throw new Error(result.errorMessage);
      await sleep(VIDEO_POLL_INTERVAL_MS);
    }
    throw new Error('Video generation timed out');
  }

  private async markFailed(jobId: string, err: unknown) {
    const isNotConfigured = err instanceof ScenePortraitProviderNotConfiguredError;
    const errorCode = isNotConfigured ? 'PROVIDER_NOT_CONFIGURED' : 'GENERATION_FAILED';
    const errorMessage = err instanceof Error ? err.message : String(err);
    this.logger.warn(`Scene portrait job ${jobId} failed: ${errorMessage}`);
    await this.prisma.scenePortraitJob.update({
      where: { id: jobId },
      data: { status: 'FAILED', errorCode, errorMessage },
    });
  }
}

function sleep(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}
