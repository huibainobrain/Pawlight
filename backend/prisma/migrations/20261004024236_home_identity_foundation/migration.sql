-- CreateEnum
CREATE TYPE "LocationScope" AS ENUM ('HOME_BASE', 'NEARBY');

-- CreateEnum
CREATE TYPE "HomeVariantKind" AS ENUM ('COTTAGE_BLUEPRINT', 'PALETTE', 'ROOF', 'DOOR', 'WINDOW', 'SIGNATURE_PLANT');

-- CreateEnum
CREATE TYPE "HomeAnchorStatus" AS ENUM ('NONE', 'ESTABLISHED', 'INVALIDATED');

-- AlterTable
ALTER TABLE "EventTemplate" ADD COLUMN     "homeAnchorEligible" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "LocationAsset" ADD COLUMN     "scope" "LocationScope" NOT NULL DEFAULT 'NEARBY';

-- AlterTable
ALTER TABLE "PlanetEvent" ADD COLUMN     "establishedHomeAnchorVersion" INTEGER;

-- CreateTable
CREATE TABLE "PlanetStyle" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "illustrationLanguage" TEXT NOT NULL,
    "realismLevel" TEXT NOT NULL,
    "colorSaturationDirection" TEXT NOT NULL,
    "lighting" TEXT NOT NULL,
    "materialFeel" TEXT NOT NULL,
    "worldSafetyRules" TEXT NOT NULL,
    "forbiddenWorldStyles" TEXT NOT NULL,
    "imageGenGuidance" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlanetStyle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "HomeVariantAsset" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "kind" "HomeVariantKind" NOT NULL,
    "nameZh" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "visualDefinition" TEXT NOT NULL,
    "imageGenPrompt" TEXT NOT NULL,
    "colorTokens" JSONB,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "HomeVariantAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "HomeProfile" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "planetStyleId" TEXT NOT NULL,
    "cottageBlueprintKey" TEXT NOT NULL,
    "paletteKey" TEXT NOT NULL,
    "roofKey" TEXT NOT NULL,
    "doorKey" TEXT NOT NULL,
    "windowKey" TEXT NOT NULL,
    "signaturePlantKey" TEXT NOT NULL,
    "nameplateText" TEXT NOT NULL,
    "visualSnapshot" JSONB NOT NULL,
    "homeAnchorStatus" "HomeAnchorStatus" NOT NULL DEFAULT 'NONE',
    "homeAnchorVersion" INTEGER NOT NULL DEFAULT 0,
    "homeAnchorImageR2Key" TEXT,
    "homeAnchorImageR2Url" TEXT,
    "homeAnchorEventId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "HomeProfile_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PlanetStyle_key_key" ON "PlanetStyle"("key");

-- CreateIndex
CREATE UNIQUE INDEX "PlanetStyle_version_key" ON "PlanetStyle"("version");

-- CreateIndex
CREATE UNIQUE INDEX "HomeVariantAsset_key_key" ON "HomeVariantAsset"("key");

-- CreateIndex
CREATE INDEX "HomeVariantAsset_kind_idx" ON "HomeVariantAsset"("kind");

-- CreateIndex
CREATE UNIQUE INDEX "HomeProfile_petId_key" ON "HomeProfile"("petId");

-- AddForeignKey
ALTER TABLE "HomeProfile" ADD CONSTRAINT "HomeProfile_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HomeProfile" ADD CONSTRAINT "HomeProfile_planetStyleId_fkey" FOREIGN KEY ("planetStyleId") REFERENCES "PlanetStyle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
