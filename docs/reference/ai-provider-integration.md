# AI Provider Integration

Technical reference for the scene-portrait image/video generation
integration (`backend/src/scene-portraits/`). Not a product description of
what the feature is for — see `docs/reference/state-machines.md` for the job
lifecycle and `docs/reference/api-reference.md` for the HTTP surface.

## Interfaces

```ts
// providers/image-gen.provider.ts
interface ImageGenProvider {
  generateCandidates(input: {
    referenceImageUrl: string;
    sceneText: string;
    count: number;
  }): Promise<{ buffer: Buffer; contentType: string }[]>;
}

// providers/video-gen.provider.ts
interface VideoGenProvider {
  submitImageToVideo(input: {
    imageUrl: string;
    motionPrompt: string;
    durationSeconds: number;
  }): Promise<{ providerTaskId: string }>;

  pollTask(providerTaskId: string): Promise<
    | { status: 'pending' }
    | { status: 'succeeded'; video: { buffer: Buffer; contentType: string } }
    | { status: 'failed'; errorMessage: string }
  >;
}
```

Both are plain TypeScript interfaces resolved through NestJS DI tokens
(`IMAGE_GEN_PROVIDER`, `VIDEO_GEN_PROVIDER`) rather than concrete classes, so
`ScenePortraitsService` never imports a vendor-specific class directly.

## Provider registry (`scene-portraits.module.ts`)

```ts
const IMAGE_PROVIDERS: Record<string, new () => ImageGenProvider> = {
  fake: FakeImageGenProvider,
  ark: ArkImageGenProvider,
};

const VIDEO_PROVIDERS: Record<string, new () => VideoGenProvider> = {
  fake: FakeVideoGenProvider,
  ark: ArkVideoGenProvider,
};
```

`imageProviderClass()` / `videoProviderClass()` look up
`process.env.SCENE_PORTRAIT_IMAGE_PROVIDER` /
`process.env.SCENE_PORTRAIT_VIDEO_PROVIDER` (default `'ark'` if unset) in
these maps and **throw at application bootstrap** if the value isn't a key in
the map. There is no fallback branch — an unrecognized or not-yet-implemented
provider name (`kling`, a typo, etc.) fails startup with a clear error
instead of silently resolving to `ark`.

To add a new vendor: implement the interface, add one entry to the relevant
map, done — no other file changes. See "Adding a provider" below for the
verification steps expected before flipping the environment variable in a
real environment.

## Implementations

| Provider | File | Status |
| --- | --- | --- |
| `FakeImageGenProvider` | `providers/fake-image-gen.provider.ts` | Implemented. Used for local development and deterministic automated testing (unit tests, e2e). Returns a hardcoded tiny PNG after a fixed 500ms delay; makes no network calls. |
| `FakeVideoGenProvider` | `providers/fake-video-gen.provider.ts` | Implemented. Same purpose. `pollTask` reports `pending` for the first poll and `succeeded` (reading a bundled fixture mp4 from `providers/fixtures/fake-observation-loop.mp4`) from the second poll onward — this exercises the polling loop instead of resolving instantly. |
| `ArkImageGenProvider` | `providers/ark-image-gen.provider.ts` | Implemented and validated against the live Volcengine Ark API with a real `ARK_API_KEY`. Calls `POST {ARK_BASE_URL}/images/generations`. |
| `ArkVideoGenProvider` | `providers/ark-video-gen.provider.ts` | Implemented and validated against the live Volcengine Ark API with a real `ARK_API_KEY`. Submits via `POST {ARK_BASE_URL}/contents/generations/tasks`, polls `GET {ARK_BASE_URL}/contents/generations/tasks/{id}`. |
| Kling (可灵) video provider | — | **Not implemented.** No `KlingVideoGenProvider` class exists. The interface and registry support adding one; nothing currently registers `kling` as a valid `SCENE_PORTRAIT_VIDEO_PROVIDER` value. |

The Ark implementations use Node's global `fetch` (no HTTP client
dependency). The current Ark adapter contract has been validated against the
live API in Pawlight's production generation flow — see the "Status" comment
at the top of `ark-image-gen.provider.ts` / `ark-video-gen.provider.ts` and
`npm run smoke:scene:ark` in `docs/reference/testing.md`.

Provider-specific contracts are isolated behind `ImageGenProvider` /
`VideoGenProvider` and must be revalidated (via the live smoke test) when
introducing a new provider or migrating to a materially different Ark
API/model version, since Volcengine's API can change independently of this
codebase.

## Environment variables

Defined in `backend/.env.example`:

| Variable | Purpose | Required to boot? |
| --- | --- | --- |
| `ARK_API_KEY` | Volcengine Ark bearer token, shared by both Ark providers | No — the app boots with it blank; a real call without it throws `ScenePortraitProviderNotConfiguredError`, which `ScenePortraitsService` catches and marks the job `FAILED` with `errorCode: PROVIDER_NOT_CONFIGURED` |
| `ARK_IMAGE_MODEL_ID` | Model id for image generation | No — defaults to `doubao-seedream-4-0-250828` in code |
| `ARK_VIDEO_MODEL_ID` | Model id for image-to-video | No — defaults to `doubao-seedance-2-0-260128` in code |
| `ARK_BASE_URL` | Ark API base URL | No — defaults to `https://ark.cn-beijing.volces.com/api/v3` in code |
| `SCENE_PORTRAIT_IMAGE_PROVIDER` | Registry key, see above | No — defaults to `ark` |
| `SCENE_PORTRAIT_VIDEO_PROVIDER` | Registry key, see above | No — defaults to `ark` |

None of these are asserted in `config/env.validation.ts`'s boot-time
`validateRequiredEnv()` — unlike R2/JWT/DATABASE_URL, a blank Ark
configuration is a valid (if non-functional) state, not a startup error.

## Job lifecycle (orchestration, not HTTP handling)

`ScenePortraitsService` runs generation as in-process, fire-and-forget async
functions (`runImageGeneration`, `runVideoGeneration`) kicked off right after
the initiating HTTP handler returns — there is no queue or worker process.
See `docs/reference/state-machines.md` for the exact status transitions and
the known "stuck job on process restart" limitation this implies.

## HTTP handling in the Ark providers

- Requests: plain `fetch(url, { method, headers, body: JSON.stringify(...) })`.
- Non-2xx responses throw `Error` with the status and response body text
  included, which `ScenePortraitsService.markFailed` catches and records as
  `errorCode: 'GENERATION_FAILED'`.
- No retry/backoff logic exists in either Ark provider — a single failed
  HTTP call fails the whole job attempt.
- No request timeout is set explicitly beyond whatever Node's `fetch`
  defaults to.

## Asset download and R2 persistence

Vendor-hosted URLs (candidate images, the finished video) are not stored
long-term — the provider downloads them into a `Buffer` immediately
(`downloadAsBuffer` in the image provider; inline in the video provider's
`pollTask` on `succeeded`) and `ScenePortraitsService` re-uploads that buffer
to Cloudflare R2 via `R2StorageService` before persisting any URL to the
database. This matters specifically for video: Ark's returned `video_url` is
documented (in the research snapshot) as expiring around 24 hours, so the
service downloads it synchronously as part of handling `succeeded`, before
returning from `pollTask`.

R2 key layout: `scene-portraits/{jobId}/candidate-{index}-{8-hex-random}.{ext}`
and `scene-portraits/{jobId}/video-{8-hex-random}.{ext}`.

## Adding a provider

The technical acceptance sequence for a new provider (e.g. `KlingVideoGenProvider`)
before it is used in production:

1. Implement the adapter against `ImageGenProvider` or `VideoGenProvider`.
2. Add contract tests for it (fully mocked HTTP — see
   `docs/reference/testing.md`), covering at minimum: correct endpoint/auth
   headers, request shape, success parsing, error responses, and asset
   download success/failure.
3. Run it through the existing fake-provider e2e regression suite by
   temporarily registering it and pointing the relevant
   `SCENE_PORTRAIT_*_PROVIDER` env var at it in a local/staging environment —
   this checks it plugs into `ScenePortraitsService`'s state machine
   correctly, not just that its HTTP calls parse.
4. Run a live smoke test against the real vendor API
   (`backend/scripts/smoke-scene-provider.ts`, see `docs/reference/testing.md`).
5. Only then add its registry entry in `scene-portraits.module.ts` and set
   the corresponding environment variable in production.

The architecture supports this extension; it does not mean an unimplemented
provider is usable — see the registry section above for why an unrecognized
name fails fast instead of falling back to Ark.
