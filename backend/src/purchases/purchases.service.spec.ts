import { BadRequestException } from '@nestjs/common';
import {
  SignedDataVerifier,
  VerificationException,
  VerificationStatus,
} from '@apple/app-store-server-library';
import { PurchasesService } from './purchases.service';
import { PrismaService } from '../prisma/prisma.service';

// A hand-built mock satisfying only the Prisma delegate method
// PurchasesService actually calls. Naturally typed (no `any`) so
// `.mockResolvedValue(...)` stays permissive; cast to PrismaService only at
// the point each test constructs the service, since the mock is
// intentionally not a full PrismaService (see docs/reference/testing.md).
function makePrisma() {
  return { entitlement: { upsert: jest.fn() } };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

const EXPECTED_PRODUCT_ID = 'com.pawlight.full_memorial_space';

describe('PurchasesService', () => {
  const originalAppleAppAppleId = process.env.APPLE_APP_APPLE_ID;

  afterEach(() => {
    jest.restoreAllMocks();
    if (originalAppleAppAppleId === undefined)
      delete process.env.APPLE_APP_APPLE_ID;
    else process.env.APPLE_APP_APPLE_ID = originalAppleAppAppleId;
  });

  describe('sandbox-only verification (APPLE_APP_APPLE_ID unset)', () => {
    beforeEach(() => {
      delete process.env.APPLE_APP_APPLE_ID;
    });

    it('applies PAID entitlement for a valid, non-revoked transaction', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockResolvedValue({
          productId: EXPECTED_PRODUCT_ID,
          revocationDate: undefined,
        });

      await service.verifyAndApply('user-1', 'fake-jws-token');

      expect(prisma.entitlement.upsert).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        update: { tier: 'PAID', photoLimit: 50, mailboxEnabled: true },
        create: {
          userId: 'user-1',
          tier: 'PAID',
          photoLimit: 50,
          mailboxEnabled: true,
        },
      });
    });

    it('rejects a transaction for a different product id', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockResolvedValue({
          productId: 'com.someone.other_product',
          revocationDate: undefined,
        });

      await expect(
        service.verifyAndApply('user-1', 'fake-jws-token'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.entitlement.upsert).not.toHaveBeenCalled();
    });

    it('rejects a revoked transaction', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockResolvedValue({
          productId: EXPECTED_PRODUCT_ID,
          revocationDate: Date.now(),
        });

      await expect(
        service.verifyAndApply('user-1', 'fake-jws-token'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.entitlement.upsert).not.toHaveBeenCalled();
    });

    it('rejects when signature/chain verification itself fails', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockRejectedValue(
          new VerificationException(VerificationStatus.VERIFICATION_FAILURE),
        );

      await expect(
        service.verifyAndApply('user-1', 'garbage-token'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.entitlement.upsert).not.toHaveBeenCalled();
    });

    it('re-throws a non-VerificationException error unchanged', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockRejectedValue(new Error('network down'));

      await expect(service.verifyAndApply('user-1', 'token')).rejects.toThrow(
        'network down',
      );
    });
  });

  describe('production-then-sandbox fallback (APPLE_APP_APPLE_ID set)', () => {
    beforeEach(() => {
      process.env.APPLE_APP_APPLE_ID = '123456789';
    });

    it('falls back to the sandbox verifier when the production verifier rejects with VerificationException', async () => {
      const prisma = makePrisma();
      const service = new PurchasesService(asPrismaService(prisma));
      let call = 0;
      jest
        .spyOn(SignedDataVerifier.prototype, 'verifyAndDecodeTransaction')
        .mockImplementation(() => {
          call += 1;
          if (call === 1) {
            throw new VerificationException(
              VerificationStatus.INVALID_ENVIRONMENT,
            );
          }
          return Promise.resolve({
            productId: EXPECTED_PRODUCT_ID,
            revocationDate: undefined,
          });
        });

      await service.verifyAndApply('user-1', 'sandbox-token');

      expect(call).toBe(2); // production tried first, then sandbox
      expect(prisma.entitlement.upsert).toHaveBeenCalled();
    });
  });
});
