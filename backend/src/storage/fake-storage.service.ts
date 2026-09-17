import { Injectable } from '@nestjs/common';
import { R2UploadParams, R2UploadResult } from './r2-storage.service';
import { StorageService } from './storage.interface';

// Selected via STORAGE_PROVIDER=fake. Keeps uploaded bytes in memory (keyed
// by the R2 key) so e2e tests can assert on what was "uploaded" via the
// `objects` map, without ever touching Cloudflare R2. The returned URL is a
// `fake-storage://` placeholder, not a fetchable HTTP URL — e2e tests assert
// against `objects` directly rather than fetching the URL. Never used outside
// of tests — see storage.module.ts.
@Injectable()
export class FakeStorageService implements StorageService {
  readonly objects = new Map<string, { buffer: Buffer; contentType: string }>();

  upload({
    key,
    buffer,
    contentType,
  }: R2UploadParams): Promise<R2UploadResult> {
    this.objects.set(key, { buffer, contentType });
    return Promise.resolve({ key, url: `fake-storage://${key}` });
  }

  delete(key: string): Promise<void> {
    this.objects.delete(key);
    return Promise.resolve();
  }
}
