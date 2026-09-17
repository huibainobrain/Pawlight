import { Injectable } from '@nestjs/common';
import {
  VideoGenProvider,
  SubmitImageToVideoInput,
  VideoGenTaskResult,
} from './video-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './errors';

const DEFAULT_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3';

// Volcengine Ark (火山方舟) async image-to-video — POST .../contents/generations/tasks,
// then poll GET .../tasks/{id}.
//
// Status: implemented. This adapter's request/response contract has been
// validated against the live Ark API in Pawlight's production generation
// flow (see `RUN_VIDEO_SMOKE=true npm run smoke:scene:ark`,
// backend/scripts/smoke-scene-provider.ts). It must be revalidated the same
// way when migrating to a materially different Ark API/model version, since
// Volcengine's API can change independently of this codebase. Field names
// were originally drafted from
// docs/archive/research/2026-09-ai-scene-portrait-api-research.md, a
// research snapshot — see docs/reference/ai-provider-integration.md for the
// current, validated contract.
//
// Kling is an equally acceptable vendor for this step — a future
// KlingVideoGenProvider implements the same interface and is registered as
// `kling` in scene-portraits.module.ts's VIDEO_PROVIDERS map once it exists.
// It must pass its own contract tests and live smoke test before use; it is
// not implemented yet, and there is no shortcut that lets an unrecognized
// provider name fall back to this one (see scene-portraits.module.ts).
@Injectable()
export class ArkVideoGenProvider implements VideoGenProvider {
  async submitImageToVideo({
    imageUrl,
    motionPrompt,
    durationSeconds,
  }: SubmitImageToVideoInput): Promise<{ providerTaskId: string }> {
    const apiKey = process.env.ARK_API_KEY;
    if (!apiKey) {
      throw new ScenePortraitProviderNotConfiguredError('ArkVideoGenProvider');
    }
    const model =
      process.env.ARK_VIDEO_MODEL_ID ?? 'doubao-seedance-2-0-260128';
    const baseUrl = process.env.ARK_BASE_URL ?? DEFAULT_BASE_URL;

    const res = await fetch(`${baseUrl}/contents/generations/tasks`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        content: [
          { type: 'image_url', image_url: { url: imageUrl } },
          { type: 'text', text: motionPrompt },
        ],
        parameters: { duration: durationSeconds, resolution: '720p', fps: 24 },
      }),
    });
    if (!res.ok) {
      throw new Error(
        `Ark video task submission failed: ${res.status} ${await res.text()}`,
      );
    }
    const json = (await res.json()) as { id?: string };
    if (!json.id) {
      throw new Error('Ark video task submission returned no id');
    }
    return { providerTaskId: json.id };
  }

  async pollTask(providerTaskId: string): Promise<VideoGenTaskResult> {
    const apiKey = process.env.ARK_API_KEY;
    if (!apiKey) {
      throw new ScenePortraitProviderNotConfiguredError('ArkVideoGenProvider');
    }
    const baseUrl = process.env.ARK_BASE_URL ?? DEFAULT_BASE_URL;

    const res = await fetch(
      `${baseUrl}/contents/generations/tasks/${providerTaskId}`,
      {
        headers: { Authorization: `Bearer ${apiKey}` },
      },
    );
    if (!res.ok) {
      throw new Error(
        `Ark video task query failed: ${res.status} ${await res.text()}`,
      );
    }
    const json = (await res.json()) as {
      status?: string;
      content?: { video_url?: string };
    };

    if (json.status === 'succeeded') {
      const videoUrl = json.content?.video_url;
      if (!videoUrl) {
        return {
          status: 'failed',
          errorMessage: 'Ark reported succeeded with no video_url',
        };
      }
      // Vendor video URLs expire (~24h) — download immediately, the caller
      // re-uploads to R2 right away.
      const videoRes = await fetch(videoUrl);
      if (!videoRes.ok) {
        return {
          status: 'failed',
          errorMessage: `Failed to download generated video: ${videoRes.status}`,
        };
      }
      const arrayBuffer = await videoRes.arrayBuffer();
      const contentType = videoRes.headers.get('content-type') ?? 'video/mp4';
      return {
        status: 'succeeded',
        video: { buffer: Buffer.from(arrayBuffer), contentType },
      };
    }
    if (json.status === 'failed') {
      return {
        status: 'failed',
        errorMessage: 'Ark reported the video generation task failed',
      };
    }
    return { status: 'pending' };
  }
}
