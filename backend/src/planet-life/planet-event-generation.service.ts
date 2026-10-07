import { Inject, Injectable, Logger } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';
import { GiftsService } from './gifts.service';
import { HomeProfileService } from './home-profile.service';
import { EVENT_TEXT_GEN_PROVIDER } from './providers/event-text-gen.provider';
import type { EventTextGenProvider } from './providers/event-text-gen.provider';
import type {
  EventFacts,
  GeneratedEventText,
  ResolvedAsset,
} from './providers/event-text-gen.provider';
import { EVENT_IMAGE_GEN_PROVIDER } from './providers/event-image-gen.provider';
import type { EventImageGenProvider } from './providers/event-image-gen.provider';
import type { GeneratedEventImage } from './providers/event-image-gen.provider';
import type { HomeGenerationContext } from './providers/home-context';
import { IMAGE_QUALITY_PROVIDER } from './providers/image-quality.provider';
import type { ImageQualityProvider } from './providers/image-quality.provider';
import { TEXT_QUALITY_PROVIDER } from './providers/text-quality.provider';
import type { TextQualityProvider } from './providers/text-quality.provider';
import {
  NARRATIVE_RULES,
  STABLE_IDENTITY_PLACEHOLDER,
} from './narrative-rules';
import {
  GENERATION_MAX_RETRIES,
  WEEKLY_EVENT_CAP,
  WEEKLY_WINDOW_MS,
} from './planet-life.constants';
import type {
  ActionAsset,
  ContentAsset,
  EventTemplate,
  GiftAsset,
  LocationAsset,
} from '@prisma/client';
import { ContentAssetKind, Prisma } from '@prisma/client';

// The core "pick facts -> AI expresses them -> quality-check -> publish"
// pipeline (PRD §43). Called by PlanetLifeScheduler's tick, never by an HTTP
// request directly — generation is async and user-invisible until a chronicle
// is actually published.
@Injectable()
export class PlanetEventGenerationService {
  private readonly logger = new Logger(PlanetEventGenerationService.name);

  constructor(
    private prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private storage: StorageService,
    @Inject(EVENT_TEXT_GEN_PROVIDER) private textGen: EventTextGenProvider,
    @Inject(EVENT_IMAGE_GEN_PROVIDER) private imageGen: EventImageGenProvider,
    @Inject(IMAGE_QUALITY_PROVIDER) private imageQuality: ImageQualityProvider,
    @Inject(TEXT_QUALITY_PROVIDER) private textQuality: TextQualityProvider,
    private giftsService: GiftsService,
    private homeProfileService: HomeProfileService,
  ) {}

  // Used only by the DEBUG "测试：真实生成一次" trigger (PlanetLifeService.
  // debugLiveTrigger) to refuse with a clear, specific message instead of
  // silently running the fake pipeline and letting a developer believe a
  // real vendor was exercised. Mirrors exactly the env vars planet-
  // life.module.ts itself resolves at boot — no new source of truth.
  readonly realProviderEnvVars = [
    'PLANET_LIFE_TEXT_PROVIDER',
    'PLANET_LIFE_IMAGE_PROVIDER',
    'PLANET_LIFE_IMAGE_QUALITY_PROVIDER',
    'PLANET_LIFE_TEXT_QUALITY_PROVIDER',
  ] as const;

  getUnconfiguredRealProviders(): string[] {
    return this.realProviderEnvVars.filter(
      (name) => (process.env[name] ?? 'fake') === 'fake',
    );
  }

  async runTick() {
    const states = await this.findDueStates();
    for (const state of states) {
      try {
        await this.generateForPet(state.petId);
      } catch (err) {
        // One pet's failure must never block the others in this tick.
        this.logger.warn(
          `Planet event generation failed for pet ${state.petId}: ${err instanceof Error ? err.message : String(err)}`,
        );
      }
    }
  }

  private async findDueStates() {
    const now = new Date();
    const candidates = await this.prisma.planetLifeState.findMany({
      where: {
        enabled: true,
        paused: false,
        OR: [{ nextEligibleAt: null }, { nextEligibleAt: { lte: now } }],
      },
    });

    const due: typeof candidates = [];
    for (const state of candidates) {
      const hasUnread = await this.prisma.planetEvent.findFirst({
        where: { petId: state.petId, status: 'UNREAD' },
      });
      if (hasUnread) continue;
      if (this.weeklyCapExceeded(state, now)) continue;
      due.push(state);
    }
    return due;
  }

  private weeklyCapExceeded(
    state: { weeklyEventCount: number; weeklyWindowStart: Date | null },
    now: Date,
  ) {
    if (!state.weeklyWindowStart) return false;
    const windowAge = now.getTime() - state.weeklyWindowStart.getTime();
    if (windowAge > WEEKLY_WINDOW_MS) return false; // window expired, will reset on next publish
    return state.weeklyEventCount >= WEEKLY_EVENT_CAP;
  }

  private async generateForPet(petId: string) {
    const pet = await this.prisma.pet.findUniqueOrThrow({
      where: { id: petId },
      include: { user: true },
    });
    const mainPhoto = await this.prisma.photo.findFirst({
      where: { petId, type: 'MAIN' },
    });
    if (!mainPhoto) return; // no reference photo yet — defer silently

    // Every enabled pet has a HomeProfile by construction (PlanetLifeService.
    // enable() creates one before/alongside PlanetLifeState) — thrown
    // otherwise and caught by runTick's per-pet try/catch, same as a
    // deleted-mid-tick Pet row would be.
    const homeProfile = await this.homeProfileService.getForPet(petId);
    const anchorEstablished = homeProfile.homeAnchorStatus === 'ESTABLISHED';

    // Resolved before template selection so a pending gift can bias which
    // template gets picked (see pickTemplate) — this is what makes PRD §31's
    // "appears within 1-3 valid chronicles" promise hold once there are many
    // templates with wildly different per-gift compatibility, instead of
    // leaving it to chance whether a compatible template is ever rolled.
    const pendingGift = await this.giftsService.getPendingForPet(petId);
    const pendingGiftAsset = pendingGift
      ? await this.prisma.giftAsset.findUnique({
          where: { id: pendingGift.giftAssetId },
        })
      : null;

    // While no valid Home Anchor exists, selection is RESTRICTED (not just
    // biased) to Home Base + homeAnchorEligible templates — generating any
    // other event right now would leave the pet stuck unable to ever
    // establish one. This window is always temporary: it closes the moment
    // one such event successfully publishes.
    const template = await this.pickTemplate(
      pet.type,
      pendingGiftAsset,
      !anchorEstablished,
    );
    if (!template) return; // nothing eligible this tick — defer silently

    // A gift only actually rides along when BOTH sides agree: the template
    // allows gifts at all, AND this specific gift lists this specific
    // template as one it's compatible with. Checking only
    // template.giftCompatible (as earlier code did) is a real bug once more
    // than one gift-compatible template and more than one gift exist — it
    // would let any pending gift ride any gift-compatible template
    // regardless of fit, since with exactly one template and one test gift
    // the two checks always happened to agree.
    const giftRidesAlong =
      template.giftCompatible &&
      pendingGiftAsset != null &&
      (pendingGiftAsset.eventCompatibility as string[]).includes(template.key);
    const giftAsset = giftRidesAlong ? pendingGiftAsset : null;
    const ridingGiftInstance = giftRidesAlong ? pendingGift : null;

    const location = await this.pickLocation(
      template,
      pet.type,
      !anchorEstablished,
    );
    const isHomeEvent = location.scope === 'HOME_BASE';
    const facts = await this.resolveFacts(
      template,
      giftAsset,
      pet.type,
      location,
    );
    const language = pet.user.language ?? 'en';

    const homeContext: HomeGenerationContext | undefined = isHomeEvent
      ? {
          visualSnapshot:
            homeProfile.visualSnapshot as unknown as HomeGenerationContext['visualSnapshot'],
          anchorImageUrl: anchorEstablished
            ? (homeProfile.homeAnchorImageR2Url ?? undefined)
            : undefined,
          anchorVersion: homeProfile.homeAnchorVersion,
        }
      : undefined;

    // PRD §49: a quality-check failure gets one automatic retry (regenerate,
    // re-check) before the tick gives up silently for this pet — it must
    // never publish a failing result and never consume a riding gift
    // (or establish/touch a Home Anchor) either way.
    const text = await this.generateTextWithRetry(petId, facts, language);
    if (!text) return;

    const image = await this.generateImageWithRetry(
      petId,
      mainPhoto.r2Url,
      homeProfile.planetStyle.imageGenGuidance,
      facts,
      !!giftAsset,
      homeContext,
    );
    if (!image) return;

    const ext = image.contentType.includes('png') ? 'png' : 'jpg';
    const key = `planet-life/${petId}/event-${randomBytes(4).toString('hex')}.${ext}`;
    const { url } = await this.storage.upload({
      key,
      buffer: image.buffer,
      contentType: image.contentType,
    });

    const now = new Date();
    const state = await this.prisma.planetLifeState.findUniqueOrThrow({
      where: { petId },
    });
    const windowExpired =
      !state.weeklyWindowStart ||
      now.getTime() - state.weeklyWindowStart.getTime() > WEEKLY_WINDOW_MS;

    // This publish IS the one that (re-)establishes the Home Anchor only
    // when it's a Home event AND no valid anchor currently exists — never
    // on an ordinary Home event once one is already established.
    const willEstablishAnchor = isHomeEvent && !anchorEstablished;
    const newAnchorVersion = willEstablishAnchor
      ? homeProfile.homeAnchorVersion + 1
      : homeProfile.homeAnchorVersion;

    // An interactive transaction (not the array form used elsewhere in this
    // file) because the Home Anchor write below needs this event's own id,
    // which doesn't exist until planetEvent.create() has actually run.
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.planetEvent.create({
        data: {
          petId,
          eventTemplateKey: template.key,
          title: text.title,
          body: text.body,
          language,
          imageR2Key: key,
          imageR2Url: url,
          factsJson: facts as unknown as Prisma.InputJsonValue,
          giftInstanceId: ridingGiftInstance?.id,
          establishedHomeAnchorVersion: willEstablishAnchor
            ? newAnchorVersion
            : null,
        },
      });

      if (ridingGiftInstance) {
        await tx.giftInstance.update({
          where: { id: ridingGiftInstance.id },
          data: { status: 'COMPLETED', completedAt: now },
        });
      }

      await tx.planetLifeState.update({
        where: { petId },
        data: windowExpired
          ? { weeklyEventCount: 1, weeklyWindowStart: now }
          : { weeklyEventCount: { increment: 1 } },
      });

      if (willEstablishAnchor) {
        await tx.homeProfile.update({
          where: { petId },
          data: {
            homeAnchorStatus: 'ESTABLISHED',
            homeAnchorVersion: newAnchorVersion,
            homeAnchorImageR2Key: key,
            homeAnchorImageR2Url: url,
            homeAnchorEventId: created.id,
          },
        });
      }
    });
  }

  private async generateTextWithRetry(
    petId: string,
    facts: EventFacts,
    language: string,
  ): Promise<GeneratedEventText | null> {
    for (let attempt = 1; attempt <= 1 + GENERATION_MAX_RETRIES; attempt++) {
      const text = await this.textGen.generate({
        facts,
        narrativeRules: NARRATIVE_RULES,
        language,
      });
      const check = await this.textQuality.check({ text, facts });
      if (check.pass) return text;
      this.logger.warn(
        `Text quality check failed for pet ${petId} (attempt ${attempt}): ${check.reason ?? 'unspecified'}`,
      );
    }
    return null;
  }

  private async generateImageWithRetry(
    petId: string,
    referenceImageUrl: string,
    planetStyleDescription: string,
    facts: EventFacts,
    hasGift: boolean,
    home: HomeGenerationContext | undefined,
  ): Promise<GeneratedEventImage | null> {
    for (let attempt = 1; attempt <= 1 + GENERATION_MAX_RETRIES; attempt++) {
      const image = await this.imageGen.generate({
        referenceImageUrl,
        stableIdentityDescription: STABLE_IDENTITY_PLACEHOLDER,
        planetStyleDescription,
        facts,
        home,
      });
      const check = await this.imageQuality.check({
        image,
        facts,
        hasGift,
        home,
      });
      if (check.pass) return image;
      this.logger.warn(
        `Image quality check failed for pet ${petId} (attempt ${attempt}): ${check.reason ?? 'unspecified'}`,
      );
    }
    return null;
  }

  // When a gift is pending, eligible templates it's actually compatible with
  // are tried FIRST (still weighted among themselves) — falling back to the
  // full eligible set only when none of those are currently selectable (e.g.
  // all on cooldown). Without this bias, template selection is blind to the
  // pending gift entirely, and PRD §31's "appears within 1-3 valid
  // chronicles" promise degrades to luck once templates vary widely in
  // which gifts they accept.
  //
  // requireHomeAnchorEligible narrows this further, BEFORE the gift bias:
  // while true, only templates marked homeAnchorEligible AND verified (by
  // an actual lookup, not just trusting the flag) to have at least one
  // HOME_BASE location in their own pool are considered eligible at all —
  // same "check the real condition, don't trust a coarse flag alone" lesson
  // already applied to Gift/Template compatibility.
  private async pickTemplate(
    petType: string,
    pendingGiftAsset: GiftAsset | null,
    requireHomeAnchorEligible: boolean,
  ): Promise<EventTemplate | null> {
    const templates = await this.prisma.eventTemplate.findMany({
      where: { active: true },
    });
    let eligible: EventTemplate[] = [];
    for (const t of templates) {
      const species = t.speciesApplicability as string[] | null;
      if (species && !species.includes(petType)) continue;
      if (t.cooldownDays) {
        const recent = await this.prisma.planetEvent.findFirst({
          where: {
            eventTemplateKey: t.key,
            createdAt: {
              gte: new Date(Date.now() - t.cooldownDays * 24 * 60 * 60 * 1000),
            },
          },
        });
        if (recent) continue;
      }
      eligible.push(t);
    }
    if (eligible.length === 0) return null;

    if (requireHomeAnchorEligible) {
      eligible = await this.filterHomeAnchorEligible(eligible);
      if (eligible.length === 0) return null; // defer silently — a content gap, not an error
    }

    if (pendingGiftAsset) {
      const compatibility = pendingGiftAsset.eventCompatibility as string[];
      const giftEligible = eligible.filter(
        (t) => t.giftCompatible && compatibility.includes(t.key),
      );
      if (giftEligible.length > 0) {
        return this.weightedPick(giftEligible);
      }
    }
    return this.weightedPick(eligible);
  }

  private async filterHomeAnchorEligible(
    templates: EventTemplate[],
  ): Promise<EventTemplate[]> {
    const flagged = templates.filter((t) => t.homeAnchorEligible);
    if (flagged.length === 0) return [];

    const result: EventTemplate[] = [];
    for (const t of flagged) {
      const homeRows = await this.prisma.locationAsset.findMany({
        where: {
          key: { in: t.locationKeys as string[] },
          active: true,
          scope: 'HOME_BASE',
        },
      });
      if (homeRows.length > 0) result.push(t);
    }
    return result;
  }

  private weightedPick(templates: EventTemplate[]): EventTemplate {
    const totalWeight = templates.reduce((sum, t) => sum + t.weight, 0);
    let roll = Math.random() * totalWeight;
    for (const t of templates) {
      roll -= t.weight;
      if (roll <= 0) return t;
    }
    return templates[templates.length - 1];
  }

  // Resolves a template's key pools into fully-expressed, bilingual facts —
  // the single place raw asset rows get turned into what a Provider actually
  // sees. Every layer below (species, gift-action, location<->action mutual
  // exclusion) is filter-with-fallback: a misconfigured or overly-narrow
  // asset can make a particular pairing less likely, but can never leave
  // generation with nothing pickable. location is resolved by the caller
  // (generateForPet) rather than here, since it also decides isHomeEvent.
  private async resolveFacts(
    template: EventTemplate,
    giftAsset: GiftAsset | null,
    petType: string,
    location: LocationAsset,
  ): Promise<EventFacts> {
    const action = await this.pickAction(
      template,
      giftAsset,
      petType,
      location,
    );
    const time = await this.pickContentAsset(
      template.timeKeys as string[],
      ContentAssetKind.TIME,
    );
    const atmosphere = await this.pickContentAsset(
      template.atmosphereKeys as string[],
      ContentAssetKind.ATMOSPHERE,
    );
    const ambientDetails = template.ambientDetailKeys
      ? await this.pickContentAsset(
          template.ambientDetailKeys as string[],
          ContentAssetKind.AMBIENT_DETAIL,
        )
      : null;

    return {
      location: toResolvedAsset(location, location.imageGenPrompt),
      action: toResolvedAsset(action, action.visualAction),
      time: toResolvedAsset(time, time.visualDescription),
      atmosphere: toResolvedAsset(atmosphere, atmosphere.visualDescription),
      ambientDetails: ambientDetails
        ? toResolvedAsset(ambientDetails, ambientDetails.visualDescription)
        : undefined,
      giftNameZh: giftAsset?.nameZh,
      giftNameEn: giftAsset?.nameEn,
    };
  }

  // requireHomeBase narrows the pool to scope=HOME_BASE FIRST, before
  // species filtering — pickTemplate already verified (via
  // filterHomeAnchorEligible) that the chosen template's pool contains at
  // least one such row whenever this is true, so this filter is guaranteed
  // non-empty here and never needs its own fallback.
  private async pickLocation(
    template: EventTemplate,
    petType: string,
    requireHomeBase: boolean,
  ): Promise<LocationAsset> {
    const keys = template.locationKeys as string[];
    const rows = await this.prisma.locationAsset.findMany({
      where: { key: { in: keys }, active: true },
    });
    const scoped = requireHomeBase
      ? rows.filter((r) => r.scope === 'HOME_BASE')
      : rows;
    const eligible = filterBySpecies(scoped, petType);
    return pickRandom(eligible.length > 0 ? eligible : scoped);
  }

  // Species narrowing (same idea as pickLocation), then the gift's own
  // actionCompatibility restriction (actionPoolFor, unchanged from before
  // this round), then the chosen location's/action's mutual incompatibility
  // lists — checked from both sides since either asset may be the one
  // declaring the exclusion (a content editor can author it from whichever
  // row is more natural to think from). Actions themselves are never
  // scope-restricted — Home/Nearby is a Location-only property.
  private async pickAction(
    template: EventTemplate,
    giftAsset: GiftAsset | null,
    petType: string,
    location: LocationAsset,
  ): Promise<ActionAsset> {
    const keys = this.actionPoolFor(template, giftAsset);
    const rows = await this.prisma.actionAsset.findMany({
      where: { key: { in: keys }, active: true },
    });
    const speciesEligible = filterBySpecies(rows, petType);
    const withSpecies = speciesEligible.length > 0 ? speciesEligible : rows;

    const locationExcludes =
      (location.incompatibleActionKeys as string[] | null) ?? [];
    const compatible = withSpecies.filter((a) => {
      if (locationExcludes.includes(a.key)) return false;
      const actionExcludes =
        (a.incompatibleLocationKeys as string[] | null) ?? [];
      return !actionExcludes.includes(location.key);
    });
    return pickRandom(compatible.length > 0 ? compatible : withSpecies);
  }

  private async pickContentAsset(
    keys: string[],
    kind: ContentAssetKind,
  ): Promise<ContentAsset> {
    const key = pickRandom(keys);
    const asset = await this.prisma.contentAsset.findUniqueOrThrow({
      where: { key },
    });
    if (asset.kind !== kind) {
      throw new Error(
        `ContentAsset "${key}" has kind ${asset.kind}, expected ${kind} — check EventTemplate seed/reference data`,
      );
    }
    return asset;
  }

  // A riding gift can optionally restrict itself to specific actions within
  // an otherwise-compatible template (GiftAsset.actionCompatibility) — e.g.
  // a ball narratively fits "playing" but not "sleeping", even within the
  // same template. Null (the default, and what the one current test gift
  // uses) means no restriction. Falls back to the full action pool if the
  // restriction would otherwise leave nothing pickable, so a gift
  // misconfigured against a template can never silently block generation
  // entirely.
  private actionPoolFor(
    template: EventTemplate,
    giftAsset: GiftAsset | null,
  ): string[] {
    const actionKeys = template.actionKeys as string[];
    const restriction = giftAsset?.actionCompatibility as string[] | null;
    if (!restriction) return actionKeys;
    const intersection = actionKeys.filter((a) => restriction.includes(a));
    return intersection.length > 0 ? intersection : actionKeys;
  }
}

function filterBySpecies<T extends { speciesApplicability: unknown }>(
  rows: T[],
  petType: string,
): T[] {
  return rows.filter((r) => {
    const species = r.speciesApplicability as string[] | null;
    return !species || species.includes(petType);
  });
}

function toResolvedAsset(
  asset: { key: string; nameZh: string; nameEn: string },
  visualDescription: string,
): ResolvedAsset {
  return {
    key: asset.key,
    nameZh: asset.nameZh,
    nameEn: asset.nameEn,
    visualDescription,
  };
}

function pickRandom<T>(items: T[]): T {
  return items[Math.floor(Math.random() * items.length)];
}
