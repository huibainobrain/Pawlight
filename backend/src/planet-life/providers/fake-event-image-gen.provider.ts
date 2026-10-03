import { Injectable } from '@nestjs/common';
import {
  EventImageGenProvider,
  GenerateEventImageInput,
  GeneratedEventImage,
} from './event-image-gen.provider';

// Same tiny valid PNG trick as FakeImageGenProvider in scene-portraits —
// enough to round-trip through R2 and render in iOS, no real vendor call.
const FAKE_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

@Injectable()
export class FakeEventImageGenProvider implements EventImageGenProvider {
  async generate(
    _input: GenerateEventImageInput,
  ): Promise<GeneratedEventImage> {
    await sleep(100);
    return {
      buffer: Buffer.from(FAKE_PNG_BASE64, 'base64'),
      contentType: 'image/png',
    };
  }
}

function sleep(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}
