/**
 * Live smoke test for the real Ark image/video providers — the ONLY place in
 * this repo that calls a real third-party AI vendor. Never runs in CI (see
 * .github/workflows/ci.yml and docs/reference/testing.md); run manually to
 * validate the current ARK_API_KEY / model IDs against the live API.
 *
 * Usage:
 *   ARK_API_KEY=... SMOKE_REFERENCE_IMAGE_URL=https://example.com/pet.jpg \
 *     npm run smoke:scene:ark
 *
 *   Add RUN_VIDEO_SMOKE=true to additionally exercise the (slower, and
 *   depending on vendor pricing, not free) video path:
 *   ARK_API_KEY=... SMOKE_REFERENCE_IMAGE_URL=... RUN_VIDEO_SMOKE=true \
 *     npm run smoke:scene:ark
 *
 * Notes:
 * - Never prints ARK_API_KEY's value, only whether it is set.
 * - Never writes generated images/video to disk — this script only reports
 *   byte counts, so nothing generated here ends up committed to the repo.
 * - Non-zero exit code on any failure; each vendor call has an explicit
 *   timeout so a hung request can't hang this script forever.
 */
import { ArkImageGenProvider } from '../src/scene-portraits/providers/ark-image-gen.provider';
import { ArkVideoGenProvider } from '../src/scene-portraits/providers/ark-video-gen.provider';
import { buildMotionPrompt } from '../src/scene-portraits/prompts';

const CALL_TIMEOUT_MS = 60_000;
const VIDEO_POLL_INTERVAL_MS = 4_000;
const VIDEO_POLL_TIMEOUT_MS = 5 * 60_000;

function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  label: string,
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(
        () => reject(new Error(`${label} timed out after ${ms}ms`)),
        ms,
      ),
    ),
  ]);
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. See the usage comment at the top of this script.`,
    );
  }
  return value;
}

async function runImageSmoke(referenceImageUrl: string): Promise<void> {
  console.log('[smoke] --- Image generation (ArkImageGenProvider) ---');
  const provider = new ArkImageGenProvider();
  const start = Date.now();

  const images = await withTimeout(
    provider.generateCandidates({
      referenceImageUrl,
      sceneText: 'a smoke test scene',
      count: 1,
    }),
    CALL_TIMEOUT_MS,
    'Image generation',
  );

  const elapsedMs = Date.now() - start;
  if (images.length !== 1) {
    throw new Error(`Expected 1 candidate, got ${images.length}`);
  }
  const [image] = images;
  if (!image.buffer || image.buffer.length === 0) {
    throw new Error('Image generation returned an empty buffer');
  }

  console.log(
    `[smoke] OK — got ${image.buffer.length} bytes (${image.contentType}) in ${elapsedMs}ms`,
  );
}

async function runVideoSmoke(referenceImageUrl: string): Promise<void> {
  console.log('[smoke] --- Video generation (ArkVideoGenProvider) ---');
  const provider = new ArkVideoGenProvider();
  const start = Date.now();

  const { providerTaskId } = await withTimeout(
    provider.submitImageToVideo({
      imageUrl: referenceImageUrl,
      motionPrompt: buildMotionPrompt(),
      durationSeconds: 5,
    }),
    CALL_TIMEOUT_MS,
    'Video task submission',
  );
  console.log(`[smoke] task submitted: ${providerTaskId}`);

  const deadline = Date.now() + VIDEO_POLL_TIMEOUT_MS;
  while (Date.now() < deadline) {
    const result = await withTimeout(
      provider.pollTask(providerTaskId),
      CALL_TIMEOUT_MS,
      'Video poll',
    );
    if (result.status === 'pending') {
      console.log('[smoke] still pending, polling again...');
      await new Promise((resolve) =>
        setTimeout(resolve, VIDEO_POLL_INTERVAL_MS),
      );
      continue;
    }
    if (result.status === 'failed') {
      throw new Error(`Video generation failed: ${result.errorMessage}`);
    }
    const elapsedMs = Date.now() - start;
    if (!result.video.buffer || result.video.buffer.length === 0) {
      throw new Error('Video generation returned an empty buffer');
    }
    console.log(
      `[smoke] OK — got ${result.video.buffer.length} bytes (${result.video.contentType}) in ${elapsedMs}ms`,
    );
    return;
  }
  throw new Error(
    `Video generation did not complete within ${VIDEO_POLL_TIMEOUT_MS}ms`,
  );
}

async function main() {
  requireEnv('ARK_API_KEY');
  console.log('[smoke] ARK_API_KEY is set (value not printed)');
  const referenceImageUrl = requireEnv('SMOKE_REFERENCE_IMAGE_URL');

  await runImageSmoke(referenceImageUrl);

  if (process.env.RUN_VIDEO_SMOKE === 'true') {
    // Uses the same reference image as the "source photo" for the video
    // step, rather than chaining the image step's real output — this
    // validates the video provider's contract/connectivity on its own.
    // Chaining image output -> video input is an orchestration concern
    // already covered by the e2e suite (with fake providers).
    await runVideoSmoke(referenceImageUrl);
  } else {
    console.log(
      '[smoke] Skipping video generation (set RUN_VIDEO_SMOKE=true to include it)',
    );
  }

  console.log('[smoke] All checks passed.');
}

main().catch((err: unknown) => {
  console.error('[smoke] FAILED:', err instanceof Error ? err.message : err);
  process.exit(1);
});
