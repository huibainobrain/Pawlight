import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { LettersService } from './letters.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods
// LettersService actually calls. Naturally typed (no `any`) so
// `.mockResolvedValue(...)` stays permissive; cast to PrismaService only at
// the point each test constructs the service, since the mock is
// intentionally not a full PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    pet: { findUnique: jest.fn() },
    entitlement: { findUnique: jest.fn() },
    letter: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

describe('LettersService', () => {
  describe('mailbox gating', () => {
    it('rejects a FREE account with mailbox disabled', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'FREE',
        mailboxEnabled: false,
      });
      const service = new LettersService(asPrismaService(prisma));

      const promise = service.findByPet('user-1', 'pet-1');
      await expect(promise).rejects.toBeInstanceOf(ForbiddenException);
      await promise.catch((err: ForbiddenException) => {
        expect(err.getResponse()).toMatchObject({
          code: 'MAILBOX_NOT_ENABLED',
        });
      });
    });

    it('accepts a PAID account even if mailboxEnabled is not explicitly true', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'PAID',
        mailboxEnabled: false,
      });
      prisma.letter.findMany.mockResolvedValue([]);
      const service = new LettersService(asPrismaService(prisma));

      await expect(service.findByPet('user-1', 'pet-1')).resolves.toEqual([]);
    });

    it('accepts a FREE account with mailboxEnabled explicitly true', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'FREE',
        mailboxEnabled: true,
      });
      prisma.letter.findMany.mockResolvedValue([]);
      const service = new LettersService(asPrismaService(prisma));

      await expect(service.findByPet('user-1', 'pet-1')).resolves.toEqual([]);
    });

    it('rejects when there is no entitlement row at all', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue(null);
      const service = new LettersService(asPrismaService(prisma));

      await expect(service.findByPet('user-1', 'pet-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('ownership', () => {
    it('rejects a non-owner even if the pet owner is PAID', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'owner-1',
      });
      const service = new LettersService(asPrismaService(prisma));

      await expect(
        service.findByPet('intruder-1', 'pet-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.entitlement.findUnique).not.toHaveBeenCalled();
    });

    it('remove() rejects deleting a letter belonging to another user', async () => {
      const prisma = makePrisma();
      prisma.letter.findUnique.mockResolvedValue({
        id: 'letter-1',
        pet: { userId: 'owner-1' },
      });
      const service = new LettersService(asPrismaService(prisma));

      await expect(
        service.remove('intruder-1', 'letter-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.letter.delete).not.toHaveBeenCalled();
    });

    it('remove() throws NotFoundException for a nonexistent letter', async () => {
      const prisma = makePrisma();
      prisma.letter.findUnique.mockResolvedValue(null);
      const service = new LettersService(asPrismaService(prisma));

      await expect(service.remove('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('upsert', () => {
    it('creates a new letter when no letterId is given', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'PAID',
        mailboxEnabled: true,
      });
      prisma.letter.create.mockResolvedValue({
        id: 'letter-1',
        content: 'hello',
      });
      const service = new LettersService(asPrismaService(prisma));

      const result = await service.upsert('user-1', 'pet-1', null, {
        content: 'hello',
      });

      expect(prisma.letter.create).toHaveBeenCalledWith({
        data: { petId: 'pet-1', title: undefined, content: 'hello' },
      });
      expect(result).toMatchObject({ id: 'letter-1' });
    });

    it('rejects updating a letter that belongs to a different pet', async () => {
      const prisma = makePrisma();
      prisma.pet.findUnique.mockResolvedValue({
        id: 'pet-1',
        userId: 'user-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        tier: 'PAID',
        mailboxEnabled: true,
      });
      prisma.letter.findUnique.mockResolvedValue({
        id: 'letter-1',
        petId: 'other-pet',
      });
      const service = new LettersService(asPrismaService(prisma));

      await expect(
        service.upsert('user-1', 'pet-1', 'letter-1', { content: 'x' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.letter.update).not.toHaveBeenCalled();
    });
  });
});
