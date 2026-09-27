import { EvalImageProvider, GeneratedImage, ReferenceImage } from '../types';

const BASE_URL = 'https://api.bfl.ai/v1';
const POLL_INTERVAL_MS = 2000;
const POLL_TIMEOUT_MS = 2 * 60_000;

// Black Forest Labs FLUX.1 Kontext image editing - async submit-then-poll,
// verified against docs.bfl.ai's Kontext image-editing page on 2026-09-27.
// FLUX_ENDPOINT must be a Kontext (image-editing) endpoint, e.g.
// flux-kontext-pro or flux-kontext-max - a plain text-to-image Flux endpoint
// has no input_image field and cannot do identity-preserving edits from a
// reference photo, which is the whole point of this eval.
//
// Known limitation: the direct BFL API's request body only has a single
// `input_image` field (no confirmed multi-reference-image support on this
// endpoint, unlike Seedream/Nano Banana) - only the first reference image is
// sent; extras are logged and dropped. If BFL adds/has a multi-image variant
// by the time this runs for real, revisit this.
export class FluxProvider implements EvalImageProvider {
  readonly key = 'flux';
  readonly modelVersion: string;
  private readonly apiKey: string;

  constructor() {
    this.apiKey = process.env.FLUX_API_KEY ?? '';
    this.modelVersion = process.env.FLUX_ENDPOINT ?? 'flux-kontext-pro';
  }

  async generate(input: {
    referenceImages: ReferenceImage[];
    prompt: string;
  }): Promise<GeneratedImage> {
    if (!this.apiKey) {
      throw new Error('FLUX_API_KEY is not set');
    }
    if (input.referenceImages.length > 1) {
      console.warn(
        `[flux] ${input.referenceImages.length} reference images given, this endpoint only accepts one - using the first and dropping the rest.`,
      );
    }
    const [primary] = input.referenceImages;
    if (!primary) {
      throw new Error('Flux requires at least one reference image');
    }

    const submitRes = await fetch(`${BASE_URL}/${this.modelVersion}`, {
      method: 'POST',
      headers: {
        accept: 'application/json',
        'x-key': this.apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: input.prompt,
        input_image: primary.buffer.toString('base64'),
        aspect_ratio: '1:1',
        output_format: 'png',
      }),
    });
    if (!submitRes.ok) {
      throw new Error(
        `Flux submit failed: ${submitRes.status} ${await submitRes.text()}`,
      );
    }
    const submitJson = (await submitRes.json()) as {
      id?: string;
      polling_url?: string;
    };
    if (!submitJson.polling_url) {
      throw new Error(
        `Flux submit response had no polling_url: ${JSON.stringify(submitJson)}`,
      );
    }

    const deadline = Date.now() + POLL_TIMEOUT_MS;
    while (Date.now() < deadline) {
      const pollRes = await fetch(submitJson.polling_url, {
        headers: { accept: 'application/json', 'x-key': this.apiKey },
      });
      if (!pollRes.ok) {
        throw new Error(
          `Flux poll failed: ${pollRes.status} ${await pollRes.text()}`,
        );
      }
      const pollJson = (await pollRes.json()) as {
        status?: string;
        result?: { sample?: string };
      };
      if (pollJson.status === 'Ready') {
        const sampleUrl = pollJson.result?.sample;
        if (!sampleUrl) {
          throw new Error('Flux reported Ready with no result.sample URL');
        }
        // Signed URLs are only valid ~10 minutes - download immediately.
        return downloadAsBuffer(sampleUrl, 'image/png');
      }
      if (pollJson.status === 'Error' || pollJson.status === 'Failed') {
        throw new Error(`Flux generation failed: status=${pollJson.status}`);
      }
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    }
    throw new Error(`Flux generation did not complete within ${POLL_TIMEOUT_MS}ms`);
  }
}

async function downloadAsBuffer(
  url: string,
  fallbackContentType: string,
): Promise<GeneratedImage> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Failed to download Flux result: ${res.status}`);
  }
  const arrayBuffer = await res.arrayBuffer();
  const contentType = res.headers.get('content-type') ?? fallbackContentType;
  return { buffer: Buffer.from(arrayBuffer), contentType };
}
