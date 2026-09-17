import { R2UploadParams, R2UploadResult } from './r2-storage.service';

export const STORAGE_SERVICE = 'STORAGE_SERVICE';

// Implemented by R2StorageService (real Cloudflare R2) and FakeStorageService
// (in-memory, for e2e tests — see storage.module.ts for the STORAGE_PROVIDER
// env var that selects between them, mirroring the image/video generation
// provider registry in scene-portraits.module.ts).
export interface StorageService {
  upload(params: R2UploadParams): Promise<R2UploadResult>;
  delete(key: string): Promise<void>;
}
