import { EvalImageProvider, GeneratedImage, ReferenceImage } from '../types';

const DEFAULT_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3';

// Volcengine Ark (火山方舟) Seedream image generation - POST /images/generations.
// Same vendor/endpoint as the shipped app's ArkImageGenProvider (see
// backend/src/scene-portraits/providers/ark-image-gen.provider.ts, validated
// there against the live API). The one difference here: the shipped app
// passes an already-R2-hosted image URL, while this eval tool has only local
// reference photos, so `image` is sent as base64 data URI(s) instead - Ark's
// docs describe this as an accepted alternative to a URL in the same field,
// including an array of data URIs for multi-image fusion (confirmed via
// third-party API guides, not the official doc page itself - re-check if
// this errors on first real run).
export class SeedreamProvider implements EvalImageProvider {
  readonly key = 'seedream';
  readonly modelVersion: string;
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor() {
    this.apiKey = process.env.SEEDREAM_API_KEY ?? '';
    this.modelVersion =
      process.env.SEEDREAM_MODEL_ID ?? 'doubao-seedream-4-0-250828';
    this.baseUrl = process.env.SEEDREAM_BASE_URL ?? DEFAULT_BASE_URL;
  }

  async generate(input: {
    referenceImages: ReferenceImage[];
    prompt: string;
  }): Promise<GeneratedImage> {
    if (!this.apiKey) {
      throw new Error('SEEDREAM_API_KEY is not set');
    }
    const images = input.referenceImages.map(
      (img) => `data:${img.mimeType};base64,${img.buffer.toString('base64')}`,
    );

    const res = await fetch(`${this.baseUrl}/images/generations`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.modelVersion,
        prompt: input.prompt,
        image: images.length === 1 ? images[0] : images,
        size: '1024x1024',
        response_format: 'url',
        watermark: false,
      }),
    });
    if (!res.ok) {
      throw new Error(
        `Seedream generation failed: ${res.status} ${await res.text()}`,
      );
    }
    const json = (await res.json()) as { data?: { url?: string }[] };
    const url = json.data?.[0]?.url;
    if (!url) {
      throw new Error('Seedream generation returned no url');
    }
    return downloadAsBuffer(url, 'image/png');
  }
}

async function downloadAsBuffer(
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
