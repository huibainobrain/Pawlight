import { Injectable, Logger } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { requireEnv } from '../config/env.validation';

export interface R2UploadParams {
  key: string;
  buffer: Buffer;
  contentType: string;
}

export interface R2UploadResult {
  key: string;
  url: string;
}

// Shared by PhotosService and ScenePortraitsService — both need the same
// "buffer + contentType -> R2 key + public url" round trip. Extracted out of
// PhotosService (which used to build its own S3Client) so both callers share
// one client/credential setup instead of duplicating it.
@Injectable()
export class R2StorageService {
  private readonly logger = new Logger(R2StorageService.name);
  private s3: S3Client;
  private bucket = requireEnv('R2_BUCKET');
  private publicUrl = requireEnv('R2_PUBLIC_URL');

  constructor() {
    this.s3 = new S3Client({
      region: 'auto',
      endpoint: `https://${requireEnv('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: requireEnv('R2_ACCESS_KEY_ID'),
        secretAccessKey: requireEnv('R2_SECRET_ACCESS_KEY'),
      },
    });
  }

  async upload({ key, buffer, contentType }: R2UploadParams): Promise<R2UploadResult> {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      }),
    );
    return { key, url: `${this.publicUrl}/${key}` };
  }

  // Best-effort: a failed object delete must not block removing the DB record
  // (or, for scene portraits, freeing up an attempt/finishing account deletion).
  async delete(key: string): Promise<void> {
    try {
      await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
    } catch (err) {
      this.logger.warn(`Best-effort R2 delete failed for ${key}: ${String(err)}`);
    }
  }
}
