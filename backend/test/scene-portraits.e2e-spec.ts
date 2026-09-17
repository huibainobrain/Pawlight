import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import {
  CANDIDATE_COUNT,
  VIDEO_POLL_INTERVAL_MS,
} from '../src/scene-portraits/scene-portraits.constants';

// Full-stack e2e tests against a real (local/test-only) Postgres, with fake
// image/video generation and fake storage (see test/env.setup.ts) — never a
// real Apple, Ark, or R2 call. See docs/reference/testing.md.

// INestApplication.getHttpServer() is typed `any` in @nestjs/common (it's
// platform-agnostic — Express or Fastify underneath). supertest's own `App`
// parameter type isn't exported by name (see @types/supertest/types.d.ts),
// so it's recovered here from `request` itself rather than hand-copied.
type TestHttpServer = Parameters<typeof request>[0];

describe('Pawlight e2e', () => {
  let app: INestApplication;
  let httpServer: TestHttpServer;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();

    httpServer = app.getHttpServer() as TestHttpServer;
    prisma = app.get(PrismaService);
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

  // ── Flow A: basic memorial closed loop ────────────────────────────────────
  describe('Flow A: create -> share -> visitor hug -> owner sees it', () => {
    it('runs the full loop', async () => {
      const { token } = await debugLogin(); // debug-login always grants PAID
      const petId = await createPet(token, 'Mochi');

      await uploadPhoto(token, petId, 'MAIN').expect(201);

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}`)
        .set(authed(token))
        .send({ story: 'We met on a rainy afternoon.' })
        .expect(200);

      const shareRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/share`)
        .set(authed(token))
        .expect(200);
      const slug = shareRes.body.slug as string;
      expect(shareRes.body.visibility).toBe('LINK'); // default, set at pet creation

      const publicRes = await request(httpServer)
        .get(`/api/v1/shares/${slug}`)
        .expect(200);
      expect(publicRes.body).toMatchObject({
        status: 'ok',
        petName: 'Mochi',
        story: 'We met on a rainy afternoon.',
        hugCount: 0,
      });
      // Never leak owner/account fields on the public endpoint.
      expect(publicRes.body).not.toHaveProperty('userId');

      const hugRes = await request(httpServer)
        .post(`/api/v1/shares/${slug}/hugs`)
        .send({ visitorFingerprint: 'visitor-e2e-1' })
        .expect(201);
      expect(hugRes.body.status).toBe('success');

      const hugsListRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/hugs`)
        .set(authed(token))
        .expect(200);
      expect(hugsListRes.body).toHaveLength(1);
      expect(hugsListRes.body[0].visitorFingerprint).toBe('visitor-e2e-1');
    });
  });

  // ── Flow B: permission / gating closed loop ───────────────────────────────
  describe('Flow B: private share, disabled hugs, FREE-tier gating', () => {
    it('rejects public access to a PRIVATE share', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'Privately Yours');

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/share`)
        .set(authed(token))
        .send({ visibility: 'PRIVATE' })
        .expect(200);

      const shareRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/share`)
        .set(authed(token))
        .expect(200);

      await request(httpServer)
        .get(`/api/v1/shares/${shareRes.body.slug}`)
        .expect(403)
        .expect((res) => {
          expect(res.body).toMatchObject({ status: 'private_or_unavailable' });
        });
    });

    it('rejects a hug when hugs are disabled, even on a LINK-visible share', async () => {
      const { token } = await debugLogin();
      const petId = await createPet(token, 'No Hugs Please');

      await request(httpServer)
        .patch(`/api/v1/pets/${petId}/share`)
        .set(authed(token))
        .send({ visibility: 'LINK', hugEnabled: false })
        .expect(200);
      const shareRes = await request(httpServer)
        .get(`/api/v1/pets/${petId}/share`)
        .set(authed(token))
        .expect(200);

      const hugRes = await request(httpServer)
        .post(`/api/v1/shares/${shareRes.body.slug}/hugs`)
        .send({ visitorFingerprint: 'visitor-e2e-2' })
        .expect(201);
      expect(hugRes.body.status).toBe('hug_disabled');
    });

    it('rejects the mailbox for a FREE-tier account', async () => {
      const { token, userId } = await debugLogin();
      const petId = await createPet(token, 'Free Tier Pet');
      // debug-login always grants PAID; downgrade directly via Prisma since
      // there is no API for it (matches the real signup default).
      await prisma.entitlement.update({
        where: { userId },
        data: { tier: 'FREE', photoLimit: 9, mailboxEnabled: false },
      });

      await request(httpServer)
        .get(`/api/v1/pets/${petId}/letters`)
        .set(authed(token))
        .expect(403)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'MAILBOX_NOT_ENABLED' });
        });
    });

    it('allows 9 FREE album photos and rejects the 10th', async () => {
      const { token, userId } = await debugLogin();
      const petId = await createPet(token, 'Quota Test Pet');
      await prisma.entitlement.update({
        where: { userId },
        data: { tier: 'FREE', photoLimit: 9, mailboxEnabled: false },
      });

      for (let i = 0; i < 9; i++) {
        await uploadPhoto(token, petId, 'ALBUM').expect(201);
      }
      await uploadPhoto(token, petId, 'ALBUM')
        .expect(400)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'PHOTO_QUOTA_REACHED' });
        });
    });
  });

  // ── Flow C: AI scene portrait job lifecycle ───────────────────────────────
  describe('Flow C: scene portrait job, candidate select, video, revert', () => {
    it(
      'runs QUEUED -> CANDIDATES_READY -> GENERATING_VIDEO -> DONE -> revert',
      async () => {
        const { token } = await debugLogin(); // PAID by default
        const petId = await createPet(token, 'Scene Portrait Pet');
        await uploadPhoto(token, petId, 'MAIN').expect(201);

        const startRes = await request(httpServer)
          .post(`/api/v1/pets/${petId}/scene-portraits`)
          .set(authed(token))
          .send({ sceneText: 'napping in a sunbeam' })
          .expect(201);
        const jobId = startRes.body.id as string;
        expect(startRes.body.status).toBe('QUEUED');

        const candidatesReady = await pollJobUntil(token, jobId, [
          'CANDIDATES_READY',
          'FAILED',
        ]);
        expect(candidatesReady.status).toBe('CANDIDATES_READY');
        expect(candidatesReady.candidates).toHaveLength(CANDIDATE_COUNT);

        const selectRes = await request(httpServer)
          .post(`/api/v1/scene-portraits/${jobId}/select`)
          .set(authed(token))
          .send({ candidateId: candidatesReady.candidates[0].id })
          .expect(201);
        expect(selectRes.body.status).toBe('GENERATING_VIDEO');

        const done = await pollJobUntil(token, jobId, ['DONE', 'FAILED']);
        expect(done.status).toBe('DONE');
        expect(done.videoR2Url).toBeTruthy();

        const petsRes = await request(httpServer)
          .get('/api/v1/pets/mine')
          .set(authed(token))
          .expect(200);
        expect(petsRes.body[0].observationVideoUrl).toBe(done.videoR2Url);

        await request(httpServer)
          .post(`/api/v1/pets/${petId}/observation-window/revert`)
          .set(authed(token))
          .expect(201);

        const petsAfterRevert = await request(httpServer)
          .get('/api/v1/pets/mine')
          .set(authed(token))
          .expect(200);
        expect(petsAfterRevert.body[0].observationVideoUrl).toBeNull();
      },
      // The fake video provider needs one real VIDEO_POLL_INTERVAL_MS sleep
      // before it reports "succeeded" — pad generously past that.
      VIDEO_POLL_INTERVAL_MS * 3 + 10000,
    );

    it('rejects a FREE-tier user with PAID_ONLY', async () => {
      const { token, userId } = await debugLogin();
      const petId = await createPet(token, 'Free Tier AI Pet');
      await uploadPhoto(token, petId, 'MAIN').expect(201);
      await prisma.entitlement.update({
        where: { userId },
        data: { tier: 'FREE', photoLimit: 9, mailboxEnabled: false },
      });

      await request(httpServer)
        .post(`/api/v1/pets/${petId}/scene-portraits`)
        .set(authed(token))
        .send({ sceneText: 'x' })
        .expect(403)
        .expect((res) => {
          expect(res.body).toMatchObject({ code: 'PAID_ONLY' });
        });
    });
  });

  async function pollJobUntil(
    token: string,
    jobId: string,
    targets: string[],
    maxAttempts = 40,
  ) {
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const res = await request(httpServer)
        .get(`/api/v1/scene-portraits/${jobId}`)
        .set(authed(token))
        .expect(200);
      if (targets.includes(res.body.status as string)) return res.body;
      await new Promise((resolve) => setTimeout(resolve, 300));
    }
    throw new Error(
      `Timed out waiting for job ${jobId} to reach one of ${targets.join(', ')}`,
    );
  }
});
