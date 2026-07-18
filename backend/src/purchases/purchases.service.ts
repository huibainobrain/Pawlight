import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import {
  Environment,
  JWSTransactionDecodedPayload,
  SignedDataVerifier,
  VerificationException,
} from '@apple/app-store-server-library';
import { PrismaService } from '../prisma/prisma.service';
import {
  EXPECTED_APPLE_BUNDLE_ID,
  getAppleAppAppleId,
} from '../config/env.validation';

// Must match exactly what you created in App Store Connect.
const EXPECTED_PRODUCT_ID = 'com.pawlight.full_memorial_space';
const BUNDLE_ID = process.env.APPLE_BUNDLE_ID ?? EXPECTED_APPLE_BUNDLE_ID;

@Injectable()
export class PurchasesService {
  private readonly logger = new Logger(PurchasesService.name);
  private readonly sandboxVerifier: SignedDataVerifier;
  // null until APPLE_APP_APPLE_ID (the app's numeric Apple ID from App Store
  // Connect > App Information) is configured — real Production purchases can't
  // be verified without it, but Sandbox/TestFlight/App Review testing still works.
  private readonly productionVerifier: SignedDataVerifier | null;

  constructor(private readonly prisma: PrismaService) {
    const rootCA = readFileSync(join(__dirname, 'certs', 'AppleRootCA-G3.cer'));

    this.sandboxVerifier = new SignedDataVerifier(
      [rootCA],
      true,
      Environment.SANDBOX,
      BUNDLE_ID,
    );

    const appAppleId = getAppleAppAppleId();
    if (appAppleId) {
      this.productionVerifier = new SignedDataVerifier(
        [rootCA],
        true,
        Environment.PRODUCTION,
        BUNDLE_ID,
        appAppleId,
      );
    } else {
      this.productionVerifier = null;
      this.logger.warn(
        'APPLE_APP_APPLE_ID is not set — Production App Store purchases will be rejected until it is configured.',
      );
    }
  }

  async verifyAndApply(userId: string, jwsToken: string): Promise<void> {
    const payload = await this.verifySignedTransaction(jwsToken);

    if (payload.productId !== EXPECTED_PRODUCT_ID) {
      throw new BadRequestException('Product ID mismatch');
    }
    if (payload.revocationDate) {
      throw new BadRequestException('Purchase has been revoked');
    }

    await this.prisma.entitlement.upsert({
      where: { userId },
      update: { tier: 'PAID', photoLimit: 50, mailboxEnabled: true },
      create: { userId, tier: 'PAID', photoLimit: 50, mailboxEnabled: true },
    });
  }

  // Cryptographically verifies the JWS against Apple's certificate chain (rooted at
  // Apple Root CA G3) instead of trusting the client-supplied payload as-is — StoreKit
  // 2's on-device .verified case only proves the transaction was well-formed to *this*
  // device, not that the payload posted to our API wasn't swapped out in transit.
  // One backend URL must accept both real purchases (Production) and App Review /
  // TestFlight testers (Sandbox), so Production is tried first and Sandbox is the
  // fallback when the transaction's embedded environment doesn't match.
  private async verifySignedTransaction(
    jws: string,
  ): Promise<JWSTransactionDecodedPayload> {
    if (this.productionVerifier) {
      try {
        return await this.productionVerifier.verifyAndDecodeTransaction(jws);
      } catch (e) {
        if (!(e instanceof VerificationException)) throw e;
      }
    }
    try {
      return await this.sandboxVerifier.verifyAndDecodeTransaction(jws);
    } catch (e) {
      if (e instanceof VerificationException) {
        this.logger.warn(
          `Purchase verification failed: ${VerificationException.name} status=${e.status}`,
        );
        throw new BadRequestException('Purchase verification failed');
      }
      throw e;
    }
  }
}
