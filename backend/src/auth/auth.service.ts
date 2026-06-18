import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import appleSignin from 'apple-signin-auth';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
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

    const token = this.jwt.sign({ sub: user.id });
    return { access_token: token, user };
  }
}
