import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { GiftsService } from './gifts.service';
import { PrismaService } from '../prisma/prisma.service';

function makePrisma() {
  return {
    pet: { findUnique: jest.fn() },
    giftAsset: { findMany: jest.fn(), findUnique: jest.fn() },
    giftProduct: { findFirst: jest.fn() },
    giftInstance: {
      findFirst: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

function makeService(prisma = makePrisma()) {
  const service = new GiftsService(asPrismaService(prisma));
  return { service, prisma };
}

describe('GiftsService.listAssets', () => {
  it('rejects a caller who does not own the pet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'owner' });

    await expect(
      service.listAssets('someone-else', 'pet-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('throws NotFoundException for a nonexistent pet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue(null);

    await expect(
      service.listAssets('user-1', 'missing-pet'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  // Case 1 (dev spec §37): no Pending Gift -> purchase allowed.
  it('reports canPurchase: true when there is no pending gift', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'CAT',
    });
    prisma.giftAsset.findMany.mockResolvedValue([
      { key: 'ball', repeatable: true, speciesApplicability: null },
    ]);
    prisma.giftInstance.findFirst.mockResolvedValue(null);

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.canPurchase).toBe(true);
    expect(result.pending).toBeNull();
  });

  // Case 5 (dev spec §37): an existing Pending Gift blocks a new purchase,
  // regardless of which gift it is.
  it('reports canPurchase: false when a gift is already pending', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'CAT',
    });
    prisma.giftAsset.findMany.mockResolvedValue([]);
    prisma.giftInstance.findFirst.mockResolvedValue({
      id: 'gift-instance-a',
      status: 'PENDING',
    });

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.canPurchase).toBe(false);
    expect(result.pending).toMatchObject({ id: 'gift-instance-a' });
  });

  // speciesApplicability was a stored-but-unread field before this round's
  // audit — these two prove it's now actually enforced, the same way
  // EventTemplate.speciesApplicability already was.
  it('excludes a gift whose speciesApplicability does not include this pet type', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'CAT',
    });
    prisma.giftAsset.findMany.mockResolvedValue([
      {
        id: 'asset-dog-toy',
        key: 'dog_toy',
        repeatable: true,
        speciesApplicability: ['DOG'],
      },
      {
        id: 'asset-ball',
        key: 'ball',
        repeatable: true,
        speciesApplicability: null,
      },
    ]);
    prisma.giftInstance.findFirst.mockResolvedValue(null);

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.assets.map((a) => a.key)).toEqual(['ball']);
  });

  it('includes a gift with no speciesApplicability restriction for any pet type', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'OTHER',
    });
    prisma.giftAsset.findMany.mockResolvedValue([
      {
        id: 'asset-ball',
        key: 'ball',
        repeatable: true,
        speciesApplicability: null,
      },
    ]);
    prisma.giftInstance.findFirst.mockResolvedValue(null);

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.assets.map((a) => a.key)).toEqual(['ball']);
  });

  // repeatable:false was also stored-but-unenforced before this round.
  it('marks a non-repeatable gift alreadyGiven once a COMPLETED instance exists', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'CAT',
    });
    prisma.giftAsset.findMany.mockResolvedValue([
      {
        id: 'asset-star',
        key: 'star',
        repeatable: false,
        speciesApplicability: null,
      },
    ]);
    prisma.giftInstance.findFirst.mockResolvedValue(null); // nothing pending
    prisma.giftInstance.findMany.mockResolvedValue([
      { giftAssetId: 'asset-star' },
    ]);

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.assets[0]).toMatchObject({
      key: 'star',
      alreadyGiven: true,
    });
  });

  it('does not mark a non-repeatable gift alreadyGiven with no COMPLETED instance yet', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'user-1',
      type: 'CAT',
    });
    prisma.giftAsset.findMany.mockResolvedValue([
      {
        id: 'asset-star',
        key: 'star',
        repeatable: false,
        speciesApplicability: null,
      },
    ]);
    prisma.giftInstance.findFirst.mockResolvedValue(null);
    prisma.giftInstance.findMany.mockResolvedValue([]); // no completed instance

    const result = await service.listAssets('user-1', 'pet-1');
    expect(result.assets[0]).toMatchObject({
      key: 'star',
      alreadyGiven: false,
    });
  });
});

describe('GiftsService.createGiftInstanceFromPurchase', () => {
  // Case 4: a verified purchase creates one independent Gift Instance.
  it('creates a new PENDING gift instance', async () => {
    const { service, prisma } = makeService();
    prisma.giftInstance.findUnique.mockResolvedValue(null);
    prisma.giftInstance.findFirst.mockResolvedValue(null);
    prisma.giftInstance.create.mockResolvedValue({
      id: 'gift-instance-a',
      status: 'PENDING',
    });

    const result = await service.createGiftInstanceFromPurchase(
      'pet-1',
      'asset-ball',
      'txn-1',
    );

    expect(prisma.giftInstance.create).toHaveBeenCalledWith({
      data: {
        petId: 'pet-1',
        giftAssetId: 'asset-ball',
        purchaseTransactionId: 'txn-1',
        status: 'PENDING',
      },
    });
    expect(result).toMatchObject({ status: 'PENDING' });
  });

  // Idempotency: the same Apple transaction id must never create a second
  // row (e.g. a client retry after a flaky network response).
  it('returns the existing instance instead of creating a duplicate for the same transaction id', async () => {
    const { service, prisma } = makeService();
    const existing = { id: 'gift-instance-a', status: 'PENDING' };
    prisma.giftInstance.findUnique.mockResolvedValue(existing);

    const result = await service.createGiftInstanceFromPurchase(
      'pet-1',
      'asset-ball',
      'txn-1',
    );

    expect(result).toBe(existing);
    expect(prisma.giftInstance.create).not.toHaveBeenCalled();
  });

  // Case 11: completing one instance and buying again creates a second,
  // independent instance — never mutates the first.
  it('creates an independent second instance for a repeat purchase after the first is no longer pending', async () => {
    const { service, prisma } = makeService();
    prisma.giftInstance.findUnique.mockResolvedValue(null);
    prisma.giftInstance.findFirst.mockResolvedValue(null); // first instance is COMPLETED, so no pending one
    prisma.giftInstance.create.mockResolvedValue({
      id: 'gift-instance-b',
      status: 'PENDING',
    });

    const result = await service.createGiftInstanceFromPurchase(
      'pet-1',
      'asset-ball',
      'txn-2',
    );

    expect(result).toMatchObject({ id: 'gift-instance-b' });
    expect(prisma.giftInstance.update).not.toHaveBeenCalled();
  });
});

describe('GiftsService.simulateDebugPurchase', () => {
  it('creates a PENDING instance for the named gift asset', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.giftInstance.findFirst.mockResolvedValue(null); // no pending yet
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      key: 'ball',
    });
    prisma.giftInstance.findUnique.mockResolvedValue(null);
    prisma.giftInstance.create.mockResolvedValue({
      id: 'gift-instance-a',
      status: 'PENDING',
    });

    const result = await service.simulateDebugPurchase(
      'user-1',
      'pet-1',
      'ball',
    );

    expect(result).toMatchObject({ status: 'PENDING' });
    const createArg = prisma.giftInstance.create.mock.calls[0][0];
    expect(createArg.data.giftAssetId).toBe('asset-ball');
    expect(createArg.data.purchaseTransactionId).toMatch(/^debug-/);
  });

  it('rejects when a gift is already pending, same as a real purchase would be blocked client-side', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.giftInstance.findFirst.mockResolvedValue({
      id: 'existing',
      status: 'PENDING',
    });

    await expect(
      service.simulateDebugPurchase('user-1', 'pet-1', 'ball'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects re-purchasing a non-repeatable gift that already has a COMPLETED instance', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.giftInstance.findFirst
      .mockResolvedValueOnce(null) // getPendingForPet: nothing pending
      .mockResolvedValueOnce({ id: 'old-instance', status: 'COMPLETED' }); // the repeatable check
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-star',
      key: 'star',
      repeatable: false,
    });

    await expect(
      service.simulateDebugPurchase('user-1', 'pet-1', 'star'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.giftInstance.create).not.toHaveBeenCalled();
  });

  it('allows buying a non-repeatable gift the first time (no COMPLETED instance yet)', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.giftInstance.findFirst.mockResolvedValue(null); // neither pending nor completed
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-star',
      key: 'star',
      repeatable: false,
    });
    prisma.giftInstance.findUnique.mockResolvedValue(null);
    prisma.giftInstance.create.mockResolvedValue({
      id: 'gift-instance-a',
      status: 'PENDING',
    });

    const result = await service.simulateDebugPurchase(
      'user-1',
      'pet-1',
      'star',
    );
    expect(result).toMatchObject({ status: 'PENDING' });
  });

  it('rejects an unknown gift asset key', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({ id: 'pet-1', userId: 'user-1' });
    prisma.giftInstance.findFirst.mockResolvedValue(null);
    prisma.giftAsset.findUnique.mockResolvedValue(null);

    await expect(
      service.simulateDebugPurchase('user-1', 'pet-1', 'nonexistent'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects a petId the caller does not own', async () => {
    const { service, prisma } = makeService();
    prisma.pet.findUnique.mockResolvedValue({
      id: 'pet-1',
      userId: 'someone-else',
    });

    await expect(
      service.simulateDebugPurchase('user-1', 'pet-1', 'ball'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});

describe('GiftsService.revertToPending', () => {
  // Case 8 (dev spec §37): "doesn't look like TA" reverts the instance to
  // Pending with no new charge — just a state change, nothing financial.
  it('sets status back to PENDING and clears completedAt', async () => {
    const { service, prisma } = makeService();

    await service.revertToPending('gift-instance-a');

    expect(prisma.giftInstance.update).toHaveBeenCalledWith({
      where: { id: 'gift-instance-a' },
      data: { status: 'PENDING', completedAt: null },
    });
  });
});
