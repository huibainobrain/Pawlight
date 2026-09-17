import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { SharesService } from './shares.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods
// SharesService actually calls. Naturally typed (no `any`) so
// `.mockResolvedValue(...)` stays permissive; cast to PrismaService only at
// the point each test constructs the service, since the mock is
// intentionally not a full PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    share: { findUnique: jest.fn(), update: jest.fn() },
    pet: { findUnique: jest.fn() },
    hug: { findFirst: jest.fn() },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

const basePetWithSensitiveFields = {
  id: 'pet-1',
  name: 'Mochi',
  type: 'CAT',
  mainPhotoId: 'photo-1',
  memorialSentence: 'sentence',
  story: 'story',
  arrivedOn: '2020-01-01',
  bornOn: null,
  leftOn: null,
  // Fields that must never leak into the public DTO even though they exist
  // on the underlying Prisma result:
  userId: 'owner-user-id',
  photos: [
    {
      id: 'photo-1',
      type: 'MAIN',
      r2Url: 'https://r2/photo-1.jpg',
      caption: null,
    },
  ],
};

describe('SharesService', () => {
  describe('findBySlug (public endpoint)', () => {
    it('rejects a PRIVATE share with 403 private_or_unavailable', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue({
        id: 'share-1',
        slug: 'abc',
        visibility: 'PRIVATE',
        hugEnabled: true,
        pet: basePetWithSensitiveFields,
        _count: { hugs: 0 },
      });
      const service = new SharesService(asPrismaService(prisma));

      const promise = service.findBySlug('abc');
      await expect(promise).rejects.toBeInstanceOf(ForbiddenException);
      await promise.catch((err: ForbiddenException) => {
        expect(err.getResponse()).toMatchObject({
          status: 'private_or_unavailable',
        });
      });
    });

    it('throws not_found for an unknown slug', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue(null);
      const service = new SharesService(asPrismaService(prisma));

      const promise = service.findBySlug('does-not-exist');
      await expect(promise).rejects.toBeInstanceOf(NotFoundException);
      await promise.catch((err: NotFoundException) => {
        expect(err.getResponse()).toMatchObject({ status: 'not_found' });
      });
    });

    it('returns a public DTO that never includes the owning userId or raw photos array', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue({
        id: 'share-1',
        slug: 'abc',
        visibility: 'LINK',
        hugEnabled: true,
        pet: basePetWithSensitiveFields,
        _count: { hugs: 3 },
      });
      prisma.hug.findFirst.mockResolvedValue(null);
      const service = new SharesService(asPrismaService(prisma));

      const result = await service.findBySlug('abc');

      expect(result).toMatchObject({
        status: 'ok',
        petName: 'Mochi',
        hugCount: 3,
        viewerHasHugged: false,
      });
      const serialized = JSON.stringify(result);
      expect(serialized).not.toContain('owner-user-id');
      expect(result).not.toHaveProperty('userId');
      expect(result).not.toHaveProperty('photos');
      expect(result.albumPhotos).toEqual([]); // no ALBUM-typed photo in the fixture
    });

    it('resolves viewerHasHugged from the given visitorFingerprint', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue({
        id: 'share-1',
        slug: 'abc',
        visibility: 'LINK',
        hugEnabled: true,
        pet: basePetWithSensitiveFields,
        _count: { hugs: 1 },
      });
      prisma.hug.findFirst.mockResolvedValue({ id: 'hug-1' });
      const service = new SharesService(asPrismaService(prisma));

      const result = await service.findBySlug('abc', 'visitor-fp-1');

      expect(result.viewerHasHugged).toBe(true);
      expect(prisma.hug.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { shareId: 'share-1', visitorFingerprint: 'visitor-fp-1' },
        }),
      );
    });
  });

  describe('update (owner-only)', () => {
    it('allows the owner to update visibility/hugEnabled', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue({
        petId: 'pet-1',
        pet: { userId: 'user-1' },
      });
      prisma.share.update.mockResolvedValue({
        visibility: 'PRIVATE',
        hugEnabled: false,
      });
      const service = new SharesService(asPrismaService(prisma));

      const result = await service.update('user-1', 'pet-1', {
        visibility: 'PRIVATE',
      });

      expect(result).toMatchObject({ visibility: 'PRIVATE' });
    });

    it('rejects a non-owner update attempt', async () => {
      const prisma = makePrisma();
      prisma.share.findUnique.mockResolvedValue({
        petId: 'pet-1',
        pet: { userId: 'owner-1' },
      });
      const service = new SharesService(asPrismaService(prisma));

      await expect(
        service.update('intruder-1', 'pet-1', { hugEnabled: false }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.share.update).not.toHaveBeenCalled();
    });
  });
});
