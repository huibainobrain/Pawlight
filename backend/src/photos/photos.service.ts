import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { randomBytes } from 'crypto';
import { PhotoType } from '@prisma/client';
import { albumPhotoLimit } from '../common/entitlement.util';
import { requireEnv } from '../config/env.validation';

@Injectable()
export class PhotosService {
  private readonly logger = new Logger(PhotosService.name);
  private s3: S3Client;
  private bucket = requireEnv('R2_BUCKET');
  private publicUrl = requireEnv('R2_PUBLIC_URL');

  constructor(private prisma: PrismaService) {
    this.s3 = new S3Client({
      region: 'auto',
      endpoint: `https://${requireEnv('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: requireEnv('R2_ACCESS_KEY_ID'),
        secretAccessKey: requireEnv('R2_SECRET_ACCESS_KEY'),
      },
    });
  }

  async upload(
    userId: string,
    petId: string,
    file: Express.Multer.File,
    type: PhotoType = 'ALBUM',
  ) {
    if (!file) throw new BadRequestException('No file uploaded');

    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();

    // Album photos count against the account-level quota. Main photos do not.
    if (type === 'ALBUM') {
      const entitlement = await this.prisma.entitlement.findUnique({
        where: { userId },
      });
      const limit = albumPhotoLimit(entitlement);
      const albumPhotoCount = await this.prisma.photo.count({
        where: { petId, type: 'ALBUM' },
      });
      if (albumPhotoCount >= limit) {
        throw new BadRequestException({
          code: 'PHOTO_QUOTA_REACHED',
          message: `Photo quota reached (${limit})`,
          albumPhotoCount,
          albumPhotoLimit: limit,
        });
      }
    }

    const ext = file.originalname.split('.').pop() ?? 'jpg';
    const key = `pets/${petId}/${randomBytes(8).toString('hex')}.${ext}`;

    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );

    const r2Url = `${this.publicUrl}/${key}`;
    const photo = await this.prisma.photo.create({
      data: { petId, r2Key: key, r2Url, type },
    });

    return photo;
  }

  async findByPet(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new ForbiddenException();

    // Album page / H5 only ever show ALBUM photos.
    const photos = await this.prisma.photo.findMany({
      where: { petId, type: 'ALBUM' },
      orderBy: { sortOrder: 'asc' },
    });

    const entitlement = await this.prisma.entitlement.findUnique({
      where: { userId },
    });

    return {
      photos,
      albumPhotoCount: photos.length,
      albumPhotoLimit: albumPhotoLimit(entitlement),
    };
  }

  async remove(userId: string, photoId: string) {
    const photo = await this.prisma.photo.findUnique({
      where: { id: photoId },
      include: { pet: true },
    });
    if (!photo) throw new NotFoundException();
    if (photo.pet.userId !== userId) throw new ForbiddenException();

    // The album delete endpoint must never delete the main (avatar) photo.
    if (photo.type === 'MAIN') {
      throw new BadRequestException({
        code: 'CANNOT_DELETE_MAIN_PHOTO',
        message: '主照片不能在照片回忆页删除',
      });
    }

    await this.deleteFromR2(photo.r2Key);
    await this.prisma.photo.delete({ where: { id: photoId } });
    return { status: 'success', id: photoId };
  }

  // Used by account deletion: removes every R2 object owned by this user's
  // pet(s). The DB rows are left to the Pet -> User cascade delete — this
  // only has to clean up storage, which Postgres can't do for us.
  async deleteAllForUser(userId: string) {
    const photos = await this.prisma.photo.findMany({
      where: { pet: { userId } },
      select: { r2Key: true },
    });
    await Promise.all(photos.map((photo) => this.deleteFromR2(photo.r2Key)));
  }

  // R2 deletion is best-effort: a failed object delete must not block removing
  // the DB record (and freeing quota).
  private async deleteFromR2(key: string) {
    try {
      await this.s3.send(
        new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
      );
    } catch (err) {
      this.logger.warn(`Best-effort R2 delete failed for ${key}: ${String(err)}`);
    }
  }
}
