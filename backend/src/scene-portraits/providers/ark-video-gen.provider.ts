import { Injectable } from '@nestjs/common';
import {
  VideoGenProvider,
  SubmitImageToVideoInput,
  VideoGenTaskResult,
} from './video-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './errors';

const DEFAULT_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3';

// Volcengine Ark (火山方舟) async image-to-video — POST .../contents/generations/tasks,
// then poll GET .../tasks/{id}. Field names reconstructed from third-party
// write-ups, NOT the official docs — verify against live docs once a real
// ARK_API_KEY is available (see docs/11_ai_scene_portrait_api_research.md and
// the plan doc for what's unverified: batch params, exact response shape).
//
// Kling is an equally acceptable vendor for this step (user confirmed either
// is fine) — a future KlingVideoGenProvider implements the same interface and
// is selected via SCENE_PORTRAIT_VIDEO_PROVIDER=kling in scene-portraits.module.ts.
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
    const model = process.env.ARK_VIDEO_MODEL_ID ?? 'doubao-seedance-2-0-260128';
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
      throw new Error(`Ark video task submission failed: ${res.status} ${await res.text()}`);
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

    const res = await fetch(`${baseUrl}/contents/generations/tasks/${providerTaskId}`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (!res.ok) {
      throw new Error(`Ark video task query failed: ${res.status} ${await res.text()}`);
    }
    const json = (await res.json()) as {
      status?: string;
      content?: { video_url?: string };
    };

    if (json.status === 'succeeded') {
      const videoUrl = json.content?.video_url;
      if (!videoUrl) {
        return { status: 'failed', errorMessage: 'Ark reported succeeded with no video_url' };
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
      return { status: 'failed', errorMessage: 'Ark reported the video generation task failed' };
    }
    return { status: 'pending' };
  }
}
