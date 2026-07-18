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
  // can run against Sandbox only, but production cannot.
  if (isProduction()) {
    requireEnv('APPLE_APP_APPLE_ID');
    requireEnv('APPLE_BUNDLE_ID');
  }
}
