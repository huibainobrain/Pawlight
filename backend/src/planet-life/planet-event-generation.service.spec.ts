import { PlanetEventGenerationService } from './planet-event-generation.service';
import { GiftsService } from './gifts.service';
import { PrismaService } from '../prisma/prisma.service';

function makePrisma() {
  return {
    planetLifeState: {
      findMany: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      update: jest.fn(),
    },
    planetEvent: { findFirst: jest.fn(), create: jest.fn() },
    pet: { findUniqueOrThrow: jest.fn() },
    photo: { findFirst: jest.fn() },
    eventTemplate: { findMany: jest.fn() },
    giftAsset: { findUnique: jest.fn() },
    giftInstance: { update: jest.fn() },
    locationAsset: { findMany: jest.fn() },
    actionAsset: { findMany: jest.fn() },
    contentAsset: { findUniqueOrThrow: jest.fn() },
    $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

function makeStorage() {
  return {
    upload: jest
      .fn()
      .mockImplementation(({ key }: { key: string }) =>
        Promise.resolve({ key, url: `https://r2.example/${key}` }),
      ),
    delete: jest.fn(),
  };
}

function makeTextGen() {
  return {
    generate: jest
      .fn()
      .mockResolvedValue({ title: 'A quiet afternoon', body: 'body text' }),
  };
}
function makeImageGen() {
  return {
    generate: jest.fn().mockResolvedValue({
      buffer: Buffer.from('fake'),
      contentType: 'image/png',
    }),
  };
}
function makeImageQuality() {
  return { check: jest.fn().mockResolvedValue({ pass: true }) };
}
function makeTextQuality() {
  return { check: jest.fn().mockResolvedValue({ pass: true }) };
}
function makeGiftsService() {
  return { getPendingForPet: jest.fn().mockResolvedValue(null) };
}

function asGiftsService(giftsService: ReturnType<typeof makeGiftsService>) {
  return giftsService as unknown as GiftsService;
}

// ── Content-asset fixtures ───────────────────────────────────────────────
// Deliberately mirror the real seed shape (English-slug keys, bilingual
// names, a model-facing description) rather than reusing raw Chinese text
// as a key — that conflation is exactly what this round's restructuring
// removes. Species/compatibility fields default to "no restriction" unless
// a specific test overrides them.
const LOCATION = {
  key: 'garden_corner',
  nameZh: '小花园',
  nameEn: 'the garden',
  imageGenPrompt: 'a small garden corner',
  speciesApplicability: null,
  incompatibleActionKeys: null,
  active: true,
};
const YARD_LOCATION = {
  key: 'yard',
  nameZh: '院子',
  nameEn: 'the yard',
  imageGenPrompt: 'a quiet backyard at night',
  speciesApplicability: null,
  incompatibleActionKeys: null,
  active: true,
};
const ACTION = {
  key: 'resting',
  nameZh: '趴着休息',
  nameEn: 'resting',
  visualAction: 'lying down quietly',
  speciesApplicability: null,
  incompatibleLocationKeys: null,
  active: true,
};
const PLAYING_ACTION = {
  key: 'playing',
  nameZh: '玩耍',
  nameEn: 'playing',
  visualAction: 'playfully batting at something',
  speciesApplicability: null,
  incompatibleLocationKeys: null,
  active: true,
};
const WALKING_ACTION = {
  key: 'walking',
  nameZh: '散步',
  nameEn: 'walking',
  visualAction: 'walking slowly',
  speciesApplicability: null,
  incompatibleLocationKeys: null,
  active: true,
};
const STARGAZING_ACTION = {
  key: 'stargazing',
  nameZh: '看星星',
  nameEn: 'stargazing',
  visualAction: 'lying on its back looking up at the stars',
  speciesApplicability: null,
  incompatibleLocationKeys: null,
  active: true,
};
const TIME_DAYTIME = {
  key: 'daytime',
  kind: 'TIME',
  nameZh: '白天',
  nameEn: 'daytime',
  visualDescription: 'bright daylight',
};
const TIME_NIGHT = {
  key: 'night',
  kind: 'TIME',
  nameZh: '夜晚',
  nameEn: 'night',
  visualDescription: 'a dark night sky',
};
const ATMOSPHERE_SUNNY = {
  key: 'sunny',
  kind: 'ATMOSPHERE',
  nameZh: '晴朗',
  nameEn: 'sunny',
  visualDescription: 'clear sky',
};
const AMBIENT_FLOWERS = {
  key: 'flowers_grass',
  kind: 'AMBIENT_DETAIL',
  nameZh: '花草',
  nameEn: 'flowers and grass',
  visualDescription: 'flowers scattered nearby',
};

const ALL_LOCATIONS = [LOCATION, YARD_LOCATION];
const ALL_ACTIONS = [ACTION, PLAYING_ACTION, WALKING_ACTION, STARGAZING_ACTION];
const ALL_CONTENT_ASSETS = [
  TIME_DAYTIME,
  TIME_NIGHT,
  ATMOSPHERE_SUNNY,
  AMBIENT_FLOWERS,
];

const TEMPLATE = {
  id: 'template-1',
  key: 'garden_rest',
  locationKeys: ['garden_corner'],
  actionKeys: ['resting'],
  timeKeys: ['daytime'],
  atmosphereKeys: ['sunny'],
  ambientDetailKeys: ['flowers_grass'],
  giftCompatible: true,
  weight: 1,
  cooldownDays: null,
  speciesApplicability: null,
  active: true,
};

function makeService(
  prisma = makePrisma(),
  storage = makeStorage(),
  textGen = makeTextGen(),
  imageGen = makeImageGen(),
  imageQuality = makeImageQuality(),
  textQuality = makeTextQuality(),
  giftsService = makeGiftsService(),
) {
  const service = new PlanetEventGenerationService(
    asPrismaService(prisma),
    storage,
    textGen,
    imageGen,
    imageQuality,
    textQuality,
    asGiftsService(giftsService),
  );
  return {
    service,
    prisma,
    storage,
    textGen,
    imageGen,
    imageQuality,
    textQuality,
    giftsService,
  };
}

function setUpDuePet(prisma: ReturnType<typeof makePrisma>) {
  prisma.planetLifeState.findMany.mockResolvedValue([
    {
      petId: 'pet-1',
      weeklyEventCount: 0,
      weeklyWindowStart: null,
    },
  ]);
  prisma.planetEvent.findFirst.mockResolvedValue(null); // no unread
  prisma.pet.findUniqueOrThrow.mockResolvedValue({
    id: 'pet-1',
    type: 'CAT',
    user: { language: 'zh' },
  });
  prisma.photo.findFirst.mockResolvedValue({ r2Url: 'https://r2/main.jpg' });
  prisma.eventTemplate.findMany.mockResolvedValue([TEMPLATE]);
  prisma.planetLifeState.findUniqueOrThrow.mockResolvedValue({
    petId: 'pet-1',
    weeklyEventCount: 0,
    weeklyWindowStart: null,
  });

  // Faithful-enough fakes of Prisma's `where: { key: { in: [...] } }`
  // filtering — real behavior matters here because the service trusts
  // whatever rows come back as the already-eligible candidate pool.
  prisma.locationAsset.findMany.mockImplementation(
    ({ where }: { where: { key: { in: string[] } } }) =>
      Promise.resolve(
        ALL_LOCATIONS.filter((l) => where.key.in.includes(l.key)),
      ),
  );
  prisma.actionAsset.findMany.mockImplementation(
    ({ where }: { where: { key: { in: string[] } } }) =>
      Promise.resolve(ALL_ACTIONS.filter((a) => where.key.in.includes(a.key))),
  );
  prisma.contentAsset.findUniqueOrThrow.mockImplementation(
    ({ where }: { where: { key: string } }) => {
      const found = ALL_CONTENT_ASSETS.find((c) => c.key === where.key);
      if (!found) {
        throw new Error(`test fixture missing ContentAsset "${where.key}"`);
      }
      return Promise.resolve(found);
    },
  );
}

describe('PlanetEventGenerationService.runTick — happy path', () => {
  it('publishes a PlanetEvent for a due pet with no pending gift', async () => {
    const { service, prisma, giftsService } = makeService();
    setUpDuePet(prisma);
    giftsService.getPendingForPet.mockResolvedValue(null);

    await service.runTick();

    expect(prisma.planetEvent.create).toHaveBeenCalledTimes(1);
    const createArg = prisma.planetEvent.create.mock.calls[0][0];
    expect(createArg.data.giftInstanceId).toBeUndefined();
    expect(prisma.giftInstance.update).not.toHaveBeenCalled();
  });

  // Core gift-fulfillment path: a pending gift riding a gift-compatible
  // template gets embedded and marked COMPLETED in the same transaction the
  // event is published in.
  it('embeds a pending gift and marks it COMPLETED when the event publishes', async () => {
    const { service, prisma, giftsService } = makeService();
    setUpDuePet(prisma);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-ball',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      nameZh: '小球',
      nameEn: 'Ball',
      eventCompatibility: ['garden_rest'],
      actionCompatibility: null,
    });

    await service.runTick();

    const createArg = prisma.planetEvent.create.mock.calls[0][0];
    expect(createArg.data.giftInstanceId).toBe('gift-instance-a');
    expect(prisma.giftInstance.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'gift-instance-a' },
        data: expect.objectContaining({ status: 'COMPLETED' }),
      }),
    );
  });
});

// This whole describe block exists to prove the system is genuinely
// data-driven: with only one template and one gift, a bug that ignored
// GiftAsset.eventCompatibility entirely would be invisible (any pending gift
// always happened to match the only template). These tests add a SECOND
// template and a SECOND gift purely as test fixtures (no new seed/production
// data) specifically to catch that class of bug.
describe('PlanetEventGenerationService.runTick — gift/template compatibility is read, not assumed', () => {
  const OTHER_TEMPLATE = {
    id: 'template-2',
    key: 'star_gazing',
    locationKeys: ['yard'],
    actionKeys: ['stargazing'],
    timeKeys: ['night'],
    atmosphereKeys: ['sunny'],
    ambientDetailKeys: null,
    giftCompatible: true,
    weight: 1,
    cooldownDays: null,
    speciesApplicability: null,
    active: true,
  };

  it('does not embed a pending gift into a template the gift does not list as compatible', async () => {
    const { service, prisma, giftsService } = makeService();
    setUpDuePet(prisma);
    // Only garden_rest is eligible this tick; the pending gift is only
    // compatible with a template that isn't even in play.
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-star',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-star',
      eventCompatibility: ['star_gazing'], // NOT 'garden_rest'
      actionCompatibility: null,
    });

    await service.runTick();

    expect(prisma.planetEvent.create).toHaveBeenCalledTimes(1);
    const createArg = prisma.planetEvent.create.mock.calls[0][0];
    expect(createArg.data.eventTemplateKey).toBe('garden_rest');
    expect(createArg.data.giftInstanceId).toBeUndefined(); // gift did NOT ride along
    expect(prisma.giftInstance.update).not.toHaveBeenCalled(); // and was not consumed
  });

  it('prefers a gift-compatible template over other eligible templates when a gift is pending', async () => {
    const { service, prisma, giftsService } = makeService();
    setUpDuePet(prisma);
    // Two eligible templates; the pending gift is compatible with only one.
    prisma.eventTemplate.findMany.mockResolvedValue([TEMPLATE, OTHER_TEMPLATE]);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-star',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-star',
      eventCompatibility: ['star_gazing'],
      actionCompatibility: null,
    });

    // Run several times — template selection is random among eligible
    // templates, so assert the biasing deterministically holds every time
    // rather than relying on one lucky draw.
    for (let i = 0; i < 10; i++) {
      prisma.planetEvent.create.mockClear();
      prisma.giftInstance.update.mockClear();
      await service.runTick();
      const createArg = prisma.planetEvent.create.mock.calls[0][0];
      expect(createArg.data.eventTemplateKey).toBe('star_gazing');
      expect(createArg.data.giftInstanceId).toBe('gift-instance-a');
    }
  });

  it('restricts the chosen action to the gift actionCompatibility intersection when set', async () => {
    const { service, prisma, giftsService } = makeService();
    setUpDuePet(prisma);
    prisma.eventTemplate.findMany.mockResolvedValue([
      { ...TEMPLATE, actionKeys: ['resting', 'playing', 'walking'] },
    ]);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-ball',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      eventCompatibility: ['garden_rest'],
      actionCompatibility: ['playing'], // only "playing" makes sense for a ball
    });

    for (let i = 0; i < 10; i++) {
      await service.runTick();
    }

    const facts = prisma.planetEvent.create.mock.calls.map(
      (call: unknown[]) =>
        (
          call[0] as {
            data: { factsJson: { action: { key: string } } };
          }
        ).data.factsJson.action,
    );
    expect(facts.every((a: { key: string }) => a.key === 'playing')).toBe(true);
  });
});

// Proves Location/Action/Time/Atmosphere/Ambient Detail are genuinely
// structured, keyed assets — not just a rename of the old raw-string pools.
// Each test here would fail against the pre-restructuring code (which had no
// species/compatibility concept below the template level, and returned bare
// strings instead of bilingual ResolvedAsset objects).
describe('PlanetEventGenerationService.runTick — content assets are structured, not raw strings', () => {
  it('resolves facts to bilingual ResolvedAsset objects, not raw pool strings', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);

    await service.runTick();

    const facts = prisma.planetEvent.create.mock.calls[0][0].data.factsJson;
    expect(facts.location).toMatchObject({
      key: 'garden_corner',
      nameZh: '小花园',
      nameEn: 'the garden',
      visualDescription: 'a small garden corner',
    });
    expect(facts.action).toMatchObject({
      key: 'resting',
      nameZh: '趴着休息',
      nameEn: 'resting',
    });
  });

  it('excludes a LocationAsset not applicable to the pet species, falling back only if that would leave nothing pickable', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);
    prisma.locationAsset.findMany.mockResolvedValue([
      LOCATION,
      { ...YARD_LOCATION, key: 'dog_yard', speciesApplicability: ['DOG'] },
    ]);
    prisma.eventTemplate.findMany.mockResolvedValue([
      { ...TEMPLATE, locationKeys: ['garden_corner', 'dog_yard'] },
    ]);
    // setUpDuePet's pet is a CAT.

    for (let i = 0; i < 10; i++) {
      await service.runTick();
    }

    const locations = prisma.planetEvent.create.mock.calls.map(
      (call: unknown[]) =>
        (call[0] as { data: { factsJson: { location: { key: string } } } }).data
          .factsJson.location.key,
    );
    expect(locations.every((k: string) => k === 'garden_corner')).toBe(true);
  });

  it('excludes an action the chosen location lists as incompatible, falling back to the full pool only when nothing else is left', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);
    prisma.locationAsset.findMany.mockResolvedValue([
      { ...LOCATION, incompatibleActionKeys: ['playing'] },
    ]);
    prisma.eventTemplate.findMany.mockResolvedValue([
      { ...TEMPLATE, actionKeys: ['resting', 'playing'] },
    ]);

    for (let i = 0; i < 10; i++) {
      await service.runTick();
    }

    const actions = prisma.planetEvent.create.mock.calls.map(
      (call: unknown[]) =>
        (call[0] as { data: { factsJson: { action: { key: string } } } }).data
          .factsJson.action.key,
    );
    expect(actions.every((k: string) => k === 'resting')).toBe(true);
  });

  it('never blocks generation even when every candidate action is excluded by the location', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);
    prisma.locationAsset.findMany.mockResolvedValue([
      { ...LOCATION, incompatibleActionKeys: ['resting'] },
    ]);
    prisma.eventTemplate.findMany.mockResolvedValue([
      { ...TEMPLATE, actionKeys: ['resting'] }, // the only action is also excluded
    ]);

    await service.runTick();

    expect(prisma.planetEvent.create).toHaveBeenCalledTimes(1); // still publishes
  });
});

describe('PlanetEventGenerationService.runTick — quality gates never consume a gift', () => {
  // Case 6/7 (dev spec §37): any failure leaves the Gift Instance untouched
  // and does not publish anything.
  it('does not publish or touch the gift when text quality fails', async () => {
    const { service, prisma, giftsService, textQuality } = makeService();
    setUpDuePet(prisma);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-ball',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      eventCompatibility: ['garden_rest'],
      actionCompatibility: null,
    });
    textQuality.check.mockResolvedValue({ pass: false, reason: 'test' });

    await service.runTick();

    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
    expect(prisma.giftInstance.update).not.toHaveBeenCalled();
  });

  it('does not publish or touch the gift when image quality fails', async () => {
    const { service, prisma, giftsService, imageQuality } = makeService();
    setUpDuePet(prisma);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-ball',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      eventCompatibility: ['garden_rest'],
      actionCompatibility: null,
    });
    imageQuality.check.mockResolvedValue({ pass: false, reason: 'test' });

    await service.runTick();

    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
    expect(prisma.giftInstance.update).not.toHaveBeenCalled();
  });

  // PRD §49: "自动重试" — a single quality-check failure gets one retry
  // before the tick gives up for this pet.
  it('retries once and publishes when the retry attempt passes text quality', async () => {
    const { service, prisma, textQuality } = makeService();
    setUpDuePet(prisma);
    textQuality.check
      .mockResolvedValueOnce({ pass: false, reason: 'first attempt' })
      .mockResolvedValueOnce({ pass: true });

    await service.runTick();

    expect(textQuality.check).toHaveBeenCalledTimes(2);
    expect(prisma.planetEvent.create).toHaveBeenCalledTimes(1);
  });

  it('retries once and publishes when the retry attempt passes image quality', async () => {
    const { service, prisma, imageQuality } = makeService();
    setUpDuePet(prisma);
    imageQuality.check
      .mockResolvedValueOnce({ pass: false, reason: 'first attempt' })
      .mockResolvedValueOnce({ pass: true });

    await service.runTick();

    expect(imageQuality.check).toHaveBeenCalledTimes(2);
    expect(prisma.planetEvent.create).toHaveBeenCalledTimes(1);
  });

  it('gives up silently (without consuming a pending gift) after exhausting all retries', async () => {
    const { service, prisma, giftsService, textQuality } = makeService();
    setUpDuePet(prisma);
    giftsService.getPendingForPet.mockResolvedValue({
      id: 'gift-instance-a',
      giftAssetId: 'asset-ball',
    });
    prisma.giftAsset.findUnique.mockResolvedValue({
      id: 'asset-ball',
      eventCompatibility: ['garden_rest'],
      actionCompatibility: null,
    });
    textQuality.check.mockResolvedValue({ pass: false, reason: 'always' });

    await service.runTick();

    expect(textQuality.check).toHaveBeenCalledTimes(2); // 1 initial + 1 retry, then gives up
    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
    expect(prisma.giftInstance.update).not.toHaveBeenCalled();
  });

  it('does not publish when the provider throws, and does not let one pet crash the whole tick', async () => {
    const { service, prisma, textGen } = makeService();
    setUpDuePet(prisma);
    textGen.generate.mockRejectedValue(new Error('provider exploded'));

    await expect(service.runTick()).resolves.toBeUndefined();
    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
  });
});

describe('PlanetEventGenerationService.runTick — eligibility filtering', () => {
  it('skips a pet that already has an unread event', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);
    prisma.planetEvent.findFirst.mockResolvedValue({ id: 'already-unread' });

    await service.runTick();

    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
  });

  it('skips a pet that has hit the weekly cap', async () => {
    const { service, prisma } = makeService();
    prisma.planetLifeState.findMany.mockResolvedValue([
      {
        petId: 'pet-1',
        weeklyEventCount: 3,
        weeklyWindowStart: new Date(), // started just now, well within the window
      },
    ]);
    prisma.planetEvent.findFirst.mockResolvedValue(null);

    await service.runTick();

    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
  });

  it('skips a pet with no main photo yet', async () => {
    const { service, prisma } = makeService();
    setUpDuePet(prisma);
    prisma.photo.findFirst.mockResolvedValue(null);

    await service.runTick();

    expect(prisma.planetEvent.create).not.toHaveBeenCalled();
  });
});
