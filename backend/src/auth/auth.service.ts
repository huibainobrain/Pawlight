import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { PhotosService } from '../photos/photos.service';
import appleSignin from 'apple-signin-auth';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private photosService: PhotosService,
  ) {}

  async loginWithApple(identityToken: string) {
    let applePayload: { sub: string; email?: string };
    try {
      applePayload = await appleSignin.verifyIdToken(identityToken, {
        audience: process.env.APPLE_BUNDLE_ID,
        ignoreExpiration: false,
      });
    } catch {
      throw new UnauthorizedException('Apple identity token invalid');
    }

    const appleUserId = applePayload.sub;
    const email = applePayload.email;

    let user = await this.prisma.user.findUnique({ where: { appleUserId } });
    if (!user) {
      user = await this.prisma.user.create({
        data: { appleUserId, email },
      });
    }

    await this.ensureEntitlement(user.id);

    const token = this.jwt.sign({ sub: user.id });
    return { access_token: token, user };
  }

  async debugLogin(secret: string) {
    if (!process.env.DEBUG_SECRET || secret !== process.env.DEBUG_SECRET) {
      throw new ForbiddenException('Debug endpoint disabled');
    }
    const appleUserId = 'debug_user_simulator';
    let user = await this.prisma.user.findUnique({ where: { appleUserId } });
    if (!user) {
      user = await this.prisma.user.create({
        data: { appleUserId, email: 'debug@simulator.local' },
      });
    }

    await this.ensureEntitlement(user.id);
    // Always grant full access for debug sessions so the mailbox and album
    // features work without manual DB edits.
    await this.prisma.entitlement.update({
      where: { userId: user.id },
      data: { mailboxEnabled: true, photoLimit: 50, tier: 'PAID' },
    });
    await this.prisma.pet.deleteMany({ where: { userId: user.id } });

    const token = this.jwt.sign({ sub: user.id });
    return { access_token: token, user };
  }

  // Required for App Store review (Guideline 5.1.1(v)): apps that support
  // account creation must let users delete their account in-app. R2 objects
  // have to be removed explicitly first — Postgres cascade only reaches the
  // DB rows (Pet -> Photo/Share/Letter -> Hug, and Entitlement directly).
  async deleteAccount(userId: string) {
    await this.photosService.deleteAllForUser(userId);
    await this.prisma.user.delete({ where: { id: userId } });
  }

  // Entitlement is account-level: every user gets a FREE entitlement on first
  // login if one does not already exist.
  private async ensureEntitlement(userId: string) {
    const existing = await this.prisma.entitlement.findUnique({
      where: { userId },
    });
    if (!existing) {
      await this.prisma.entitlement.create({
        data: { userId, tier: 'FREE', photoLimit: 9, mailboxEnabled: false },
      });
    }
  }
}
