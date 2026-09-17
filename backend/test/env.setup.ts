// Jest "setupFiles" entry — runs before any test file (and therefore before
// AppModule / env.validation.ts's `import 'dotenv/config'`) is imported.
// dotenv never overrides an already-set process.env key, so setting
// DATABASE_URL etc. here first means the real backend/.env (if present) can
// never leak a production connection string into an e2e test run.
process.env.SCENE_PORTRAIT_IMAGE_PROVIDER =
  process.env.SCENE_PORTRAIT_IMAGE_PROVIDER ?? 'fake';
process.env.SCENE_PORTRAIT_VIDEO_PROVIDER =
  process.env.SCENE_PORTRAIT_VIDEO_PROVIDER ?? 'fake';
process.env.STORAGE_PROVIDER = process.env.STORAGE_PROVIDER ?? 'fake';
process.env.JWT_SECRET =
  process.env.JWT_SECRET ?? 'test-jwt-secret-not-for-production';
process.env.DEBUG_SECRET = process.env.DEBUG_SECRET ?? 'test-debug-secret';
process.env.R2_ACCOUNT_ID = process.env.R2_ACCOUNT_ID ?? 'test-account-id';
process.env.R2_ACCESS_KEY_ID =
  process.env.R2_ACCESS_KEY_ID ?? 'test-access-key';
process.env.R2_SECRET_ACCESS_KEY =
  process.env.R2_SECRET_ACCESS_KEY ?? 'test-secret-key';
process.env.R2_BUCKET = process.env.R2_BUCKET ?? 'test-bucket';
process.env.R2_PUBLIC_URL =
  process.env.R2_PUBLIC_URL ?? 'https://test.example.invalid';

// DATABASE_URL_TEST is the only override honored here — deliberately not
// falling back to an ambient DATABASE_URL, so a developer's real .env can
// never be picked up by accident.
process.env.DATABASE_URL =
  process.env.DATABASE_URL_TEST ??
  'postgresql://postgres@localhost:5432/pawlight_e2e_test';

// Hard safety net: e2e tests must never run against a real deployed
// database. Fail immediately, before anything connects, rather than risk
// running test data mutations against production.
if (/rlwy\.net|railway\.app/.test(process.env.DATABASE_URL)) {
  throw new Error(
    'Refusing to run e2e tests against what looks like a real Railway DATABASE_URL. ' +
      'Set DATABASE_URL_TEST to a local/test Postgres instance instead.',
  );
}
