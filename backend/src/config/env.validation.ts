// Explicit, so requireEnv() below never depends on import order to see a
// loaded .env. ConfigModule.forRoot() doesn't help here — it's called inside
// the @Module() decorator's imports array, which evaluates after
// validateRequiredEnv() already ran (see app.module.ts). Confirmed by testing
// that .env was, in the current app.module.ts import order, only reaching
// process.env in time because PrismaModule happens to be imported earlier and
// loads it as a side effect — an accident of import order, not a guarantee,
// so any future reordering could silently break local dev. A missing .env
// file (e.g. on Railway, where real env vars are injected directly) is a
// silent no-op, so this is safe in every environment.
import 'dotenv/config';

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function isPositiveInteger(value: number): boolean {
  return Number.isInteger(value) && value > 0;
}

function requireNumericEnv(name: string): number {
  const raw = requireEnv(name);
  const value = Number(raw);
  if (!isPositiveInteger(value)) {
    throw new Error(`${name} must be a valid positive integer`);
  }
  return value;
}

// Must match the iOS app's real Bundle ID exactly — a mismatch doesn't fail
// loudly on its own, it just makes Apple reject every real transaction's
// signature during verification.
export const EXPECTED_APPLE_BUNDLE_ID = 'com.pawlight.app';

// Read-only accessor for purchases.service.ts: the numeric App Apple ID when
// it's present and valid, or undefined otherwise. Never throws — development
// is allowed to run without it (Sandbox-only). In production this is
// guaranteed valid by validateRequiredEnv() before any provider is
// constructed, so callers there never actually see the undefined branch.
export function getAppleAppAppleId(): number | undefined {
  const raw = process.env.APPLE_APP_APPLE_ID;
  if (!raw) return undefined;
  const value = Number(raw);
  return isPositiveInteger(value) ? value : undefined;
}

// Called once at module load (see AppModule), before Nest starts wiring up
// providers — so a missing var crashes the process immediately instead of
// surfacing later as a bad JWT secret or a purchase that only fails IAP
// verification after the user has already paid.
export function validateRequiredEnv(): void {
  requireEnv('JWT_SECRET');
  requireEnv('DATABASE_URL');

  // Cloudflare R2 (photo storage) has no local mock — every environment needs
  // real credentials, or uploads either throw mid-request or silently write
  // broken "undefined/..." URLs into the DB.
  requireEnv('R2_ACCOUNT_ID');
  requireEnv('R2_ACCESS_KEY_ID');
  requireEnv('R2_SECRET_ACCESS_KEY');
  requireEnv('R2_BUCKET');
  requireEnv('R2_PUBLIC_URL');

  // Sign in with Apple / App Store Server API verification: local development
  // can run against Sandbox only, but production cannot. A present-but-wrong
  // value (typo'd ID, wrong bundle id copied from another app) would
  // otherwise degrade silently into "every real transaction fails
  // verification" instead of failing at startup.
  if (isProduction()) {
    requireNumericEnv('APPLE_APP_APPLE_ID');
    const bundleId = requireEnv('APPLE_BUNDLE_ID');
    if (bundleId !== EXPECTED_APPLE_BUNDLE_ID) {
      throw new Error(`APPLE_BUNDLE_ID must be ${EXPECTED_APPLE_BUNDLE_ID}`);
    }
  }
}
