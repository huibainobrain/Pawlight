import { Injectable } from '@nestjs/common';
import {
  ImageGenProvider,
  GenerateCandidatesInput,
  GeneratedImage,
} from './image-gen.provider';
import { ScenePortraitProviderNotConfiguredError } from './errors';
import { buildScenePortraitPrompt } from '../prompts';
import { IMAGE_SIZE } from '../scene-portraits.constants';

const DEFAULT_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3';

// Volcengine Ark (火山方舟) image generation — POST /images/generations.
// Field names reconstructed from third-party write-ups, NOT the official docs
// (see docs/11_ai_scene_portrait_api_research.md and the plan doc) — verify
// against live docs once a real ARK_API_KEY is available.
@Injectable()
export class ArkImageGenProvider implements ImageGenProvider {
  async generateCandidates({
    referenceImageUrl,
    sceneText,
    count,
  }: GenerateCandidatesInput): Promise<GeneratedImage[]> {
    const apiKey = process.env.ARK_API_KEY;
    if (!apiKey) {
      throw new ScenePortraitProviderNotConfiguredError('ArkImageGenProvider');
    }
    const model = process.env.ARK_IMAGE_MODEL_ID ?? 'doubao-seedream-4-0-250828';
    const baseUrl = process.env.ARK_BASE_URL ?? DEFAULT_BASE_URL;
    const prompt = buildScenePortraitPrompt(sceneText);

    // No confirmed batch/`n` parameter on this endpoint — issue `count`
    // independent concurrent calls rather than assume one exists.
    return Promise.all(
      Array.from({ length: count }, () =>
        this.generateOne({ apiKey, baseUrl, model, prompt, referenceImageUrl }),
      ),
    );
  }

  private async generateOne(args: {
    apiKey: string;
    baseUrl: string;
    model: string;
    prompt: string;
    referenceImageUrl: string;
  }): Promise<GeneratedImage> {
    const res = await fetch(`${args.baseUrl}/images/generations`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${args.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: args.model,
        prompt: args.prompt,
        image: args.referenceImageUrl,
        size: IMAGE_SIZE,
        response_format: 'url',
        watermark: false,
      }),
    });
    if (!res.ok) {
      throw new Error(`Ark image generation failed: ${res.status} ${await res.text()}`);
    }
    const json = (await res.json()) as { data?: { url?: string }[] };
    const url = json.data?.[0]?.url;
    if (!url) {
      throw new Error('Ark image generation returned no url');
    }
    return this.downloadAsBuffer(url, 'image/png');
  }

  private async downloadAsBuffer(
    url: string,
    fallbackContentType: string,
  ): Promise<GeneratedImage> {
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Failed to download generated image: ${res.status}`);
    }
    const arrayBuffer = await res.arrayBuffer();
    const contentType = res.headers.get('content-type') ?? fallbackContentType;
    return { buffer: Buffer.from(arrayBuffer), contentType };
  }
}
