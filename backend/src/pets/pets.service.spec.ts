import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PetsService } from './pets.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods PetsService
// actually calls. Naturally typed (no `any`) so `.mockResolvedValue(...)`
// stays permissive; cast to PrismaService only at the point each test
// constructs the service, since the mock is intentionally not a full
// PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    pet: {
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findUnique: jest.fn(),
    },
    entitlement: { findUnique: jest.fn() },
    photo: { count: jest.fn() },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

describe('PetsService', () => {
  describe('create', () => {
    it('rejects with PET_LIMIT_REACHED when the user already owns a pet', async () => {
      const prisma = makePrisma();
      prisma.pet.count.mockResolvedValue(1);
      const service = new PetsService(asPrismaService(prisma));

      let caught: unknown;
      try {
        await service.create('user-1', { name: 'Mochi', type: 'CAT' });
      } catch (err) {
        caught = err;
      }

      expect(caught).toBeInstanceOf(ConflictException);
      expect((caught as ConflictException).getResponse()).toMatchObject({
        code: 'PET_LIMIT_REACHED',
      });
      expect(prisma.pet.create).not.toHaveBeenCalled();
    });

    it('creates a pet with a generated share slug when the user has none yet', async () => {
      const prisma = makePrisma();
      prisma.pet.count.mockResolvedValue(0);
      prisma.pet.create.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
        name: 'Mochi',
      });
      prisma.entitlement.findUnique.mockResolvedValue(null);
      prisma.photo.count.mockResolvedValue(0);
      const service = new PetsService(asPrismaService(prisma));

      const result = await service.create('user-1', {
        name: 'Mochi',
        type: 'CAT',
      });

      expect(prisma.pet.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: 'user-1',
            name: 'Mochi',
            share: { create: { slug: expect.any(String) } },
          }),
        }),
      );
      expect(result).toMatchObject({
        id: 'pet-1',
        albumPhotoLimit: 9,
        mailboxEnabled: false,
      });
    });
  });

  describe('update (ownership)', () => {
    it('allows the owner to update their pet', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.pet.update.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
        name: 'New Name',
      });
      prisma.entitlement.findUnique.mockResolvedValue(null);
      prisma.photo.count.mockResolvedValue(0);
      const service = new PetsService(asPrismaService(prisma));

      const result = await service.update('user-1', 'pet-1', {
        name: 'New Name',
      });

      expect(result).toMatchObject({ name: 'New Name' });
      expect(prisma.pet.update).toHaveBeenCalled();
    });

    it('rejects a non-owner with ForbiddenException', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'owner-1',
      });
      const service = new PetsService(asPrismaService(prisma));

      await expect(
        service.update('intruder-1', 'pet-1', { name: 'Hijacked' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.pet.update).not.toHaveBeenCalled();
    });

    it('rejects an update to a nonexistent pet with NotFoundException', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue(null);
      const service = new PetsService(asPrismaService(prisma));

      await expect(
        service.update('user-1', 'missing-pet', { name: 'X' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
