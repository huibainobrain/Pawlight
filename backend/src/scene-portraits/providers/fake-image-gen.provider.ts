import { Injectable } from '@nestjs/common';
import { ImageGenProvider, GenerateCandidatesInput, GeneratedImage } from './image-gen.provider';

// A valid, tiny (68-byte) 1x1 PNG — enough to round-trip through R2 and render
// in an iOS AsyncImage, without calling any real vendor. Selected via
// SCENE_PORTRAIT_IMAGE_PROVIDER=fake — see the verification plan in the
// approved plan doc for how this is used to test the whole pipeline for free.
const FAKE_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

@Injectable()
export class FakeImageGenProvider implements ImageGenProvider {
  async generateCandidates({ count }: GenerateCandidatesInput): Promise<GeneratedImage[]> {
    await sleep(500);
    const buffer = Buffer.from(FAKE_PNG_BASE64, 'base64');
    return Array.from({ length: count }, () => ({ buffer, contentType: 'image/png' }));
  }
}

function sleep(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}
