import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { PlanetEventGenerationService } from '../src/planet-life/planet-event-generation.service';

// Full-stack e2e tests against a real (local/test-only) Postgres, with fake
// text/image/quality providers and fake storage (see test/env.setup.ts) —
// never a real AI vendor call. See docs/reference/testing.md and the
// approved plan doc for the Planet Life / Gift design this exercises.
//
// The generation pipeline is driven by a cron tick (PlanetLifeScheduler),
// not by an HTTP request, so these tests call
// PlanetEventGenerationService.runTick() directly (pulled from the real DI
// container) to simulate a tick firing, instead of waiting on a real timer.
// Likewise, a real Gift purchase requires a cryptographically valid Apple
// JWS that can't be fabricated in a test — PurchasesService's dispatch logic
// is already unit-tested (purchases.service.spec.ts) with a mocked
// verifier, so here a Pending GiftInstance is created directly via Prisma to
// stand in for "a purchase already succeeded", matching the same convention
// the existing e2e suite uses for FREE/PAID entitlement setup.

type TestHttpServer = Parameters<typeof request>[0];

describe('Planet Life + Gifts e2e', () => {
  let app: INestApplication;
  let httpServer: TestHttpServer;
  let prisma: PrismaService;
  let generation: PlanetEventGenerationService;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();

    httpServer = app.getHttpServer() as TestHttpServer;
    prisma = app.get(PrismaService);
    generation = app.get(PlanetEventGenerationService);
  });

  afterAll(async () => {
    await app.close();
  });

  function authed(token: string) {
    return { Authorization: `Bearer ${token}` };
  }

  async function debugLogin() {
    const res = await request(httpServer)
      .post('/api/v1/auth/debug-login')
      .set('X-Debug-Secret', process.env.DEBUG_SECRET as string)
      .expect(201);
    return {
      token: res.body.access_token as string,
      userId: res.body.user.id as string,
    };
  }

  async function createPet(token: string, name = 'Mochi') {
    const res = await request(httpServer)
      .post('/api/v1/pets')
      .set(authed(token))
      .send({ name, type: 'CAT' })
      .expect(201);
    return res.body.id as string;
  }

  function uploadPhoto(
    token: string,
    petId: string,
    type: 'MAIN' | 'ALBUM' = 'ALBUM',
  ) {
    return request(httpServer)
      .post(`/api/v1/pets/${petId}/photos`)
      .set(authed(token))
      .field('type', type)
      .attach('file', Buffer.from('fake-image-bytes'), 'photo.jpg');
  }

  // debug-login grants PAID (and now starLifeEnabled) by default, but
  // enable() also requires a completed AI scene — set that up the same way
  // the existing scene-portraits e2e flow does (observationVideoUrl is only
  // ever set for real by that job's own DONE transition; here it's set
  // directly since this suite isn't re-testing that pipeline).
  async function setUpPaidPetWithScene(token: string, petId: string) {
    await uploadPhoto(token, petId, 'MAIN').expect(201);
    await prisma.pet.update({
      where: { id: petId },
      data: { observationVideoUrl: 'https://fake.example/video.mp4' },
    });
  }

  async function forceEligibleNow(petId: string) {
    await prisma.planetLifeState.update({
      where: { petId },
      data: { nextEligibleAt: new Date(0) },
    });
  }

  // ── Flow D: Star Life opt-in / generation / read cycle / pause ──────────
  describe('Flow D: enable gating, generation cadence, read cycle, pause', () => {
    it('rejects enable() for a FREE-tier account', async () => {
      const { token, userId } = await debugLogin();
      const petId = await createPet(token, 'Free Tier Pet');
      await prisma.entitlement.update({
        where: { userId },
        data: {
          tier: 'FREE',
          photoLimit: 9,
          mailboxEnabled: false,
          starLifeEnabled: false,
        },
      });

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(403)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'PAID_ONLY' });
        });
    });

    // PRD §5: AI Scene completion (observationVideoUrl) is a hard
    // prerequisite for the very first enable.
    it('rejects enable() before any AI scene has been completed', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'No Scene Yet Pet');
      await uploadPhoto(token, petId, 'MAIN').expect(201);

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(400)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'NO_SCENE_PORTRAIT_YET' });
        });
    });

    it('runs the full cycle: enable -> tick publishes one event -> no unread means it stays single -> read -> next tick waits again', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Star Life Pet');
      await setUpPaidPetWithScene(token, petId);

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      // Case: first wait starts from enable() itself, not "now" — a tick
      // right after enabling must not publish anything yet.
      await generation.runTick();
      let events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(0);

      // Force the wait to have elapsed, then the next tick should publish.
      await forceEligibleNow(petId);
      await generation.runTick();
      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(1);
      expect(events.body[0].status).toBe('UNREAD');
      const eventId = events.body[0].id as string;

      // Case 20 (PRD §20): an existing UNREAD event blocks further
      // generation even if eligibility time has also elapsed again.
      await forceEligibleNow(petId);
      await generation.runTick();
      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(1); // still just the one

      // Reading restarts the wait (PRD §19) — a tick immediately after
      // reading must not publish a second event yet.
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/events/${eventId}/read`)
        .set(authed(token))
        .expect(201)
        .expect((res) => expect(res.body.status).toBe('READ'));

      await generation.runTick();
      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(1); // no second event yet

      // Only once the (new, post-read) wait has also elapsed does a
      // second event appear.
      await forceEligibleNow(petId);
      await generation.runTick();
      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(2);
    }, 30000);

    // Case 9/12 (PRD §53): pausing stops new generation outright.
    it('pause blocks generation even when otherwise eligible; resume allows it again', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Pausable Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/planet-life/settings`)
        .set(authed(token))
        .send({ paused: true })
        .expect(200);

      await forceEligibleNow(petId);
      await generation.runTick();
      let events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(0);

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/planet-life/settings`)
        .set(authed(token))
        .send({ paused: false })
        .expect(200);
      await generation.runTick();
      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(1);
    });
  });

  // ── Flow E: Gift Asset / Gift Instance lifecycle ─────────────────────────
  describe('Flow E: gift purchase, fulfillment, bad case, repeat purchase', () => {
    async function createPendingGiftInstance(petId: string, txnSuffix: string) {
      const ball = await prisma.giftAsset.findUniqueOrThrow({
        where: { key: 'ball' },
      });
      return prisma.giftInstance.create({
        data: {
          petId,
          giftAssetId: ball.id,
          purchaseTransactionId: `e2e-txn-${txnSuffix}`,
          status: 'PENDING',
        },
      });
    }

    // Case 1: no Pending Gift -> purchase allowed.
    it('reports canPurchase: true with no pending gift, and lists the seeded ball asset', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Gift Pet 1');

      const res = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);

      expect(res.body.canPurchase).toBe(true);
      expect(
        res.body.assets.some((a: { key: string }) => a.key === 'ball'),
      ).toBe(true);
    });

    // Case 5: an existing Pending Gift blocks new purchases.
    it('reports canPurchase: false once a gift is pending', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Gift Pet 2');
      await createPendingGiftInstance(petId, 'pet2-a');

      const res = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);

      expect(res.body.canPurchase).toBe(false);
      expect(res.body.pending).toMatchObject({ status: 'PENDING' });
    });

    it('Case 9: a gift-bearing event completes the instance; marking it bad case reverts it to PENDING with no new charge', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Gift Pet 3');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      // A freshly-enabled pet has no Home Anchor yet, so selection is
      // restricted to the Home Base + homeAnchorEligible template
      // (home_doorstep_rest) until one publishes successfully — ball's
      // eventCompatibility only lists garden_rest, so it can't ride this
      // first event regardless. Establish the anchor first (its own event,
      // read so it stops blocking further generation), matching PRD §11's
      // real initialization order, before exercising the gift path this
      // test actually cares about.
      await forceEligibleNow(petId);
      await generation.runTick();
      const anchorEvents = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      await request(httpServer)
        .post(
          `/api/v1/pets/${petId}/planet-life/events/${anchorEvents.body[0].id}/read`,
        )
        .set(authed(token))
        .expect(201);

      const giftInstance = await createPendingGiftInstance(petId, 'pet3-a');

      await forceEligibleNow(petId);
      await generation.runTick();

      const events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      // 2, not 1: the anchor-establishing event from the step above, plus
      // this one.
      expect(events.body).toHaveLength(2);
      const event = events.body.find(
        (e: { giftInstanceId: string | null }) =>
          e.giftInstanceId === giftInstance.id,
      );
      expect(event).toBeTruthy();

      const completedInstance = await prisma.giftInstance.findUniqueOrThrow({
        where: { id: giftInstance.id },
      });
      expect(completedInstance.status).toBe('COMPLETED');

      // "这张照片不像 TA"
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/events/${event.id}/bad-case`)
        .set(authed(token))
        .expect(201)
        .expect((res) => expect(res.body.status).toBe('BAD_CASE'));

      const revertedInstance = await prisma.giftInstance.findUniqueOrThrow({
        where: { id: giftInstance.id },
      });
      expect(revertedInstance.status).toBe('PENDING');
      expect(revertedInstance.completedAt).toBeNull();

      // Still the same instance id — bad case never creates a new charge.
      const giftsRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);
      expect(giftsRes.body.pending.id).toBe(giftInstance.id);
    }, 20000);

    // Case 10/11: completing an instance allows buying the same gift again,
    // and that second purchase is an independent instance that never
    // touches the first one's history.
    it('Case 11: a repeat purchase after completion creates an independent new instance', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Gift Pet 4');
      const instanceA = await createPendingGiftInstance(petId, 'pet4-a');
      await prisma.giftInstance.update({
        where: { id: instanceA.id },
        data: { status: 'COMPLETED', completedAt: new Date() },
      });

      let res = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);
      expect(res.body.canPurchase).toBe(true); // A is no longer pending

      const instanceB = await createPendingGiftInstance(petId, 'pet4-b');

      res = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);
      expect(res.body.pending.id).toBe(instanceB.id);

      const untouchedA = await prisma.giftInstance.findUniqueOrThrow({
        where: { id: instanceA.id },
      });
      expect(untouchedA.status).toBe('COMPLETED');
      expect(untouchedA.id).not.toBe(instanceB.id);
    });

    // Case 12/13: pausing Star Life must never delete or alter a Pending Gift.
    it('Case 12: a pending gift survives pause/resume untouched', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Gift Pet 5');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);
      const instance = await createPendingGiftInstance(petId, 'pet5-a');

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/planet-life/settings`)
        .set(authed(token))
        .send({ paused: true })
        .expect(200);
      await forceEligibleNow(petId);
      await generation.runTick();

      const stillPending = await prisma.giftInstance.findUniqueOrThrow({
        where: { id: instance.id },
      });
      expect(stillPending.status).toBe('PENDING');
    });
  });

  // ── Flow F: DEBUG-only endpoints backing the iOS "测试：模拟星球来信" /
  // "测试：真实生成一次" tools ──────────────────────────────────────────────
  describe('Flow F: DEBUG fake-trigger / live-trigger / simulate-purchase', () => {
    function debugHeaders(token: string) {
      return {
        ...authed(token),
        'X-Debug-Secret': process.env.DEBUG_SECRET as string,
      };
    }

    it('rejects all three debug endpoints without a valid X-Debug-Secret', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Debug Secret Pet');

      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/planet-life/fake-trigger`)
        .set(authed(token)) // no X-Debug-Secret
        .expect(403);
      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/planet-life/live-trigger`)
        .set(authed(token))
        .expect(403);
      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/gifts/simulate-purchase`)
        .set(authed(token))
        .send({ giftAssetKey: 'ball' })
        .expect(403);
    });

    it('fake-trigger forces the wait and publishes exactly like a real scheduler tick would', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Debug Fake Trigger Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      const res = await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/planet-life/fake-trigger`)
        .set(debugHeaders(token))
        .expect(201);

      expect(res.body.unread).toBeTruthy();
      expect(res.body.unread.status).toBe('UNREAD');
    }, 15000);

    it('fake-trigger refuses before Star Life has ever been enabled', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Debug Not Enabled Pet');

      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/planet-life/fake-trigger`)
        .set(debugHeaders(token))
        .expect(400)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'STAR_LIFE_NOT_ENABLED' });
        });
    });

    // Today every PLANET_LIFE_*_PROVIDER env var is 'fake' (test/env.setup.ts)
    // — this must always refuse, never silently run the fake pipeline.
    it('live-trigger refuses with AI_PROVIDER_NOT_CONFIGURED since no real vendor exists yet', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Debug Live Trigger Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/planet-life/live-trigger`)
        .set(debugHeaders(token))
        .expect(400)
        .expect((res) => {
          expect(res.body).toMatchObject({
            code: 'AI_PROVIDER_NOT_CONFIGURED',
          });
          expect(res.body.missing).toEqual(
            expect.arrayContaining(['PLANET_LIFE_IMAGE_PROVIDER']),
          );
        });
    });

    it('simulate-purchase creates a Pending instance, then refuses a second one while it is still pending', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Debug Simulate Purchase Pet');

      const res = await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/gifts/simulate-purchase`)
        .set(debugHeaders(token))
        .send({ giftAssetKey: 'ball' })
        .expect(201);
      expect(res.body.status).toBe('PENDING');

      await request(httpServer)
        .post(`/api/v1/debug/pets/${petId}/gifts/simulate-purchase`)
        .set(debugHeaders(token))
        .send({ giftAssetKey: 'ball' })
        .expect(400)
        .expect((r) => {
          expect(r.body).toMatchObject({ code: 'GIFT_ALREADY_PENDING' });
        });

      const giftsRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/gifts`)
        .set(authed(token))
        .expect(200);
      expect(giftsRes.body.canPurchase).toBe(false);
      expect(giftsRes.body.pending.id).toBe(res.body.id);
    });
  });

  // ── Flow F: DEBUG reset ──────────────────────────────────────────────────
  describe('Flow F: DEBUG reset clears one pet without touching others', () => {
    it('clears events/gifts/state for the target pet only', async () => {
      const { token } = await debugLogin();
      const petA = await createPet(token, 'Reset Pet');
      await setUpPaidPetWithScene(token, petA);
      await request(httpServer)
        .post(`/api/v1/pets/${petA}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);
      await request(httpServer)
        .post(`/api/v1/debug/pets/${petA}/gifts/simulate-purchase`)
        .set({
          ...authed(token),
          'X-Debug-Secret': process.env.DEBUG_SECRET,
        })
        .send({ giftAssetKey: 'ball' })
        .expect(201);

      await request(httpServer)
        .post(`/api/v1/debug/pets/${petA}/planet-life/reset`)
        .set({
          ...authed(token),
          'X-Debug-Secret': process.env.DEBUG_SECRET,
        })
        .expect(201)
        .expect((r) => expect(r.body).toEqual({ ok: true }));

      const stateAfter = await prisma.planetLifeState.findUnique({
        where: { petId: petA },
      });
      expect(stateAfter).toBeNull();
      const giftsAfter = await prisma.giftInstance.findMany({
        where: { petId: petA },
      });
      expect(giftsAfter).toHaveLength(0);

      // Re-enabling after reset must work cleanly (no leftover row conflict).
      await request(httpServer)
        .post(`/api/v1/pets/${petA}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);
    });
  });

  // ── Flow G: proves the generation pipeline is genuinely data-driven —
  // adding a second template and a second gift (as test fixtures only, never
  // production seed data) must require zero changes to generation code for
  // the two to stay correctly isolated from each other. ────────────────────
  describe('Flow G: a second template/gift pair stays correctly isolated with no code changes', () => {
    it('never embeds a gift into a template it does not list as compatible, even across many ticks', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Extensibility Pet');
      await setUpPaidPetWithScene(token, petId);

      // Test-only fixtures — not seed data, not production content (see
      // AGENTS §17 of this round's audit instructions). Location/Action/Time
      // are new structured rows (this round's content-asset restructuring);
      // 'sunny' is reused from the real seed data to also prove an existing
      // ContentAsset can be shared across templates with zero code changes.
      await prisma.locationAsset.create({
        data: {
          key: `yard_${petId}`,
          nameZh: '院子',
          nameEn: 'the yard',
          visualDefinition: 'test fixture location',
          imageGenPrompt: 'a quiet backyard at night',
        },
      });
      await prisma.actionAsset.create({
        data: {
          key: `stargazing_${petId}`,
          nameZh: '看星星',
          nameEn: 'stargazing',
          visualAction: 'lying on its back looking up at the stars',
        },
      });
      await prisma.contentAsset.create({
        data: {
          key: `night_${petId}`,
          kind: 'TIME',
          nameZh: '夜晚',
          nameEn: 'night',
          visualDescription: 'a dark night sky',
        },
      });
      await prisma.eventTemplate.create({
        data: {
          key: `star_gazing_${petId}`,
          locationKeys: [`yard_${petId}`],
          actionKeys: [`stargazing_${petId}`],
          timeKeys: [`night_${petId}`],
          atmosphereKeys: ['sunny'],
          giftCompatible: true,
          weight: 1,
          active: true,
        },
      });
      const starAsset = await prisma.giftAsset.create({
        data: {
          key: `star_${petId}`,
          nameZh: '一颗星星',
          nameEn: 'Star',
          descriptionZh: '测试',
          descriptionEn: 'test',
          illustrationAssetName: 'gift_star',
          eventCompatibility: [`star_gazing_${petId}`], // NOT garden_rest
          repeatable: true,
          saleStatus: 'ACTIVE',
        },
      });
      await prisma.giftInstance.create({
        data: {
          petId,
          giftAssetId: starAsset.id,
          purchaseTransactionId: `e2e-star-${petId}`,
          status: 'PENDING',
        },
      });

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      // A freshly-enabled pet has no Home Anchor yet, so the very first
      // tick is restricted to the Home Base + homeAnchorEligible seed
      // template (home_doorstep_rest) regardless of this test's new
      // fixtures — establish it (and mark it read, so it stops blocking
      // further generation) before exercising the data-driven-extensibility
      // claim this test actually cares about.
      await forceEligibleNow(petId);
      await generation.runTick();
      const anchorEvents = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      await request(httpServer)
        .post(
          `/api/v1/pets/${petId}/planet-life/events/${anchorEvents.body[0].id}/read`,
        )
        .set(authed(token))
        .expect(201);

      // With the star pending and the anchor already established, the
      // generation pipeline should now bias toward its own new template —
      // proving the whole real stack (API, DB, scheduler tick, fake quality
      // checks, transaction) handles brand-new data with zero code changes.
      await forceEligibleNow(petId);
      await generation.runTick();

      const events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      // 2, not 1: the anchor-establishing event from the step above, plus
      // this one.
      expect(events.body).toHaveLength(2);
      const starEvent = events.body.find(
        (e: { eventTemplateKey: string }) =>
          e.eventTemplateKey === `star_gazing_${petId}`,
      );
      expect(starEvent).toBeTruthy();
      expect(starEvent.giftInstanceId).not.toBeNull();

      const instance = await prisma.giftInstance.findFirstOrThrow({
        where: { giftAssetId: starAsset.id },
      });
      expect(instance.status).toBe('COMPLETED');
    }, 20000);
  });

  // ── Flow H: Home Profile initialization (Canonical Planet World round) ──
  describe('Flow H: Home Profile initialization', () => {
    it('creates exactly one HomeProfile on first enable, and does not re-roll it on a later re-enable', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Home Init Pet');
      await setUpPaidPetWithScene(token, petId);

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      const first = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      expect(first.homeAnchorStatus).toBe('NONE');
      expect(first.visualSnapshot).toBeTruthy();
      expect(first.nameplateText).toBe('Home Init Pet');

      // Pause then re-enable (Case 2: retry/re-enable must not re-roll).
      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/planet-life/settings`)
        .set(authed(token))
        .send({ paused: true })
        .expect(200);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      const second = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      expect(second.id).toBe(first.id);
      expect(second.cottageBlueprintKey).toBe(first.cottageBlueprintKey);
      expect(second.paletteKey).toBe(first.paletteKey);
      expect(second.roofKey).toBe(first.roofKey);
    });

    // Case 3: the frozen snapshot must survive a later edit to the Variant
    // catalog this pet's HomeProfile originally selected from — this is the
    // whole point of freezing a snapshot instead of joining live, so it
    // needs a REAL mutation through the real DB to mean anything (a mock
    // would just prove "we store a copy", not "a later catalog edit can't
    // reach it").
    it("freezes the visual snapshot at init — a later edit to the HomeVariantAsset catalog never changes an already-initialized pet's home", async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Snapshot Freeze Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      const profile = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      const before = profile.visualSnapshot as {
        cottageBlueprint: { imageGenPrompt: string };
      };
      const originalPrompt = before.cottageBlueprint.imageGenPrompt;

      await prisma.homeVariantAsset.update({
        where: { key: profile.cottageBlueprintKey },
        data: { imageGenPrompt: 'a completely different-looking mansion' },
      });

      const reread = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      const after = reread.visualSnapshot as {
        cottageBlueprint: { imageGenPrompt: string };
      };
      expect(after.cottageBlueprint.imageGenPrompt).toBe(originalPrompt);
    });

    // Case 4: bound once, forever — even though P0 only has one PlanetStyle
    // version to bind to, this confirms the binding is a real FK read, not
    // "whichever one happens to be active right now."
    it('binds the Home Profile to the currently-active PlanetStyle version', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Planet Style Bind Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      const profile = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
        include: { planetStyle: true },
      });
      expect(profile.planetStyle.key).toBe('pawlight_planet_v1');
      expect(profile.planetStyle.version).toBe(1);
    });
  });

  // ── Flow I: Home Anchor lifecycle — establish, invalidate on Bad Case,
  // re-establish ─────────────────────────────────────────────────────────
  describe('Flow I: Home Anchor establishes, invalidates on Bad Case, and re-establishes', () => {
    it('establishes V1 on the first eligible Home event, invalidates it on Bad Case without touching HomeProfile itself, then re-establishes V2', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Anchor Lifecycle Pet');
      await setUpPaidPetWithScene(token, petId);
      await request(httpServer)
        .post(`/api/v1/pets/${petId}/planet-life/enable`)
        .set(authed(token))
        .send({ notifyOnNewEvent: true })
        .expect(201);

      // Case 5: no valid anchor yet -> selection is restricted to the one
      // Home Base + homeAnchorEligible seed template, deterministically.
      await forceEligibleNow(petId);
      await generation.runTick();

      let events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      expect(events.body).toHaveLength(1);
      expect(events.body[0].eventTemplateKey).toBe('home_doorstep_rest');
      const firstEventId = events.body[0].id as string;

      // Case 7: establishes V1.
      let profile = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      expect(profile.homeAnchorStatus).toBe('ESTABLISHED');
      expect(profile.homeAnchorVersion).toBe(1);
      expect(profile.homeAnchorEventId).toBe(firstEventId);
      expect(profile.homeAnchorImageR2Url).toBeTruthy();

      const anchorEventRow = await prisma.planetEvent.findUniqueOrThrow({
        where: { id: firstEventId },
      });
      expect(anchorEventRow.establishedHomeAnchorVersion).toBe(1);

      // Case 10: Bad Case on the anchor event itself invalidates the anchor.
      await request(httpServer)
        .post(
          `/api/v1/pets/${petId}/planet-life/events/${firstEventId}/bad-case`,
        )
        .set(authed(token))
        .expect(201);

      // Case 11: HomeProfile itself survives, untouched — same variant
      // selection and snapshot, only the anchor pointer/status changed.
      const cottageBefore = profile.cottageBlueprintKey;
      profile = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      expect(profile.homeAnchorStatus).toBe('INVALIDATED');
      expect(profile.homeAnchorImageR2Url).toBeNull();
      expect(profile.homeAnchorEventId).toBeNull();
      expect(profile.homeAnchorVersion).toBe(1); // not decremented, just not current
      expect(profile.cottageBlueprintKey).toBe(cottageBefore);

      // Case 12: the next eligible Home event establishes V2 — selection is
      // restricted to Home Base + homeAnchorEligible again, same as Case 5,
      // since INVALIDATED is treated the same as NONE for this purpose.
      await forceEligibleNow(petId);
      await generation.runTick();

      events = await request(httpServer)
        .get(`/api/v1/pets/${petId}/planet-life/events`)
        .set(authed(token))
        .expect(200);
      // The Bad Case event is excluded from this list (only UNREAD/READ),
      // so this is the one new event, not two.
      expect(events.body).toHaveLength(1);
      const secondEventId = events.body[0].id as string;
      expect(secondEventId).not.toBe(firstEventId);

      profile = await prisma.homeProfile.findUniqueOrThrow({
        where: { petId },
      });
      expect(profile.homeAnchorStatus).toBe('ESTABLISHED');
      expect(profile.homeAnchorVersion).toBe(2);
      expect(profile.homeAnchorEventId).toBe(secondEventId);
    }, 20000);
  });
});
