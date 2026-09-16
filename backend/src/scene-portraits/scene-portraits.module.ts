import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { ScenePortraitsController } from './scene-portraits.controller';
import { ScenePortraitsService } from './scene-portraits.service';
import { IMAGE_GEN_PROVIDER } from './providers/image-gen.provider';
import { VIDEO_GEN_PROVIDER } from './providers/video-gen.provider';
import { ArkImageGenProvider } from './providers/ark-image-gen.provider';
import { ArkVideoGenProvider } from './providers/ark-video-gen.provider';
import { FakeImageGenProvider } from './providers/fake-image-gen.provider';
import { FakeVideoGenProvider } from './providers/fake-video-gen.provider';

// Vendor selection lives entirely here, behind SCENE_PORTRAIT_IMAGE_PROVIDER /
// SCENE_PORTRAIT_VIDEO_PROVIDER — swapping vendors (e.g. adding Kling) never
// touches the controller/service.
function imageProviderClass() {
  return process.env.SCENE_PORTRAIT_IMAGE_PROVIDER === 'fake'
    ? FakeImageGenProvider
    : ArkImageGenProvider;
}

function videoProviderClass() {
  if (process.env.SCENE_PORTRAIT_VIDEO_PROVIDER === 'fake') return FakeVideoGenProvider;
  // 'kling' is not implemented yet — falls back to Ark until a
  // KlingVideoGenProvider exists and is added here.
  return ArkVideoGenProvider;
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
