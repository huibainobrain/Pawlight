import {
  Inject,
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomBytes } from 'crypto';
import { PhotoType } from '@prisma/client';
import { albumPhotoLimit } from '../common/entitlement.util';
import { STORAGE_SERVICE } from '../storage/storage.interface';
import type { StorageService } from '../storage/storage.interface';

@Injectable()
export class PhotosService {
  constructor(
    private prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private storage: StorageService,
  ) {}

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

    const { url: r2Url } = await this.storage.upload({
      key,
      buffer: file.buffer,
      contentType: file.mimetype,
    });

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

    await this.storage.delete(photo.r2Key);
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
    await Promise.all(photos.map((photo) => this.storage.delete(photo.r2Key)));
  }
}
