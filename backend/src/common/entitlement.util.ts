import { Tier } from '@prisma/client';

export const FREE_PHOTO_LIMIT = 9;
export const PAID_PHOTO_LIMIT = 50;

// The album photo limit is derived from the account tier. We prefer an explicit
// photoLimit stored on the entitlement when present, otherwise fall back to the
// tier default. This keeps quota logic in one place across pets/photos services.
export function albumPhotoLimit(
  entitlement?: {
    tier: Tier;
    photoLimit?: number | null;
  } | null,
): number {
  if (entitlement?.photoLimit && entitlement.photoLimit > 0) {
    return entitlement.photoLimit;
  }
  return entitlement?.tier === 'PAID' ? PAID_PHOTO_LIMIT : FREE_PHOTO_LIMIT;
}
