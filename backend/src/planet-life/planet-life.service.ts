import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { ContentAssetKind, HomeVariantKind, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';
import { GiftsService } from './gifts.service';
import { HomeProfileService } from './home-profile.service';
import { PlanetEventGenerationService } from './planet-event-generation.service';
import {
  MAX_EVENT_INTERVAL_HOURS,
  MIN_EVENT_INTERVAL_HOURS,
} from './planet-life.constants';

@Injectable()
export class PlanetLifeService implements OnModuleInit {
  private readonly logger = new Logger(PlanetLifeService.name);

  constructor(
    private prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private storage: StorageService,
    private giftsService: GiftsService,
    private generationService: PlanetEventGenerationService,
    private homeProfileService: HomeProfileService,
  ) {}

  // Ensures the P0 test EventTemplate/GiftAsset/GiftProduct rows exist on
  // every boot (dev, CI, and a fresh prod deploy alike) — these are
  // human-curated reference data (PRD §22-23), not dev-only sample data like
  // prisma/seed.ts, so they can't depend on someone remembering to run a
  // separate seed script.
  async onModuleInit() {
    await this.seedReferenceData();
  }

  private async seedReferenceData() {
    await this.seedContentAssets();
    await this.seedHomeIdentityFoundation();

    await this.upsertTolerateRace(
      () =>
        this.prisma.locationAsset.upsert({
          where: { key: 'garden_corner' },
          update: {},
          create: {
            key: 'garden_corner',
            nameZh: '小花园',
            nameEn: 'the garden',
            visualDefinition:
              '家门口的小花园角落，木质围栏、绿色灌木，光线柔和。',
            imageGenPrompt:
              'a small home garden corner with a wooden fence and green shrubs, soft natural daylight',
          },
        }),
      () =>
        this.prisma.locationAsset.findUniqueOrThrow({
          where: { key: 'garden_corner' },
        }),
    );

    await this.upsertTolerateRace(
      () =>
        this.prisma.actionAsset.upsert({
          where: { key: 'resting' },
          update: {},
          create: {
            key: 'resting',
            nameZh: '趴着休息',
            nameEn: 'resting',
            visualAction:
              'lying down quietly, eyes half-closed, tail relaxed and still',
          },
        }),
      () =>
        this.prisma.actionAsset.findUniqueOrThrow({
          where: { key: 'resting' },
        }),
    );

    await this.upsertTolerateRace(
      () =>
        this.prisma.eventTemplate.upsert({
          where: { key: 'garden_rest' },
          update: {},
          create: {
            key: 'garden_rest',
            locationKeys: ['garden_corner'],
            actionKeys: ['resting'],
            timeKeys: ['daytime', 'dusk'],
            atmosphereKeys: ['sunny', 'breezy'],
            ambientDetailKeys: ['flowers_grass'],
            giftCompatible: true,
            weight: 1,
            active: true,
          },
        }),
      () =>
        this.prisma.eventTemplate.findUniqueOrThrow({
          where: { key: 'garden_rest' },
        }),
    );

    const ball = await this.upsertTolerateRace(
      () =>
        this.prisma.giftAsset.upsert({
          where: { key: 'ball' },
          update: {},
          create: {
            key: 'ball',
            nameZh: '小球',
            nameEn: 'Ball',
            descriptionZh: '轻轻一推，就能滚向更远的地方。',
            descriptionEn: 'A gentle push sends it rolling further away.',
            illustrationAssetName: 'gift_ball',
            eventCompatibility: ['garden_rest'],
            repeatable: true,
            saleStatus: 'ACTIVE',
            displayOrder: 0,
          },
        }),
      () => this.prisma.giftAsset.findUniqueOrThrow({ where: { key: 'ball' } }),
    );

    await this.upsertTolerateRace(
      () =>
        this.prisma.giftProduct.upsert({
          where: { productId: 'com.pawlight.gift.ball.test' },
          update: {},
          create: {
            giftAssetId: ball.id,
            platform: 'ios',
            // Placeholder test id — not a real App Store Connect product.
            // See the plan's "待确认" list.
            productId: 'com.pawlight.gift.ball.test',
            active: true,
          },
        }),
      () =>
        this.prisma.giftProduct.findUniqueOrThrow({
          where: { productId: 'com.pawlight.gift.ball.test' },
        }),
    );
  }

  // Time/Atmosphere/Ambient Detail share one table (ContentAsset, kind-
  // discriminated) since the product spec gives all three the same minimal
  // shape — see schema.prisma's comment on that model. Seeded with the
  // minimal set garden_rest's pools reference, nothing more.
  private async seedContentAssets() {
    const rows: Array<{
      key: string;
      kind: ContentAssetKind;
      nameZh: string;
      nameEn: string;
      visualDescription: string;
    }> = [
      {
        key: 'daytime',
        kind: ContentAssetKind.TIME,
        nameZh: '白天',
        nameEn: 'daytime',
        visualDescription: 'bright midday light',
      },
      {
        key: 'dusk',
        kind: ContentAssetKind.TIME,
        nameZh: '黄昏',
        nameEn: 'dusk',
        visualDescription: 'warm dusk light, soft orange glow',
      },
      {
        key: 'sunny',
        kind: ContentAssetKind.ATMOSPHERE,
        nameZh: '晴朗',
        nameEn: 'sunny',
        visualDescription: 'clear sunny sky, no clouds',
      },
      {
        key: 'breezy',
        kind: ContentAssetKind.ATMOSPHERE,
        nameZh: '微风',
        nameEn: 'breezy',
        visualDescription: 'a gentle breeze moving the leaves',
      },
      {
        key: 'flowers_grass',
        kind: ContentAssetKind.AMBIENT_DETAIL,
        nameZh: '花草',
        nameEn: 'flowers and grass',
        visualDescription: 'small flowers and grass scattered nearby',
      },
    ];
    for (const row of rows) {
      await this.upsertTolerateRace(
        () =>
          this.prisma.contentAsset.upsert({
            where: { key: row.key },
            update: {},
            create: row,
          }),
        () =>
          this.prisma.contentAsset.findUniqueOrThrow({
            where: { key: row.key },
          }),
      );
    }
  }

  // Canonical Planet World / Home Identity foundation (this round's new
  // layer): one test PlanetStyle version, one test HomeVariantAsset per
  // dimension, and the one HOME_BASE Location + homeAnchorEligible Template
  // needed to actually exercise the Home Anchor lifecycle end-to-end. Still
  // only the minimal set the architecture needs proven — not a real Home
  // Variant/Location library (that stays for a future round, see the
  // Production Asset Checklist).
  private async seedHomeIdentityFoundation() {
    await this.upsertTolerateRace(
      () =>
        this.prisma.planetStyle.upsert({
          where: { key: 'pawlight_planet_v1' },
          update: {},
          create: {
            key: 'pawlight_planet_v1',
            version: 1,
            illustrationLanguage:
              'soft, hand-painted illustration with gentle linework, not photorealistic',
            realismLevel: 'stylized/illustrated, not photoreal',
            colorSaturationDirection:
              'warm, muted, slightly desaturated pastels',
            lighting:
              'soft diffused daylight, gentle shadows, no harsh contrast',
            materialFeel: 'painterly, watercolor-like textures with soft edges',
            worldSafetyRules:
              'nothing frightening, no real danger, no violence, no threatening darkness',
            forbiddenWorldStyles:
              'no cyberpunk, no urban cityscape, no realistic mansion, no sci-fi, no photorealistic rendering',
            imageGenGuidance:
              'A soft, hand-painted illustration style with gentle linework and warm, slightly desaturated pastel colors. Lighting is soft and diffused with no harsh shadows. Avoid photorealism, cyberpunk, urban, sci-fi, or mansion-like settings — keep the world gentle, warm, quiet, and safe.',
            active: true,
          },
        }),
      () =>
        this.prisma.planetStyle.findUniqueOrThrow({
          where: { key: 'pawlight_planet_v1' },
        }),
    );

    const variants: Array<{
      key: string;
      kind: HomeVariantKind;
      nameZh: string;
      nameEn: string;
      visualDefinition: string;
      imageGenPrompt: string;
      colorTokens?: string[];
    }> = [
      {
        key: 'cottage_warm_wood',
        kind: HomeVariantKind.COTTAGE_BLUEPRINT,
        nameZh: '暖木小屋',
        nameEn: 'warm wooden cottage',
        visualDefinition: '一座温暖的木质小屋，低矮坡顶，轮廓圆润友好。',
        imageGenPrompt:
          'a small warm wooden cottage with a gently sloped roof and rounded, friendly proportions',
      },
      {
        key: 'palette_sage',
        kind: HomeVariantKind.PALETTE,
        nameZh: '鼠尾草绿',
        nameEn: 'sage palette',
        visualDefinition: '以鼠尾草绿和奶白色为主的柔和配色。',
        imageGenPrompt:
          'a soft color palette of sage green and warm cream tones',
        colorTokens: ['#8fae8a', '#f5f0e3', '#6b8c66'],
      },
      {
        key: 'roof_deep_green',
        kind: HomeVariantKind.ROOF,
        nameZh: '深绿色斜屋顶',
        nameEn: 'deep green sloped roof',
        visualDefinition: '深绿色的坡形屋顶。',
        imageGenPrompt: 'a deep green sloped roof',
      },
      {
        key: 'door_round_wood',
        kind: HomeVariantKind.DOOR,
        nameZh: '圆形木门',
        nameEn: 'round wooden door',
        visualDefinition: '一扇圆形的木质小门，带黄铜把手。',
        imageGenPrompt: 'a round wooden door with a small brass handle',
      },
      {
        key: 'window_round',
        kind: HomeVariantKind.WINDOW,
        nameZh: '圆形窗户',
        nameEn: 'round window',
        visualDefinition: '一个圆形的窗户，透出柔和的光。',
        imageGenPrompt: 'a round window with warm light glowing from inside',
      },
      {
        key: 'plant_white_daisies',
        kind: HomeVariantKind.SIGNATURE_PLANT,
        nameZh: '白色小花',
        nameEn: 'white daisies',
        visualDefinition: '门边种着一簇白色小花。',
        imageGenPrompt:
          'a small cluster of white daisies growing near the entrance',
      },
    ];
    for (const v of variants) {
      await this.upsertTolerateRace(
        () =>
          this.prisma.homeVariantAsset.upsert({
            where: { key: v.key },
            update: {},
            create: { ...v, colorTokens: v.colorTokens ?? undefined },
          }),
        () =>
          this.prisma.homeVariantAsset.findUniqueOrThrow({
            where: { key: v.key },
          }),
      );
    }

    await this.upsertTolerateRace(
      () =>
        this.prisma.locationAsset.upsert({
          where: { key: 'home_entrance' },
          update: {},
          create: {
            key: 'home_entrance',
            nameZh: '小屋门前',
            nameEn: 'the cottage doorstep',
            scope: 'HOME_BASE',
            visualDefinition:
              '小屋正门外的区域，取景以门口和门前小路为主——具体建筑外观由每只宠物的 Home Profile 决定，这里只定义空间范围，不固定任何具体建筑样式。',
            imageGenPrompt:
              "the area just outside the pet's front door, framing the entrance and the path leading up to it",
          },
        }),
      () =>
        this.prisma.locationAsset.findUniqueOrThrow({
          where: { key: 'home_entrance' },
        }),
    );

    await this.upsertTolerateRace(
      () =>
        this.prisma.eventTemplate.upsert({
          where: { key: 'home_doorstep_rest' },
          update: {},
          create: {
            key: 'home_doorstep_rest',
            locationKeys: ['home_entrance'],
            actionKeys: ['resting'],
            timeKeys: ['daytime', 'dusk'],
            atmosphereKeys: ['sunny', 'breezy'],
            ambientDetailKeys: ['flowers_grass'],
            giftCompatible: false,
            homeAnchorEligible: true,
            weight: 1,
            active: true,
          },
        }),
      () =>
        this.prisma.eventTemplate.findUniqueOrThrow({
          where: { key: 'home_doorstep_rest' },
        }),
    );
  }

  // Prisma's upsert() is a find-then-create/update round trip, not a single
  // atomic SQL statement — concurrent app instances seeding the same
  // reference row for the first time (e.g. multiple e2e spec files booting
  // AppModule in parallel Jest workers against one shared test database)
  // can both pass the "not found" check and both attempt create, so the
  // loser hits a real unique-constraint violation here rather than a true
  // bug. Falling back to a plain read on that specific race is correct
  // because the desired end state — the row exists — is already satisfied
  // by whichever call won.
  private async upsertTolerateRace<T>(
    upsert: () => Promise<T>,
    reread: () => Promise<T>,
  ): Promise<T> {
    try {
      return await upsert();
    } catch (err) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        return reread();
      }
      throw err;
    }
  }

  async getStatus(userId: string, petId: string) {
    await this.assertPetOwner(userId, petId);
    const [state, unread, recent, homeProfile] = await Promise.all([
      this.prisma.planetLifeState.findUnique({ where: { petId } }),
      this.prisma.planetEvent.findFirst({
        where: { petId, status: 'UNREAD' },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.planetEvent.findMany({
        where: { petId, status: { in: ['UNREAD', 'READ'] } },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
      // Debug/visibility only — nothing in the generation pipeline reads
      // this response; it reads HomeProfile directly. Null before the
      // first enable.
      this.prisma.homeProfile.findUnique({ where: { petId } }),
    ]);
    return { state, unread, recent, homeProfile };
  }

  // PRD §5: first-ever enable requires paid + at least one completed AI
  // scene (observationVideoUrl set). After that, Star Life keeps running
  // even if the user later reverts to the static photo (§5.1) — this check
  // only gates the initial opt-in, nothing re-checks observationVideoUrl on
  // every tick.
  async enable(userId: string, petId: string, notifyOnNewEvent: boolean) {
    const pet = await this.assertPetOwner(userId, petId);
    const entitlement = await this.prisma.entitlement.findUnique({
      where: { userId },
    });
    if (!entitlement?.starLifeEnabled) {
      throw new ForbiddenException({
        code: 'PAID_ONLY',
        message: '这是完整纪念空间的功能',
      });
    }
    if (!pet.observationVideoUrl) {
      throw new BadRequestException({
        code: 'NO_SCENE_PORTRAIT_YET',
        message: '请先完成一次 AI 场景生成',
      });
    }

    // Idempotent, runs once ever — a pet that already has a HomeProfile
    // (re-enabling after a pause, or a retried request) is never re-rolled.
    // Deliberately does not read pet.observationVideoUrl/scenePortraitJobs
    // beyond the gate above — Personal Scene plays no part in which Home
    // Variants get picked (PRD: "Personal Scene 不参与 Home Variant 选择").
    await this.homeProfileService.initializeIfNeeded(petId, pet.name);

    return this.prisma.planetLifeState.upsert({
      where: { petId },
      update: {
        enabled: true,
        paused: false,
        notifyOnNewEvent,
        nextEligibleAt: randomNextEligibleAt(),
      },
      create: {
        petId,
        enabled: true,
        notifyOnNewEvent,
        nextEligibleAt: randomNextEligibleAt(),
      },
    });
  }

  async updateSettings(
    userId: string,
    petId: string,
    data: { notifyOnNewEvent?: boolean; paused?: boolean },
  ) {
    await this.assertPetOwner(userId, petId);
    const state = await this.prisma.planetLifeState.findUnique({
      where: { petId },
    });
    if (!state) {
      throw new BadRequestException({
        code: 'STAR_LIFE_NOT_ENABLED',
        message: '星球生活还没有开启',
      });
    }
    return this.prisma.planetLifeState.update({
      where: { petId },
      data,
    });
  }

  async listEvents(userId: string, petId: string) {
    await this.assertPetOwner(userId, petId);
    return this.prisma.planetEvent.findMany({
      where: { petId, status: { in: ['UNREAD', 'READ'] } },
      orderBy: { createdAt: 'desc' },
    });
  }

  // Restarts the wait from the moment the user reads the event (PRD §19),
  // not from when it was published — see PlanetLifeState.nextEligibleAt.
  async markRead(userId: string, petId: string, eventId: string) {
    const event = await this.assertEventOwner(userId, petId, eventId);
    if (event.status !== 'UNREAD') return event;

    const [updated] = await this.prisma.$transaction([
      this.prisma.planetEvent.update({
        where: { id: eventId },
        data: { status: 'READ', readAt: new Date() },
      }),
      this.prisma.planetLifeState.update({
        where: { petId },
        data: { nextEligibleAt: randomNextEligibleAt() },
      }),
    ]);
    return updated;
  }

  // "这张照片不像 TA" (PRD §50): hide the content, record it as a bad case,
  // and — if this event carried a gift — void that fulfillment attempt and
  // put the Gift Instance back to Pending with no new charge. If this event
  // happens to be the one currently holding this pet's Home Anchor, the
  // anchor is invalidated too (HomeProfile itself is never deleted or
  // re-rolled — only its anchor pointer/status) — the next eligible Home
  // event re-establishes a new version.
  async markBadCase(userId: string, petId: string, eventId: string) {
    const event = await this.assertEventOwner(userId, petId, eventId);
    if (event.status === 'BAD_CASE') return event;

    const updated = await this.prisma.planetEvent.update({
      where: { id: eventId },
      data: { status: 'BAD_CASE' },
    });
    if (event.giftInstanceId) {
      await this.giftsService.revertToPending(event.giftInstanceId);
    }
    await this.homeProfileService.invalidateAnchorIfCurrent(petId, eventId);
    return updated;
  }

  // DEBUG "测试：模拟星球来信" (behind X-Debug-Secret — see
  // PlanetLifeController.assertDebugSecret). Forces only the TIME gate open
  // (nextEligibleAt -> now) and then runs the real scheduler tick — every
  // other invariant (enabled/paused/no-unread/weekly cap) still applies
  // exactly as it would for a real user, so this never fabricates a result
  // that couldn't also happen for real. Uses whichever providers are
  // currently configured, which today is always 'fake' (see
  // planet-life.module.ts) — zero real AI either way.
  async debugForceTick(userId: string, petId: string) {
    await this.assertPetOwner(userId, petId);
    const state = await this.prisma.planetLifeState.findUnique({
      where: { petId },
    });
    if (!state?.enabled) {
      throw new BadRequestException({
        code: 'STAR_LIFE_NOT_ENABLED',
        message: '星球生活还没有开启',
      });
    }
    await this.prisma.planetLifeState.update({
      where: { petId },
      data: { nextEligibleAt: new Date(0) },
    });
    await this.generationService.runTick();
    return this.getStatus(userId, petId);
  }

  // DEBUG "测试：真实生成一次". Refuses with a clear, specific error instead
  // of silently falling back to the fake pipeline — today every Planet Life
  // provider is 'fake' (no real vendor registered yet), so this always
  // refuses. Once a real provider is registered and configured via env var,
  // this starts actually running it via the same force-tick path.
  async debugLiveTrigger(userId: string, petId: string) {
    await this.assertPetOwner(userId, petId);
    const missing = this.generationService.getUnconfiguredRealProviders();
    if (missing.length > 0) {
      throw new BadRequestException({
        code: 'AI_PROVIDER_NOT_CONFIGURED',
        message: 'AI Provider 尚未配置，暂时无法真实生成',
        missing,
      });
    }
    return this.debugForceTick(userId, petId);
  }

  // DEBUG "重置星球生活" — clears this one pet's PlanetEvent/GiftInstance/
  // PlanetLifeState/HomeProfile rows so repeated manual testing doesn't
  // require recreating the pet or hand-editing the database between runs.
  // HomeProfile is included deliberately: without clearing it, a tester
  // could never re-exercise the "fresh init" path (Case 1/2) after the
  // first run, only the "already exists" idempotent path. Deletes
  // PlanetEvent before GiftInstance (the FK has no onDelete: Cascade, since a
  // GiftInstance legitimately outlives any one event across bad-case
  // retries) so nothing still references a row this removes. Never touches
  // other pets or the user's account.
  async debugReset(userId: string, petId: string) {
    await this.assertPetOwner(userId, petId);
    const [events, homeProfile] = await Promise.all([
      this.prisma.planetEvent.findMany({
        where: { petId },
        select: { imageR2Key: true },
      }),
      this.prisma.homeProfile.findUnique({
        where: { petId },
        select: { homeAnchorImageR2Key: true },
      }),
    ]);
    await Promise.all([
      ...events.map((e) => this.storage.delete(e.imageR2Key)),
      ...(homeProfile?.homeAnchorImageR2Key
        ? [this.storage.delete(homeProfile.homeAnchorImageR2Key)]
        : []),
    ]);
    await this.prisma.$transaction([
      this.prisma.planetEvent.deleteMany({ where: { petId } }),
      this.prisma.giftInstance.deleteMany({ where: { petId } }),
      this.prisma.planetLifeState.deleteMany({ where: { petId } }),
      this.prisma.homeProfile.deleteMany({ where: { petId } }),
    ]);
    return { ok: true };
  }

  // Used by account deletion (AuthService.deleteAccount): removes every
  // planet-life R2 object owned by this user's pet(s) — chronicle images
  // and any Home Anchor image. DB rows are left to the Pet -> User cascade
  // delete, which can't reach into R2 on its own — same split as
  // ScenePortraitsService.deleteAllForUser.
  async deleteAllForUser(userId: string) {
    const [events, homeProfiles] = await Promise.all([
      this.prisma.planetEvent.findMany({
        where: { pet: { userId } },
        select: { imageR2Key: true },
      }),
      this.prisma.homeProfile.findMany({
        where: { pet: { userId } },
        select: { homeAnchorImageR2Key: true },
      }),
    ]);
    await Promise.all([
      ...events.map((e) => this.storage.delete(e.imageR2Key)),
      ...homeProfiles
        .filter((h) => h.homeAnchorImageR2Key)
        .map((h) => this.storage.delete(h.homeAnchorImageR2Key as string)),
    ]);
  }

  private async assertPetOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();
    return pet;
  }

  private async assertEventOwner(
    userId: string,
    petId: string,
    eventId: string,
  ) {
    await this.assertPetOwner(userId, petId);
    const event = await this.prisma.planetEvent.findUnique({
      where: { id: eventId },
    });
    if (!event || event.petId !== petId) {
      throw new NotFoundException('Event not found');
    }
    return event;
  }
}

export function randomNextEligibleAt(now: Date = new Date()): Date {
  const minMs = MIN_EVENT_INTERVAL_HOURS * 60 * 60 * 1000;
  const maxMs = MAX_EVENT_INTERVAL_HOURS * 60 * 60 * 1000;
  const intervalMs = minMs + Math.random() * (maxMs - minMs);
  return new Date(now.getTime() + intervalMs);
}
