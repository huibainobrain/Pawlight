import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

// Gift Asset (the type, e.g. "小球") and Gift Instance (one real purchase of
// it) are deliberately separate models — see schema.prisma. This service is
// the only place that creates/completes/reverts a GiftInstance, so that
// invariant (and the "max 1 pending" rule) lives in one place.
@Injectable()
export class GiftsService {
  private readonly logger = new Logger(GiftsService.name);

  constructor(private prisma: PrismaService) {}

  async listAssets(userId: string, petId: string) {
    const pet = await this.assertPetOwner(userId, petId);
    const [allAssets, pending] = await Promise.all([
      this.prisma.giftAsset.findMany({
        where: { saleStatus: 'ACTIVE' },
        orderBy: { displayOrder: 'asc' },
        include: { products: { where: { active: true } } },
      }),
      this.getPendingForPet(petId),
    ]);

    // speciesApplicability was a stored-but-unread field until this pass —
    // enforced here the same way EventTemplate already enforces its own
    // speciesApplicability during generation.
    const assets = allAssets.filter((a) => {
      const species = a.speciesApplicability as string[] | null;
      return !species || species.includes(pet.type);
    });

    const alreadyGivenIds = await this.alreadyGivenNonRepeatableIds(
      petId,
      assets,
    );

    return {
      assets: assets.map((a) => ({
        ...a,
        // Distinct from canPurchase below: this is "you can never buy this
        // ONE again" (repeatable:false + already completed once), not
        // "something else is pending right now."
        alreadyGiven: alreadyGivenIds.has(a.id),
      })),
      // Not "already owned" — just whether a new purchase can start right
      // now (PRD §8.1: max 1 pending at a time, any gift can be bought again
      // once its current instance completes).
      canPurchase: !pending,
      pending,
    };
  }

  private async alreadyGivenNonRepeatableIds(
    petId: string,
    assets: { id: string; repeatable: boolean }[],
  ): Promise<Set<string>> {
    const nonRepeatableIds = assets
      .filter((a) => !a.repeatable)
      .map((a) => a.id);
    if (nonRepeatableIds.length === 0) return new Set();
    const completed = await this.prisma.giftInstance.findMany({
      where: {
        petId,
        giftAssetId: { in: nonRepeatableIds },
        status: 'COMPLETED',
      },
      select: { giftAssetId: true },
    });
    return new Set(completed.map((i) => i.giftAssetId));
  }

  async getPendingForPet(petId: string) {
    return this.prisma.giftInstance.findFirst({
      where: { petId, status: 'PENDING' },
      include: { giftAsset: true },
    });
  }

  async findActiveProductByProductId(productId: string) {
    return this.prisma.giftProduct.findFirst({
      where: { productId, active: true },
      include: { giftAsset: true },
    });
  }

  // Called only from PurchasesService after a real, verified Apple purchase.
  // Idempotent on purchaseTransactionId so a client retry (or Apple
  // redelivering the same transaction) never creates a second instance.
  async createGiftInstanceFromPurchase(
    petId: string,
    giftAssetId: string,
    transactionId: string,
  ) {
    const existing = await this.prisma.giftInstance.findUnique({
      where: { purchaseTransactionId: transactionId },
    });
    if (existing) return existing;

    const pending = await this.getPendingForPet(petId);
    if (pending) {
      // The purchase already went through with Apple — refusing to record it
      // would take the user's money and give them nothing. This should not
      // be reachable if the client gates correctly before starting a
      // purchase; if it happens anyway (a race), we accept a second pending
      // instance as a rare, logged edge case rather than discard a paid
      // transaction.
      this.logger.warn(
        `Creating a second pending GiftInstance for pet ${petId} — an existing pending instance (${pending.id}) was not cleared before this purchase completed.`,
      );
    }

    // Same reasoning as the pending check above: real money already moved,
    // so a non-repeatable gift bought again (client should have hidden the
    // buy button via listAssets().assets[].alreadyGiven) is logged, not
    // refused.
    const asset = await this.prisma.giftAsset.findUnique({
      where: { id: giftAssetId },
    });
    if (asset && !asset.repeatable) {
      const alreadyCompleted = await this.prisma.giftInstance.findFirst({
        where: { petId, giftAssetId, status: 'COMPLETED' },
      });
      if (alreadyCompleted) {
        this.logger.warn(
          `Creating a repeat GiftInstance for non-repeatable asset ${asset.key} on pet ${petId} — client should have prevented this purchase.`,
        );
      }
    }

    return this.prisma.giftInstance.create({
      data: {
        petId,
        giftAssetId,
        purchaseTransactionId: transactionId,
        status: 'PENDING',
      },
    });
  }

  // "不像 TA" on a gift-bearing event: the fulfillment attempt is void, the
  // instance goes back to Pending with no new charge (PRD §33).
  async revertToPending(giftInstanceId: string) {
    await this.prisma.giftInstance.update({
      where: { id: giftInstanceId },
      data: { status: 'PENDING', completedAt: null },
    });
  }

  // DEBUG-only stand-in for a real Apple purchase (behind X-Debug-Secret —
  // see PlanetLifeController). Goes through the same "max 1 pending" business
  // rule a real purchase would (unlike createGiftInstanceFromPurchase, which
  // must accept a second pending instance on a race because real money has
  // already changed hands — there is no such constraint on a fake purchase,
  // so this rejects outright instead).
  async simulateDebugPurchase(
    userId: string,
    petId: string,
    giftAssetKey: string,
  ) {
    await this.assertPetOwner(userId, petId);
    const pending = await this.getPendingForPet(petId);
    if (pending) {
      throw new BadRequestException({
        code: 'GIFT_ALREADY_PENDING',
        message: '已经有一份待回应的礼物，无法再次购买',
      });
    }
    const asset = await this.prisma.giftAsset.findUnique({
      where: { key: giftAssetKey },
    });
    if (!asset) throw new NotFoundException('Gift asset not found');

    if (!asset.repeatable) {
      const alreadyCompleted = await this.prisma.giftInstance.findFirst({
        where: { petId, giftAssetId: asset.id, status: 'COMPLETED' },
      });
      if (alreadyCompleted) {
        // No real money involved here (unlike the real-purchase path above),
        // so there's no reason to tolerate this the way a real charge would
        // have to be.
        throw new BadRequestException({
          code: 'GIFT_NOT_REPEATABLE',
          message: '这份礼物不支持重复赠送，且已经完成过一次',
        });
      }
    }

    const transactionId = `debug-${randomBytes(8).toString('hex')}`;
    return this.createGiftInstanceFromPurchase(petId, asset.id, transactionId);
  }

  private async assertPetOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();
    return pet;
  }
}
