import appleSignin from 'apple-signin-auth';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { PhotosService } from '../photos/photos.service';
import { ScenePortraitsService } from '../scene-portraits/scene-portraits.service';

jest.mock('apple-signin-auth', () => ({
  __esModule: true,
  default: { verifyIdToken: jest.fn() },
}));

// Hand-built mocks satisfying only the methods AuthService actually calls on
// each dependency. Naturally typed (no `any`) so `.mockResolvedValue(...)`
// stays permissive; cast to the real class type only at the point each test
// constructs the service, since these are intentionally not full instances
// (see docs/reference/testing.md). JwtService/PhotosService/
// ScenePortraitsService are classes (not plain interfaces), so a structural
// object literal can't satisfy them directly without going through
// `unknown` first.
function makePrisma() {
  return {
    user: { findUnique: jest.fn(), create: jest.fn(), delete: jest.fn() },
    entitlement: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    pet: { deleteMany: jest.fn() },
  };
}

function asPrismaService(prisma: ReturnType<typeof makePrisma>) {
  return prisma as unknown as PrismaService;
}

function makeJwt() {
  return { sign: jest.fn().mockReturnValue('signed-jwt') };
}

function asJwtService(jwt: ReturnType<typeof makeJwt>) {
  return jwt as unknown as JwtService;
}

function makeDeps() {
  return {
    photosService: {
      deleteAllForUser: jest.fn().mockResolvedValue(undefined),
    },
    scenePortraitsService: {
      deleteAllForUser: jest.fn().mockResolvedValue(undefined),
    },
  };
}

function asPhotosService(
  photosService: ReturnType<typeof makeDeps>['photosService'],
) {
  return photosService as unknown as PhotosService;
}

function asScenePortraitsService(
  scenePortraitsService: ReturnType<typeof makeDeps>['scenePortraitsService'],
) {
  return scenePortraitsService as unknown as ScenePortraitsService;
}

describe('AuthService', () => {
  describe('loginWithApple / ensureEntitlement', () => {
    it('creates a new User and a FREE Entitlement on first login', async () => {
      (appleSignin.verifyIdToken as jest.Mock).mockResolvedValue({
        sub: 'apple-sub-1',
        email: 'a@b.com',
      });
      const prisma = makePrisma();
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'user-1',
        appleUserId: 'apple-sub-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue(null);
      const { photosService, scenePortraitsService } = makeDeps();
      const service = new AuthService(
        asPrismaService(prisma),
        asJwtService(makeJwt()),
        asPhotosService(photosService),
        asScenePortraitsService(scenePortraitsService),
      );

      await service.loginWithApple('id-token');

      expect(prisma.user.create).toHaveBeenCalledWith({
        data: { appleUserId: 'apple-sub-1', email: 'a@b.com' },
      });
      expect(prisma.entitlement.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          tier: 'FREE',
          photoLimit: 9,
          mailboxEnabled: false,
        },
      });
    });

    it('does not create a duplicate entitlement for a returning user who already has one', async () => {
      (appleSignin.verifyIdToken as jest.Mock).mockResolvedValue({
        sub: 'apple-sub-1',
      });
      const prisma = makePrisma();
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        appleUserId: 'apple-sub-1',
      });
      prisma.entitlement.findUnique.mockResolvedValue({
        id: 'ent-1',
        userId: 'user-1',
        tier: 'PAID',
      });
      const { photosService, scenePortraitsService } = makeDeps();
      const service = new AuthService(
        asPrismaService(prisma),
        asJwtService(makeJwt()),
        asPhotosService(photosService),
        asScenePortraitsService(scenePortraitsService),
      );

      await service.loginWithApple('id-token');

      expect(prisma.user.create).not.toHaveBeenCalled();
      expect(prisma.entitlement.create).not.toHaveBeenCalled();
    });
  });

  describe('deleteAccount', () => {
    it('cleans up Photo and ScenePortrait R2 objects before deleting the User', async () => {
      const prisma = makePrisma();
      prisma.user.delete.mockResolvedValue({ id: 'user-1' });
      const { photosService, scenePortraitsService } = makeDeps();
      const service = new AuthService(
        asPrismaService(prisma),
        asJwtService(makeJwt()),
        asPhotosService(photosService),
        asScenePortraitsService(scenePortraitsService),
      );

      const calls: string[] = [];
      photosService.deleteAllForUser.mockImplementation(() => {
        calls.push('photos');
        return Promise.resolve();
      });
      scenePortraitsService.deleteAllForUser.mockImplementation(() => {
        calls.push('scenePortraits');
        return Promise.resolve();
      });
      prisma.user.delete.mockImplementation(() => {
        calls.push('user');
        return Promise.resolve({ id: 'user-1' });
      });

      await service.deleteAccount('user-1');

      expect(photosService.deleteAllForUser).toHaveBeenCalledWith('user-1');
      expect(scenePortraitsService.deleteAllForUser).toHaveBeenCalledWith(
        'user-1',
      );
      expect(prisma.user.delete).toHaveBeenCalledWith({
        where: { id: 'user-1' },
      });
      // Storage cleanup must happen before the DB cascade removes the rows
      // that name which R2 objects to delete.
      expect(calls).toEqual(['photos', 'scenePortraits', 'user']);
    });
  });
});
