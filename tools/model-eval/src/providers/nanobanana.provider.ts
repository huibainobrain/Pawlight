import { EvalImageProvider, GeneratedImage, ReferenceImage } from '../types';

const BASE_URL = 'https://generativelanguage.googleapis.com/v1';

// Google Gemini image generation/editing ("Nano Banana"), via the
// `generateContent` REST endpoint. Verified against ai.google.dev's docs on
// 2026-09-27 (this space iterates fast - re-check docs.ai.google.dev if this
// starts failing, and confirm NANOBANANA_MODEL_ID is still current; a newer
// "Interactions API" (POST .../v1beta/interactions) also exists and may
// become the preferred surface - not used here because generateContent is
// the more broadly-documented, longer-established shape).
//
// Request/response field casing (inline_data/mime_type vs inlineData/
// mimeType) was inconsistent across Google's own docs pages at research
// time; this sends the snake_case form shown on the live docs page and
// parses the response defensively under either casing.
export class NanoBananaProvider implements EvalImageProvider {
  readonly key = 'nanobanana';
  readonly modelVersion: string;
  private readonly apiKey: string;

  constructor() {
    this.apiKey = process.env.NANOBANANA_API_KEY ?? '';
    this.modelVersion =
      process.env.NANOBANANA_MODEL_ID ?? 'gemini-2.5-flash-image';
  }

  async generate(input: {
    referenceImages: ReferenceImage[];
    prompt: string;
  }): Promise<GeneratedImage> {
    if (!this.apiKey) {
      throw new Error('NANOBANANA_API_KEY is not set');
    }
    const imageParts = input.referenceImages.map((img) => ({
      inline_data: {
        mime_type: img.mimeType,
        data: img.buffer.toString('base64'),
      },
    }));

    const res = await fetch(
      `${BASE_URL}/models/${this.modelVersion}:generateContent`,
      {
        method: 'POST',
        headers: {
          'x-goog-api-key': this.apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: input.prompt }, ...imageParts],
            },
          ],
          generationConfig: {
            responseModalities: ['TEXT', 'IMAGE'],
          },
        }),
      },
    );
    if (!res.ok) {
      throw new Error(
        `Nano Banana generation failed: ${res.status} ${await res.text()}`,
      );
    }
    const json = (await res.json()) as {
      candidates?: {
        content?: {
          parts?: {
            inline_data?: { mime_type?: string; data?: string };
            inlineData?: { mimeType?: string; data?: string };
          }[];
        };
      }[];
    };
    const parts = json.candidates?.[0]?.content?.parts ?? [];
    for (const part of parts) {
      const inline = part.inline_data ?? part.inlineData;
      const data = inline && 'data' in inline ? inline.data : undefined;
      if (data) {
        const mimeType =
          (part.inline_data?.mime_type ?? part.inlineData?.mimeType) ??
          'image/png';
        return { buffer: Buffer.from(data, 'base64'), contentType: mimeType };
      }
    }
    throw new Error(
      `Nano Banana response had no image part: ${JSON.stringify(json).slice(0, 500)}`,
    );
  }
}
