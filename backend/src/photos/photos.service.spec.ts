import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PhotosService } from './photos.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods
// PhotosService actually calls. Naturally typed (no `any`) so
// `.mockResolvedValue(...)` stays permissive; cast to PrismaService only at
// the point each test constructs the service, since the mock is
// intentionally not a full PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    pet: { findUnique: jest.fn() },
    entitlement: { findUnique: jest.fn() },
    photo: {
      count: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
      findMany: jest.fn(),
    },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

// StorageService is a plain interface (see storage.interface.ts), so this
// object satisfies it structurally — no cast needed.
function makeStorage() {
  return {
    upload: jest.fn().mockResolvedValue({
      key: 'pets/pet-1/abc123.jpg',
      url: 'https://r2.example/pets/pet-1/abc123.jpg',
    }),
    delete: jest.fn().mockResolvedValue(undefined),
  };
}

function makeFile(
  overrides: Partial<Express.Multer.File> = {},
): Express.Multer.File {
  return {
    originalname: 'photo.jpg',
    mimetype: 'image/jpeg',
    buffer: Buffer.from('fake-image-bytes'),
    ...overrides,
  } as Express.Multer.File;
}

describe('PhotosService', () => {
  describe('upload quota', () => {
    it('does not check quota for a MAIN photo, even at/over the album limit', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.photo.create.mockResolvedValue({ id: 'photo-1', type: 'MAIN' });
      const storage = makeStorage();
      const service = new PhotosService(asPrismaService(prisma), storage);

      await service.upload('user-1', 'pet-1', makeFile(), 'MAIN');

      expect(prisma.entitlement.findUnique).not.toHaveBeenCalled();
      expect(prisma.photo.count).not.toHaveBeenCalled();
      expect(prisma.photo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ type: 'MAIN' }),
        }),
      );
    });

    it('FREE tier: allows the 9th album photo', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'FREE',
        photoLimit: null,
      });
      prisma.photo.count.mockResolvedValue(8); // 8 existing -> this upload is the 9th
      prisma.photo.create.mockResolvedValue({ id: 'photo-9', type: 'ALBUM' });
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      await expect(
        service.upload('user-1', 'pet-1', makeFile(), 'ALBUM'),
      ).resolves.toMatchObject({
        id: 'photo-9',
      });
    });

    it('FREE tier: rejects the 10th album photo with PHOTO_QUOTA_REACHED', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'FREE',
        photoLimit: null,
      });
      prisma.photo.count.mockResolvedValue(9); // already at the FREE limit of 9
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      const promise = service.upload('user-1', 'pet-1', makeFile(), 'ALBUM');
      await expect(promise).rejects.toBeInstanceOf(BadRequestException);
      await promise.catch((err: BadRequestException) => {
        expect(err.getResponse()).toMatchObject({
          code: 'PHOTO_QUOTA_REACHED',
          albumPhotoLimit: 9,
        });
      });
      expect(prisma.photo.create).not.toHaveBeenCalled();
    });

    it('PAID tier: allows the 50th album photo', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'PAID',
        photoLimit: null,
      });
      prisma.photo.count.mockResolvedValue(49);
      prisma.photo.create.mockResolvedValue({ id: 'photo-50', type: 'ALBUM' });
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      await expect(
        service.upload('user-1', 'pet-1', makeFile(), 'ALBUM'),
      ).resolves.toMatchObject({
        id: 'photo-50',
      });
    });

    it('PAID tier: rejects the 51st album photo with PHOTO_QUOTA_REACHED', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'PAID',
        photoLimit: null,
      });
      prisma.photo.count.mockResolvedValue(50);
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      const promise = service.upload('user-1', 'pet-1', makeFile(), 'ALBUM');
      await expect(promise).rejects.toBeInstanceOf(BadRequestException);
      await promise.catch((err: BadRequestException) => {
        expect(err.getResponse()).toMatchObject({
          code: 'PHOTO_QUOTA_REACHED',
          albumPhotoLimit: 50,
        });
      });
    });
  });

  describe('upload ownership', () => {
    it('rejects uploading to a pet owned by someone else', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'owner-1',
      });
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      await expect(
        service.upload('intruder-1', 'pet-1', makeFile(), 'ALBUM'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects uploading with no file', async () => {
      const prisma = makePrisma();
      const service = new PhotosService(asPrismaService(prisma), makeStorage());
      await expect(
        service.upload(
          'user-1',
          'pet-1',
          undefined as unknown as Express.Multer.File,
          'ALBUM',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('remove', () => {
    it('cannot delete a MAIN photo via the album-delete flow', async () => {
      const prisma = makePrisma();
      prisma.photo.findUnique.mockResolvedValue({
        id: 'photo-1',
        type: 'MAIN',
        r2Key: 'pets/pet-1/main.jpg',
        pet: { userId: 'user-1' },
      });
      const storage = makeStorage();
      const service = new PhotosService(asPrismaService(prisma), storage);

      const promise = service.remove('user-1', 'photo-1');
      await expect(promise).rejects.toBeInstanceOf(BadRequestException);
      await promise.catch((err: BadRequestException) => {
        expect(err.getResponse()).toMatchObject({
          code: 'CANNOT_DELETE_MAIN_PHOTO',
        });
      });
      expect(storage.delete).not.toHaveBeenCalled();
      expect(prisma.photo.delete).not.toHaveBeenCalled();
    });

    it('deletes an ALBUM photo and calls R2 delete with its key', async () => {
      const prisma = makePrisma();
      prisma.photo.findUnique.mockResolvedValue({
        id: 'photo-2',
        type: 'ALBUM',
        r2Key: 'pets/pet-1/album-1.jpg',
        pet: { userId: 'user-1' },
      });
      prisma.photo.delete.mockResolvedValue({ id: 'photo-2' });
      const storage = makeStorage();
      const service = new PhotosService(asPrismaService(prisma), storage);

      const result = await service.remove('user-1', 'photo-2');

      expect(storage.delete).toHaveBeenCalledWith('pets/pet-1/album-1.jpg');
      expect(prisma.photo.delete).toHaveBeenCalledWith({
        where: { id: 'photo-2' },
      });
      expect(result).toEqual({ status: 'success', id: 'photo-2' });
    });

    it('rejects deleting a photo owned by someone else', async () => {
      const prisma = makePrisma();
      prisma.photo.findUnique.mockResolvedValue({
        id: 'photo-2',
        type: 'ALBUM',
        r2Key: 'k',
        pet: { userId: 'owner-1' },
      });
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      await expect(
        service.remove('intruder-1', 'photo-2'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws NotFoundException for a nonexistent photo', async () => {
      const prisma = makePrisma();
      prisma.photo.findUnique.mockResolvedValue(null);
      const service = new PhotosService(asPrismaService(prisma), makeStorage());

      await expect(service.remove('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('deleteAllForUser', () => {
    it('deletes every R2 object for photos across all of the user pets', async () => {
      const prisma = makePrisma();
      prisma.photo.findMany.mockResolvedValue([
        { r2Key: 'a' },
        { r2Key: 'b' },
        { r2Key: 'c' },
      ]);
      const storage = makeStorage();
      const service = new PhotosService(asPrismaService(prisma), storage);

      await service.deleteAllForUser('user-1');

      expect(prisma.photo.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { pet: { userId: 'user-1' } } }),
      );
      expect(storage.delete).toHaveBeenCalledTimes(3);
      expect(storage.delete).toHaveBeenCalledWith('a');
      expect(storage.delete).toHaveBeenCalledWith('b');
      expect(storage.delete).toHaveBeenCalledWith('c');
    });
  });
});
