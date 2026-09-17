# Pawlight Backend

NestJS + Prisma API backing the Pawlight iOS app and H5 share page.

## Purpose

Provides authentication (Sign in with Apple), pet/photo/story/letter CRUD,
the public share/hug endpoints consumed by the H5 page, StoreKit 2 purchase
verification, and the AI scene-portrait generation pipeline. See
`docs/reference/architecture.md`, `docs/reference/api-reference.md`,
`docs/reference/data-model.md` for what each part actually does.

## Requirements

- Node.js 18+ (developed against Node 24; the codebase relies on global
  `fetch`, which requires Node 18+)
- A PostgreSQL database
- A Cloudflare R2 bucket (S3-compatible) — the app fails to start without R2
  credentials configured (see below)

## Install

```bash
npm install
```

## Environment variables

Copy `.env.example` to `.env` and fill in real values — never commit `.env`.

Required at boot (`validateRequiredEnv()` in `src/config/env.validation.ts`
throws immediately if any of these are missing):

- `DATABASE_URL`
- `JWT_SECRET`
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`,
  `R2_PUBLIC_URL`
- In production (`NODE_ENV=production`) only: `APPLE_APP_APPLE_ID` (numeric
  App Apple ID), and `APPLE_BUNDLE_ID` must equal `com.pawlight.app`

Optional:

- `DEBUG_SECRET` — enables `POST /api/v1/auth/debug-login` when set; leave
  unset in production
- `ARK_API_KEY`, `ARK_IMAGE_MODEL_ID`, `ARK_VIDEO_MODEL_ID`, `ARK_BASE_URL`,
  `SCENE_PORTRAIT_IMAGE_PROVIDER`, `SCENE_PORTRAIT_VIDEO_PROVIDER` — see
  `docs/reference/ai-provider-integration.md`

## Database / Prisma

```bash
npx prisma generate       # regenerate the client after a schema change
npx prisma migrate deploy # apply committed migrations to DATABASE_URL
npx prisma migrate dev    # create + apply a new migration (local/dev only)
```

Migrations are committed under `prisma/migrations/`. Do not hand-edit an
already-applied migration; add a new one.

## Development

```bash
npm run start:dev   # watch mode
npm run start       # single run, no watch
```

## Build

```bash
npm run build        # nest build -> dist/
npm run start:prod   # node dist/main (after build)
```

## Test

```bash
npm run test          # unit tests (Jest, colocated *.spec.ts under src/)
npm run test:cov      # unit tests with coverage
npm run test:e2e      # e2e tests (test/*.e2e-spec.ts), see below
npm run lint:check    # eslint, no auto-fix — this is what CI runs
npm run lint          # eslint --fix, for local use only (mutates source)
```

E2E tests use fake providers (`SCENE_PORTRAIT_*_PROVIDER=fake`) and mocked
Apple purchase verification — they never call a real third-party API. See
`docs/reference/testing.md` for the full test-layer breakdown, what each
layer does and doesn't cover, and known gaps.

## Provider configuration

Image/video generation vendors are pluggable — see
`docs/reference/ai-provider-integration.md` for the full registry, supported
values, and how to add a new vendor. In short: `SCENE_PORTRAIT_IMAGE_PROVIDER`
and `SCENE_PORTRAIT_VIDEO_PROVIDER` select `fake` or `ark`; any other value
fails application startup rather than silently falling back to a default
vendor.

## Live smoke test

Real AI vendor APIs are never called from CI or from the automated test
suites. To validate the real Ark integration against Volcengine's live API:

```bash
ARK_API_KEY=... SMOKE_REFERENCE_IMAGE_URL=https://example.com/pet.jpg npm run smoke:scene:ark
```

`SMOKE_REFERENCE_IMAGE_URL` must be a URL Volcengine's servers can fetch
(a real pet photo already hosted on R2 works well). Image generation only, by
default. To additionally exercise the video path (slower, and depending on
the vendor's pricing, not free):

```bash
ARK_API_KEY=... SMOKE_REFERENCE_IMAGE_URL=... RUN_VIDEO_SMOKE=true npm run smoke:scene:ark
```

See `backend/scripts/smoke-scene-provider.ts` and
`docs/reference/testing.md` for what the script checks and its exit-code
behavior.
