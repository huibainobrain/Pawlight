import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { ScenePortraitsController } from './scene-portraits.controller';
import { ScenePortraitsService } from './scene-portraits.service';
import { IMAGE_GEN_PROVIDER } from './providers/image-gen.provider';
import type { ImageGenProvider as ImageGenProviderImpl } from './providers/image-gen.provider';
import { VIDEO_GEN_PROVIDER } from './providers/video-gen.provider';
import type { VideoGenProvider as VideoGenProviderImpl } from './providers/video-gen.provider';
import { ArkImageGenProvider } from './providers/ark-image-gen.provider';
import { ArkVideoGenProvider } from './providers/ark-video-gen.provider';
import { FakeImageGenProvider } from './providers/fake-image-gen.provider';
import { FakeVideoGenProvider } from './providers/fake-video-gen.provider';

// Vendor selection lives entirely here, behind SCENE_PORTRAIT_IMAGE_PROVIDER /
// SCENE_PORTRAIT_VIDEO_PROVIDER — swapping vendors (e.g. adding Kling) never
// touches the controller/service.
//
// Registries are explicit and exhaustive on purpose: an unrecognized provider
// name must fail app startup, not silently resolve to Ark. Add a new entry
// here only once that provider class actually exists.
const IMAGE_PROVIDERS: Record<string, new () => ImageGenProviderImpl> = {
  fake: FakeImageGenProvider,
  ark: ArkImageGenProvider,
};

const VIDEO_PROVIDERS: Record<string, new () => VideoGenProviderImpl> = {
  fake: FakeVideoGenProvider,
  ark: ArkVideoGenProvider,
  // 'kling' is intentionally absent: KlingVideoGenProvider does not exist yet.
  // Implement it, then add `kling: KlingVideoGenProvider` here.
};

function imageProviderClass() {
  const name = process.env.SCENE_PORTRAIT_IMAGE_PROVIDER ?? 'ark';
  const cls = IMAGE_PROVIDERS[name];
  if (!cls) {
    throw new Error(
      `Unknown SCENE_PORTRAIT_IMAGE_PROVIDER "${name}". Valid values: ${Object.keys(IMAGE_PROVIDERS).join(', ')}`,
    );
  }
  return cls;
}

function videoProviderClass() {
  const name = process.env.SCENE_PORTRAIT_VIDEO_PROVIDER ?? 'ark';
  const cls = VIDEO_PROVIDERS[name];
  if (!cls) {
    throw new Error(
      `Unknown SCENE_PORTRAIT_VIDEO_PROVIDER "${name}". Valid values: ${Object.keys(VIDEO_PROVIDERS).join(', ')}`,
    );
  }
  return cls;
}

@Module({
  imports: [StorageModule],
  controllers: [ScenePortraitsController],
  providers: [
    ScenePortraitsService,
    { provide: IMAGE_GEN_PROVIDER, useClass: imageProviderClass() },
    { provide: VIDEO_GEN_PROVIDER, useClass: videoProviderClass() },
  ],
  exports: [ScenePortraitsService],
})
export class ScenePortraitsModule {}
