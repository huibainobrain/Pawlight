import { Prisma } from '@prisma/client';
import { HugsService } from './hugs.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate methods HugsService
// actually calls. Naturally typed (no `any`) so `.mockResolvedValue(...)`
// stays permissive; cast to PrismaService only at the point each test
// constructs the service, since the mock is intentionally not a full
// PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return {
    share: { findUnique: jest.fn() },
    hug: { findFirst: jest.fn(), create: jest.fn(), count: jest.fn() },
    pet: { findUnique: jest.fn() },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

function p2002() {
  return new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
    code: 'P2002',
    clientVersion: '5.22.0',
  });
}

describe('HugsService.create', () => {
  it('returns not_found for an unknown slug', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue(null);
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('missing-slug', {
      visitorFingerprint: 'fp-1',
    });

    expect(result).toEqual({ status: 'not_found' });
  });

  it('returns not_found when the share has no pet', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: null,
      visibility: 'LINK',
    });
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('slug', { visitorFingerprint: 'fp-1' });

    expect(result).toEqual({ status: 'not_found' });
  });

  it('returns private_or_unavailable for a PRIVATE share', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'PRIVATE',
    });
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('slug', { visitorFingerprint: 'fp-1' });

    expect(result).toEqual({ status: 'private_or_unavailable' });
  });

  it('returns hug_disabled when the share has hugs turned off', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'LINK',
      hugEnabled: false,
    });
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('slug', { visitorFingerprint: 'fp-1' });

    expect(result).toEqual({ status: 'hug_disabled' });
  });

  it('returns already_hugged when the pre-check finds an existing hug', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'LINK',
      hugEnabled: true,
    });
    prisma.hug.findFirst.mockResolvedValue({ id: 'existing-hug' });
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('slug', { visitorFingerprint: 'fp-1' });

    expect(result).toEqual({ status: 'already_hugged' });
    expect(prisma.hug.create).not.toHaveBeenCalled();
  });

  it('returns success and the new hug count on the first hug', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'LINK',
      hugEnabled: true,
    });
    prisma.hug.findFirst.mockResolvedValue(null);
    prisma.hug.create.mockResolvedValue({ id: 'hug-1' });
    prisma.hug.count.mockResolvedValue(4);
    const service = new HugsService(asPrismaService(prisma));

    const result = await service.create('slug', {
      visitorFingerprint: 'fp-1',
      visitorName: 'A friend',
    });

    expect(result).toEqual({
      status: 'success',
      hug: { id: 'hug-1' },
      hugCount: 4,
    });
  });

  it('maps a concurrent Prisma P2002 unique-constraint violation to already_hugged', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'LINK',
      hugEnabled: true,
    });
    prisma.hug.findFirst.mockResolvedValue(null); // pre-check sees no row yet
    prisma.hug.create.mockRejectedValue(p2002()); // but the insert races another request

    const service = new HugsService(asPrismaService(prisma));
    const result = await service.create('slug', { visitorFingerprint: 'fp-1' });

    expect(result).toEqual({ status: 'already_hugged' });
  });

  it('re-throws a non-P2002 error from the insert', async () => {
    const prisma = makePrisma();
    prisma.share.findUnique.mockResolvedValue({
      id: 'share-1',
      pet: {},
      visibility: 'LINK',
      hugEnabled: true,
    });
    prisma.hug.findFirst.mockResolvedValue(null);
    prisma.hug.create.mockRejectedValue(new Error('connection lost'));

    const service = new HugsService(asPrismaService(prisma));
    await expect(
      service.create('slug', { visitorFingerprint: 'fp-1' }),
    ).rejects.toThrow('connection lost');
  });
});
