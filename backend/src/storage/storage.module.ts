import { Module } from '@nestjs/common';
import { R2StorageService } from './r2-storage.service';
import { FakeStorageService } from './fake-storage.service';
import { STORAGE_SERVICE } from './storage.interface';

// STORAGE_PROVIDER=fake selects an in-memory storage double for e2e tests
// (never used outside tests); anything else (including unset) uses real
// Cloudflare R2. Mirrors the SCENE_PORTRAIT_IMAGE_PROVIDER /
// SCENE_PORTRAIT_VIDEO_PROVIDER registry pattern in
// scene-portraits.module.ts, at a smaller scale (one real implementation, no
// third-party vendor choice to make here).
@Module({
  providers: [
    {
      provide: STORAGE_SERVICE,
      useClass:
        process.env.STORAGE_PROVIDER === 'fake'
          ? FakeStorageService
          : R2StorageService,
    },
  ],
  exports: [STORAGE_SERVICE],
})
export class StorageModule {}
