-- V1 P0 backend changes: account-level entitlement, photo types, letter title,
-- hug visitorFingerprint dedup. Written by hand to preserve existing data.

-- =========================================================================
-- 1. PhotoType enum + Photo.type column
-- =========================================================================
CREATE TYPE "PhotoType" AS ENUM ('MAIN', 'ALBUM');

ALTER TABLE "Photo" ADD COLUMN "type" "PhotoType" NOT NULL DEFAULT 'ALBUM';

-- Backfill: any photo currently referenced as a pet's main photo becomes MAIN.
UPDATE "Photo" p
SET "type" = 'MAIN'
FROM "Pet" pt
WHERE pt."mainPhotoId" = p."id";

CREATE INDEX "Photo_petId_type_idx" ON "Photo"("petId", "type");

-- =========================================================================
-- 2. Letter.title (optional)
-- =========================================================================
ALTER TABLE "Letter" ADD COLUMN "title" TEXT;

-- =========================================================================
-- 3. Hug.visitorFingerprint (required) + dedup unique constraint
-- =========================================================================
-- Add as nullable first so we can backfill existing rows.
ALTER TABLE "Hug" ADD COLUMN "visitorFingerprint" TEXT;

-- Backfill existing hugs with a generated value so the column can be NOT NULL.
-- (No pgcrypto dependency: synthesize a unique token from the row id + random.)
UPDATE "Hug"
SET "visitorFingerprint" = 'legacy-' || "id"
WHERE "visitorFingerprint" IS NULL;

ALTER TABLE "Hug" ALTER COLUMN "visitorFingerprint" SET NOT NULL;

CREATE INDEX "Hug_shareId_idx" ON "Hug"("shareId");
CREATE UNIQUE INDEX "Hug_shareId_visitorFingerprint_key" ON "Hug"("shareId", "visitorFingerprint");

-- =========================================================================
-- 4. Entitlement: move from pet-level to account (user) level
-- =========================================================================
-- New columns first.
ALTER TABLE "Entitlement" ADD COLUMN "userId" TEXT;
ALTER TABLE "Entitlement" ADD COLUMN "photoLimit" INTEGER NOT NULL DEFAULT 9;
ALTER TABLE "Entitlement" ADD COLUMN "mailboxEnabled" BOOLEAN NOT NULL DEFAULT false;

-- Backfill userId from the entitlement's pet owner.
UPDATE "Entitlement" e
SET "userId" = pt."userId"
FROM "Pet" pt
WHERE e."petId" = pt."id";

-- Derive photoLimit / mailboxEnabled from existing tier.
UPDATE "Entitlement"
SET "photoLimit" = CASE WHEN "tier" = 'PAID' THEN 50 ELSE 9 END,
    "mailboxEnabled" = CASE WHEN "tier" = 'PAID' THEN true ELSE false END;

-- Collapse multiple pet-level entitlements per user into a single account-level
-- entitlement. Keep the "strongest" one (PAID over FREE, then most recent),
-- delete the rest. PAID on any pet upgrades the whole account.
WITH ranked AS (
  SELECT "id",
         "userId",
         ROW_NUMBER() OVER (
           PARTITION BY "userId"
           ORDER BY (CASE WHEN "tier" = 'PAID' THEN 0 ELSE 1 END), "createdAt" DESC
         ) AS rn
  FROM "Entitlement"
  WHERE "userId" IS NOT NULL
)
DELETE FROM "Entitlement"
WHERE "id" IN (SELECT "id" FROM ranked WHERE rn > 1);

-- Any orphan entitlement whose pet/user could not be resolved is dead data.
DELETE FROM "Entitlement" WHERE "userId" IS NULL;

-- Ensure every user has exactly one (FREE) entitlement, creating any missing.
INSERT INTO "Entitlement" ("id", "userId", "tier", "photoLimit", "mailboxEnabled", "createdAt", "updatedAt")
SELECT
  'ent_' || u."id",
  u."id",
  'FREE',
  9,
  false,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM "User" u
WHERE NOT EXISTS (
  SELECT 1 FROM "Entitlement" e WHERE e."userId" = u."id"
);

-- Drop old pet-level structures.
ALTER TABLE "Entitlement" DROP CONSTRAINT IF EXISTS "Entitlement_petId_fkey";
DROP INDEX IF EXISTS "Entitlement_petId_key";
ALTER TABLE "Entitlement" DROP COLUMN "petId";
ALTER TABLE "Entitlement" DROP COLUMN "purchaseId";
ALTER TABLE "Entitlement" DROP COLUMN "expiredAt";

-- Enforce new account-level shape.
ALTER TABLE "Entitlement" ALTER COLUMN "userId" SET NOT NULL;
CREATE UNIQUE INDEX "Entitlement_userId_key" ON "Entitlement"("userId");
ALTER TABLE "Entitlement"
  ADD CONSTRAINT "Entitlement_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
