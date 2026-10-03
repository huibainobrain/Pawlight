import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PlanetLifeService } from './planet-life.service';
import { GiftsService } from './gifts.service';
import { PlanetEventGenerationService } from './planet-event-generation.service';
import { PrismaService } from '../prisma/prisma.service';

function makePrisma() {
  return {
    pet: { findUnique: jest.fn() },
    entitlement: { findUnique: jest.fn() },
    planetLifeState: {
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    },
    planetEvent: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    },
    giftInstance: { deleteMany: jest.fn() },
    eventTemplate: { upsert: jest.fn() },
    giftAsset: { upsert: jest.fn() },
    giftProduct: { upsert: jest.fn() },
    locationAsset: { upsert: jest.fn() },
    actionAsset: { upsert: jest.fn() },
    contentAsset: { upsert: jest.fn() },
    $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

function makeStorage() {
  return { upload: jest.fn(), delete: jest.fn().mockResolvedValue(undefined) };
}

function makeGiftsService() {
  return { revertToPending: jest.fn().mockResolvedValue(undefined) };
}

function asGiftsService(giftsService: ReturnType<typeof makeGiftsService>) {
  return giftsService as unknown as GiftsService;
}

function makeGenerationService() {
  return {
    runTick: jest.fn().mockResolvedValue(undefined),
    getUnconfiguredRealProviders: jest.fn().mockReturnValue([]),
  };
}

function asGenerationService(
  generationService: ReturnType<typeof makeGenerationService>,
) {
  return generationService as unknown as PlanetEventGenerationService;
}

function makeService(
  prisma = makePrisma(),
  storage = makeStorage(),
  giftsService = makeGiftsService(),
  generationService = makeGenerationService(),
) {
  const service = new PlanetLifeService(
    asPrismaService(prisma),
    storage,
    asGiftsService(giftsService),
    asGenerationService(generationService),
  );
  return { service, prisma, storage, giftsService, generationService };
}

describe('PlanetLifeService.onModuleInit (reference data seeding)', () => {
  it('upserts the P0 test EventTemplate and GiftAsset/GiftProduct', async () => {
    const { service, prisma } = makeService();
    prisma.giftAsset.upsert.mockResolvedValue({ id: 'asset-ball' });

    await service.onModuleInit();

    expect(prisma.eventTemplate.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { key: 'garden_rest' } }),
    );
    expect(prisma.giftAsset.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { key: 'ball' } }),
    );
    expect(prisma.giftProduct.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { productId: 'com.pawlight.gift.ball.test' },
      }),
    );
  });

  // This round's restructuring: EventTemplate must reference content assets
  // by key, not embed raw strings — so seeding must create the referenced
  // LocationAsset/ActionAsset/ContentAsset rows, and the template's own
  // upsert payload must point at their keys, not at natural-language pools.
  it('seeds LocationAsset/ActionAsset/ContentAsset and has the template reference them by key', async () => {
    const { service, prisma } = makeService();
    prisma.giftAsset.upsert.mockResolvedValue({ id: 'asset-ball' });

    await service.onModuleInit();

    expect(prisma.locationAsset.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { key: 'garden_corner' } }),
    );
    expect(prisma.actionAsset.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { key: 'resting' } }),
    );
    const contentAssetKeys = prisma.contentAsset.upsert.mock.calls.map(
      (call: unknown[]) => (call[0] as { where: { key: string } }).where.key,
    );
    expect(contentAssetKeys).toEqual(
      expect.arrayContaining([
        'daytime',
        'dusk',
        'sunny',
        'breezy',
        'flowers_grass',
      ]),
    );

    const templateArg = prisma.eventTemplate.upsert.mock.calls[0][0] as {
      create: Record<string, unknown>;
    };
    expect(templateArg.create).toMatchObject({
      locationKeys: ['garden_corner'],
      actionKeys: ['resting'],
      ambientDetailKeys: ['flowers_grass'],
    });
  });
});

describe('PlanetLifeService.enable', () => {
  it('rejects a non-paid account with PAID_ONLY', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      observationVideoUrl: 'https://r2/video.mp4',
    });
    prisma.entitlement.findUnique.mockResolvedValue({
      starLifeEnabled: false,
    });

    const promise = service.enable('user-1', 'pet-1', true);
    await expect(promise).rejects.toBeInstanceOf(ForbiddenException);
    await promise.catch((err: ForbiddenException) =>
      expect(err.getResponse()).toMatchObject({ code: 'PAID_ONLY' }),
    );
  });

  // PRD §5: first enable requires a completed AI scene (observationVideoUrl).
  it('rejects a paid account with no completed AI scene yet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      observationVideoUrl: null,
    });
    prisma.entitlement.findUnique.mockResolvedValue({
      starLifeEnabled: true,
    });

    const promise = service.enable('user-1', 'pet-1', true);
    await expect(promise).rejects.toBeInstanceOf(BadRequestException);
    await promise.catch((err: BadRequestException) =>
      expect(err.getResponse()).toMatchObject({
        code: 'NO_SCENE_PORTRAIT_YET',
      }),
    );
  });

  it('enables with a first-wait window when gated correctly', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      observationVideoUrl: 'https://r2/video.mp4',
    });
    prisma.entitlement.findUnique.mockResolvedValue({
      starLifeEnabled: true,
    });
    prisma.planetLifeState.upsert.mockResolvedValue({ enabled: true });

    await service.enable('user-1', 'pet-1', true);

    const call = prisma.planetLifeState.upsert.mock.calls[0][0];
    expect(call.create.enabled).toBe(true);
    expect(call.create.nextEligibleAt).toBeInstanceOf(Date);
    expect(call.create.nextEligibleAt.getTime()).toBeGreaterThan(Date.now());
  });
});

describe('PlanetLifeService.markRead', () => {
  // PRD §18-19: the wait restarts from the READ moment, not from publish.
  it('marks the event READ and recomputes nextEligibleAt', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findUnique.mockResolvedValue({
      id: 'event-1',
      petId: 'pet-1',
      status: 'UNREAD',
    });
    prisma.planetEvent.update.mockResolvedValue({
      id: 'event-1',
      status: 'READ',
    });

    await service.markRead('user-1', 'pet-1', 'event-1');

    expect(prisma.planetEvent.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'event-1' },
        data: expect.objectContaining({ status: 'READ' }),
      }),
    );
    expect(prisma.planetLifeState.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { petId: 'pet-1' },
        data: expect.objectContaining({
          nextEligibleAt: expect.any(Date),
        }),
      }),
    );
  });

  it('is a no-op for an event that is not UNREAD', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findUnique.mockResolvedValue({
      id: 'event-1',
      petId: 'pet-1',
      status: 'READ',
    });

    await service.markRead('user-1', 'pet-1', 'event-1');

    expect(prisma.planetEvent.update).not.toHaveBeenCalled();
    expect(prisma.planetLifeState.update).not.toHaveBeenCalled();
  });

  it('throws NotFoundException for an event belonging to a different pet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findUnique.mockResolvedValue({
      id: 'event-1',
      petId: 'some-other-pet',
      status: 'UNREAD',
    });

    await expect(
      service.markRead('user-1', 'pet-1', 'event-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('PlanetLifeService.markBadCase', () => {
  // Case 9/dev spec Case 8: reverts the carried gift to Pending, no refund logic
  // needed since nothing was "consumed" in the first place.
  it('reverts the carried gift instance to PENDING', async () => {
    const { service, prisma, giftsService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findUnique.mockResolvedValue({
      id: 'event-1',
      petId: 'pet-1',
      status: 'UNREAD',
      giftInstanceId: 'gift-instance-a',
    });
    prisma.planetEvent.update.mockResolvedValue({
      id: 'event-1',
      status: 'BAD_CASE',
    });

    await service.markBadCase('user-1', 'pet-1', 'event-1');

    expect(prisma.planetEvent.update).toHaveBeenCalledWith({
      where: { id: 'event-1' },
      data: { status: 'BAD_CASE' },
    });
    expect(giftsService.revertToPending).toHaveBeenCalledWith(
      'gift-instance-a',
    );
  });

  it('does not touch any gift instance when the event carried none', async () => {
    const { service, prisma, giftsService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findUnique.mockResolvedValue({
      id: 'event-1',
      petId: 'pet-1',
      status: 'UNREAD',
      giftInstanceId: null,
    });
    prisma.planetEvent.update.mockResolvedValue({
      id: 'event-1',
      status: 'BAD_CASE',
    });

    await service.markBadCase('user-1', 'pet-1', 'event-1');

    expect(giftsService.revertToPending).not.toHaveBeenCalled();
  });
});

describe('PlanetLifeService.updateSettings (pause/resume)', () => {
  // Case 9/13 (PRD §53): pausing/resuming is a pure flag flip — it must never
  // touch PlanetEvent or GiftInstance rows (a Pending gift survives untouched).
  it('only updates the PlanetLifeState row, nothing else', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetLifeState.findUnique.mockResolvedValue({ petId: 'pet-1' });
    prisma.planetLifeState.update.mockResolvedValue({ paused: true });

    await service.updateSettings('user-1', 'pet-1', { paused: true });

    expect(prisma.planetLifeState.update).toHaveBeenCalledWith({
      where: { petId: 'pet-1' },
      data: { paused: true },
    });
    expect(prisma.planetEvent.update).not.toHaveBeenCalled();
  });

  it('rejects toggling settings before Star Life has ever been enabled', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetLifeState.findUnique.mockResolvedValue(null);

    await expect(
      service.updateSettings('user-1', 'pet-1', { paused: true }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});

describe('PlanetLifeService.debugForceTick', () => {
  it('forces nextEligibleAt to now and runs a real tick, then returns fresh status', async () => {
    const { service, prisma, generationService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetLifeState.findUnique.mockResolvedValue({
      petId: 'pet-1',
      enabled: true,
    });
    prisma.planetEvent.findFirst.mockResolvedValue(null);
    prisma.planetEvent.findMany.mockResolvedValue([]);

    await service.debugForceTick('user-1', 'pet-1');

    expect(prisma.planetLifeState.update).toHaveBeenCalledWith({
      where: { petId: 'pet-1' },
      data: { nextEligibleAt: new Date(0) },
    });
    expect(generationService.runTick).toHaveBeenCalledTimes(1);
  });

  it('refuses when Star Life has never been enabled for this pet', async () => {
    const { service, prisma, generationService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetLifeState.findUnique.mockResolvedValue(null);

    await expect(
      service.debugForceTick('user-1', 'pet-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(generationService.runTick).not.toHaveBeenCalled();
  });

  it('rejects a petId the caller does not own', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'someone-else',
    });

    await expect(
      service.debugForceTick('user-1', 'pet-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});

describe('PlanetLifeService.debugLiveTrigger', () => {
  it('refuses with AI_PROVIDER_NOT_CONFIGURED when any real provider is unconfigured', async () => {
    const { service, prisma, generationService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    generationService.getUnconfiguredRealProviders.mockReturnValue([
      'PLANET_LIFE_IMAGE_PROVIDER',
    ]);

    const promise = service.debugLiveTrigger('user-1', 'pet-1');
    await expect(promise).rejects.toBeInstanceOf(BadRequestException);
    await promise.catch((err: BadRequestException) =>
      expect(err.getResponse()).toMatchObject({
        code: 'AI_PROVIDER_NOT_CONFIGURED',
        missing: ['PLANET_LIFE_IMAGE_PROVIDER'],
      }),
    );
    expect(generationService.runTick).not.toHaveBeenCalled();
  });

  it('proceeds to a real force-tick once every provider is configured', async () => {
    const { service, prisma, generationService } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetLifeState.findUnique.mockResolvedValue({
      petId: 'pet-1',
      enabled: true,
    });
    prisma.planetEvent.findFirst.mockResolvedValue(null);
    prisma.planetEvent.findMany.mockResolvedValue([]);
    generationService.getUnconfiguredRealProviders.mockReturnValue([]);

    await service.debugLiveTrigger('user-1', 'pet-1');

    expect(generationService.runTick).toHaveBeenCalledTimes(1);
  });
});

describe('PlanetLifeService.debugReset', () => {
  it('deletes R2 objects then PlanetEvent/GiftInstance/PlanetLifeState rows for this pet only', async () => {
    const { service, prisma, storage } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.planetEvent.findMany.mockResolvedValue([
      { imageR2Key: 'planet-life/pet-1/event-a.png' },
      { imageR2Key: 'planet-life/pet-1/event-b.png' },
    ]);

    await service.debugReset('user-1', 'pet-1');

    expect(storage.delete).toHaveBeenCalledWith(
      'planet-life/pet-1/event-a.png',
    );
    expect(storage.delete).toHaveBeenCalledWith(
      'planet-life/pet-1/event-b.png',
    );
    expect(prisma.planetEvent.deleteMany).toHaveBeenCalledWith({
      where: { petId: 'pet-1' },
    });
    expect(prisma.giftInstance.deleteMany).toHaveBeenCalledWith({
      where: { petId: 'pet-1' },
    });
    expect(prisma.planetLifeState.deleteMany).toHaveBeenCalledWith({
      where: { petId: 'pet-1' },
    });
  });

  it('rejects a petId the caller does not own', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'someone-else',
    });

    await expect(service.debugReset('user-1', 'pet-1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
