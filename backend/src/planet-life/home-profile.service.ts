import { Injectable, Logger } from '@nestjs/common';
import { HomeVariantKind, Prisma } from '@prisma/client';
import type { HomeVariantAsset } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import type {
  HomeVisualSnapshot,
  HomeVisualVariant,
} from './home-profile.types';

const VARIANT_KINDS = [
  HomeVariantKind.COTTAGE_BLUEPRINT,
  HomeVariantKind.PALETTE,
  HomeVariantKind.ROOF,
  HomeVariantKind.DOOR,
  HomeVariantKind.WINDOW,
  HomeVariantKind.SIGNATURE_PLANT,
] as const;

// Owns Home Profile initialization and Home Anchor status (not the anchor-
// ESTABLISHING write itself, which has to be atomic with the PlanetEvent
// that earns it — see PlanetEventGenerationService, which writes
// HomeProfile directly inside that one transaction, the same way it already
// writes GiftInstance completion inline rather than through GiftsService).
// This service owns everything that happens OUTSIDE that transaction:
// one-time init, reads, and Bad-Case invalidation — the same split GiftsService
// already has between "the transactional completion path" and "its own
// out-of-transaction methods" (revertToPending, simulateDebugPurchase, ...).
@Injectable()
export class HomeProfileService {
  private readonly logger = new Logger(HomeProfileService.name);

  constructor(private prisma: PrismaService) {}

  // Called from PlanetLifeService.enable(). Idempotent and race-safe: a
  // pet that already has a HomeProfile is never touched again — Variant
  // selection only ever happens once, at the very first successful enable.
  async initializeIfNeeded(petId: string, petName: string): Promise<void> {
    const existing = await this.prisma.homeProfile.findUnique({
      where: { petId },
    });
    if (existing) return;

    try {
      await this.createHomeProfile(petId, petName);
    } catch (err) {
      // Same race this module already tolerates elsewhere (see
      // PlanetLifeService.upsertTolerateRace's doc comment): two concurrent
      // enable() calls for the same pet can both pass the "not found" check
      // above. The loser hits petId's unique constraint here — the desired
      // end state (a HomeProfile exists) is already satisfied by whoever
      // won, so this is a no-op, not a real error.
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        return;
      }
      throw err;
    }
  }

  private async createHomeProfile(petId: string, petName: string) {
    const planetStyle = await this.prisma.planetStyle.findFirst({
      where: { active: true },
      orderBy: { version: 'desc' },
    });
    if (!planetStyle) {
      throw new Error(
        'No active PlanetStyle configured — seed/reference data is missing',
      );
    }

    const variants = await this.pickVariants();
    const snapshot = buildVisualSnapshot(variants, petName);

    await this.prisma.homeProfile.create({
      data: {
        petId,
        planetStyleId: planetStyle.id,
        cottageBlueprintKey: variants.COTTAGE_BLUEPRINT.key,
        paletteKey: variants.PALETTE.key,
        roofKey: variants.ROOF.key,
        doorKey: variants.DOOR.key,
        windowKey: variants.WINDOW.key,
        signaturePlantKey: variants.SIGNATURE_PLANT.key,
        nameplateText: petName,
        visualSnapshot: snapshot as unknown as Prisma.InputJsonValue,
      },
    });
  }

  private async pickVariants(): Promise<
    Record<(typeof VARIANT_KINDS)[number], HomeVariantAsset>
  > {
    const result = {} as Record<
      (typeof VARIANT_KINDS)[number],
      HomeVariantAsset
    >;
    for (const kind of VARIANT_KINDS) {
      const rows = await this.prisma.homeVariantAsset.findMany({
        where: { kind, active: true },
      });
      if (rows.length === 0) {
        // Unlike the generation pipeline's fact-resolution (which always
        // falls back rather than block an async background tick), Home
        // Profile init runs synchronously inside a user-initiated enable()
        // call — a missing catalog row is a genuine content-authoring gap,
        // and failing loudly with a clear cause beats silently picking
        // nothing.
        throw new Error(
          `No active HomeVariantAsset for kind ${kind} — seed/reference data is missing`,
        );
      }
      result[kind] = rows[Math.floor(Math.random() * rows.length)];
    }
    return result;
  }

  // Includes planetStyle so callers (PlanetEventGenerationService) never
  // need a second query to read this pet's bound imageGenGuidance.
  async getForPet(petId: string) {
    return this.prisma.homeProfile.findUniqueOrThrow({
      where: { petId },
      include: { planetStyle: true },
    });
  }

  // Called from PlanetLifeService.markBadCase. A no-op unless the bad-cased
  // event is specifically the one currently holding the anchor — an
  // ordinary (non-anchor) Home event being bad-cased must never touch
  // Home Profile at all. HomeProfile itself is never deleted or re-rolled
  // here — only the anchor pointer/status fields change (PRD: "selected
  // Variants / resolved visual snapshot 不变").
  async invalidateAnchorIfCurrent(
    petId: string,
    eventId: string,
  ): Promise<void> {
    const profile = await this.prisma.homeProfile.findUnique({
      where: { petId },
    });
    if (!profile || profile.homeAnchorEventId !== eventId) return;

    await this.prisma.homeProfile.update({
      where: { petId },
      data: {
        homeAnchorStatus: 'INVALIDATED',
        homeAnchorImageR2Key: null,
        homeAnchorImageR2Url: null,
        homeAnchorEventId: null,
      },
    });
    this.logger.log(
      `Home Anchor invalidated for pet ${petId} (event ${eventId} marked Bad Case) — will re-establish on the next eligible Home event.`,
    );
  }
}

function toVisualVariant(asset: HomeVariantAsset): HomeVisualVariant {
  return {
    key: asset.key,
    nameZh: asset.nameZh,
    nameEn: asset.nameEn,
    imageGenPrompt: asset.imageGenPrompt,
  };
}

function buildVisualSnapshot(
  variants: Record<(typeof VARIANT_KINDS)[number], HomeVariantAsset>,
  petName: string,
): HomeVisualSnapshot {
  const cottageBlueprint = toVisualVariant(variants.COTTAGE_BLUEPRINT);
  const palette = {
    ...toVisualVariant(variants.PALETTE),
    colorTokens: (variants.PALETTE.colorTokens as string[] | null) ?? null,
  };
  const roof = toVisualVariant(variants.ROOF);
  const door = toVisualVariant(variants.DOOR);
  const window = toVisualVariant(variants.WINDOW);
  const signaturePlant = toVisualVariant(variants.SIGNATURE_PLANT);

  // Mechanical concatenation, not AI-generated — a convenience string for a
  // provider that wants one paragraph instead of assembling the individual
  // fields itself.
  const summaryPrompt = [
    cottageBlueprint.imageGenPrompt,
    roof.imageGenPrompt,
    door.imageGenPrompt,
    window.imageGenPrompt,
    palette.imageGenPrompt,
    signaturePlant.imageGenPrompt,
    `a wooden nameplate reading "${petName}" near the entrance`,
  ].join(', ');

  return {
    cottageBlueprint,
    palette,
    roof,
    door,
    window,
    signaturePlant,
    nameplateText: petName,
    summaryPrompt,
  };
}
