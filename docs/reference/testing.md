# Testing

Technical reference for the backend test suite. H5 and iOS testing are not
covered here — neither currently has an automated test suite beyond the
manual/CI build checks described in `AGENTS.md` and the CI workflow.

## Test layers

1. **Unit tests** — `backend/src/**/*.spec.ts`, run with `npm test`. Each
   service is instantiated directly (`new SomeService(mockPrisma, ...)`)
   against hand-built mock objects, not through Nest's DI container — no
   database, no HTTP layer, no network. `ScenePortraitsService`'s private
   `runImageGeneration`/`runVideoGeneration` methods are called directly
   (bypassing the fire-and-forget wrapper in `startJob`/`selectCandidate`) so
   their outcomes can be awaited deterministically; `startJob`/`selectCandidate`
   themselves are tested by spying on those two methods to confirm they're
   triggered with the right arguments, without re-running their internals.
   The video-poll **timeout exhaustion** path (`MAX_VIDEO_POLL_ATTEMPTS`
   reached without the provider ever reporting `succeeded`/`failed`) is
   covered the same way, using `jest.useFakeTimers()` and one
   `jest.advanceTimersByTimeAsync(VIDEO_POLL_INTERVAL_MS * MAX_VIDEO_POLL_ATTEMPTS)`
   call to drive all 45 poll/sleep cycles without a real ~3-minute wait; the
   test restores real timers in a `finally` block so a failed assertion can't
   leak fake timers into later tests.
2. **Provider contract tests** — `backend/src/scene-portraits/providers/*.provider.spec.ts`,
   run with `npm test` (same command, same layer as unit tests). Fully mock
   global `fetch`; never make a real HTTP call. Exist specifically to catch a
   Volcengine Ark field-name or response-shape change early.
3. **E2E tests** — `backend/test/*.e2e-spec.ts`, run with `npm run test:e2e`.
   Boot the real `AppModule` via `supertest`, against a real (local/CI-only)
   Postgres, with `SCENE_PORTRAIT_IMAGE_PROVIDER=fake`,
   `SCENE_PORTRAIT_VIDEO_PROVIDER=fake`, and `STORAGE_PROVIDER=fake` (see
   below). Apple purchase verification is not exercised by the current e2e
   suite at all (no e2e test calls `/api/v1/purchases/verify`) — that
   endpoint's logic is covered at the unit level only (`purchases.service.spec.ts`,
   which mocks `SignedDataVerifier.prototype.verifyAndDecodeTransaction`).
4. **Live smoke test** — `backend/scripts/smoke-scene-provider.ts`, run
   manually with `npm run smoke:scene:ark`. The only layer that calls a real
   third-party AI vendor (Volcengine Ark). Never runs in CI.

## How to run

```bash
npm test                 # unit + provider contract tests
npm run test:cov         # same, with coverage
DATABASE_URL_TEST=postgresql://user@localhost:5432/pawlight_e2e_test npm run test:e2e
ARK_API_KEY=... SMOKE_REFERENCE_IMAGE_URL=... npm run smoke:scene:ark
```

E2E tests need a real reachable Postgres. `test/env.setup.ts` (a Jest
`setupFiles` entry, runs before `AppModule` is ever imported) sets
`DATABASE_URL` from `DATABASE_URL_TEST` if provided, else defaults to
`postgresql://postgres@localhost:5432/pawlight_e2e_test` — apply migrations
to that database once with `DATABASE_URL=<same value> npx prisma migrate deploy`
before running `test:e2e` the first time. `test/env.setup.ts` also refuses to
run (throws before anything connects) if the resolved `DATABASE_URL` contains
`rlwy.net` or `railway.app`, as a hard backstop against ever pointing e2e
tests at the real deployed database.

## Fake provider behavior

- `FakeImageGenProvider` — returns a hardcoded 1x1 PNG after a fixed 500ms
  delay, for every requested candidate. No network calls.
- `FakeVideoGenProvider` — `pollTask` reports `pending` on the first poll and
  `succeeded` (reading `providers/fixtures/fake-observation-loop.mp4`) from
  the second poll onward. Combined with the real
  `VIDEO_POLL_INTERVAL_MS` (4 seconds) that `ScenePortraitsService` sleeps
  between polls, this means any e2e test that runs the video path takes at
  least ~4 seconds — the e2e spec for this gives that test a longer explicit
  Jest timeout rather than relying on the default 5s.
- `FakeStorageService` (`backend/src/storage/fake-storage.service.ts`) — an
  in-memory `Map` standing in for Cloudflare R2, selected via
  `STORAGE_PROVIDER=fake`. Returns a `fake-storage://<key>` placeholder URL
  (not a fetchable HTTP URL) — tests that need to inspect "uploaded" bytes do
  so via the service's own `objects` map, not by fetching the returned URL.

All three are real, exported classes — not test-only inline mocks — so the
same fakes back both the unit tests (where they're constructed directly) and
the e2e tests (where they're selected via environment variable through the
same provider-registry mechanism used for real vendors, see
`docs/reference/ai-provider-integration.md`).

## Why live AI APIs (and Apple, and R2) are excluded from CI

- Cost: every real Ark call is billed per Volcengine's pricing.
- Determinism: CI must not fail because a third-party vendor is slow, rate
  limiting, or briefly down.
- Credentials: CI does not have (and should not be given) a real
  `ARK_API_KEY`, real Apple root-of-trust production credentials, or real R2
  credentials.

The fake providers plus `FakeStorageService` plus mocked
`SignedDataVerifier.verifyAndDecodeTransaction` (unit tests only) let the
rest of the system's logic — job orchestration, entitlement gating,
ownership checks, cascading cleanup — be tested deterministically without any
of that.

## CI checks

See `.github/workflows/ci.yml`. The backend job runs, in order: `npm ci`,
`npx prisma generate`, `npm run lint:check` (no `--fix` — CI must never
modify the working tree), `npm test`, `npm run test:e2e` (against a Postgres
service container), `npm run build`. It never runs `smoke:scene:ark`.

## How to validate a newly implemented provider

See `docs/reference/ai-provider-integration.md`'s "Adding a provider"
section for the full sequence (contract tests → fake-provider e2e regression
→ live smoke test → production configuration). The short version: get it
passing unit + contract tests and the existing e2e suite with it temporarily
registered, then run it through the live smoke test with real credentials
before ever setting `SCENE_PORTRAIT_VIDEO_PROVIDER` (or `_IMAGE_PROVIDER`) to
its registry key in a real environment.

## Known test gaps

- No e2e test exercises `/api/v1/purchases/verify` end-to-end (covered at the
  unit level only, see above).
- No e2e test exercises account deletion (`DELETE /api/v1/auth/me`) — covered
  at the unit level (`auth.service.spec.ts`) with a mocked
  `PhotosService`/`ScenePortraitsService`, but not against a real Prisma
  cascade delete.
- No automated test asserts on the *content* of AI-generated output (fake
  providers return placeholder bytes) — this is inherent to not calling a
  real vendor in automated tests, not a gap specific to this suite.
- No H5 or iOS automated test suite exists at all yet — both are currently
  verified by manual use plus (for iOS) an Xcode build succeeding and (for
  H5) a Next.js build succeeding, both enforced in CI.
- Ark request/response field names are validated by the live smoke test and,
  per the user, by a manual run against the real API outside this repo — not
  by an automated CI check, since CI never holds a real `ARK_API_KEY`. A
  silent Ark-side field rename would only surface via the smoke test or a
  real failed generation in production, not CI.
