import { RETRY_ATTEMPTS, RETRY_BASE_DELAY_MS } from './config';

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Retries only transient-looking failures (network errors, timeouts, 5xx,
// 429). A 4xx auth/bad-request error is almost always the same on every
// retry, so it's surfaced immediately instead of burning attempts on it.
function isRetryable(err: unknown): boolean {
  const message = err instanceof Error ? err.message : String(err);
  if (/\b(401|403)\b/.test(message)) return false;
  if (/\b(400|422)\b/.test(message)) return false;
  return true;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  label: string,
): Promise<T> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= RETRY_ATTEMPTS; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      const message = err instanceof Error ? err.message : String(err);
      if (!isRetryable(err) || attempt === RETRY_ATTEMPTS) {
        throw err;
      }
      const delay = RETRY_BASE_DELAY_MS * attempt;
      console.warn(
        `[retry] ${label} attempt ${attempt}/${RETRY_ATTEMPTS} failed (${message}); retrying in ${delay}ms`,
      );
      await sleep(delay);
    }
  }
  throw lastError;
}
