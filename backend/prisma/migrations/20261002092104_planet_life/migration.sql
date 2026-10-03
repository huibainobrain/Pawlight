-- CreateEnum
CREATE TYPE "PlanetEventStatus" AS ENUM ('UNREAD', 'READ', 'BAD_CASE');

-- CreateEnum
CREATE TYPE "GiftSaleStatus" AS ENUM ('ACTIVE', 'HIDDEN');

-- CreateEnum
CREATE TYPE "GiftInstanceStatus" AS ENUM ('PENDING', 'COMPLETED');

-- AlterTable
ALTER TABLE "Entitlement" ADD COLUMN     "starLifeEnabled" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "language" TEXT DEFAULT 'en';

-- CreateTable
CREATE TABLE "PlanetLifeState" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "paused" BOOLEAN NOT NULL DEFAULT false,
    "notifyOnNewEvent" BOOLEAN NOT NULL DEFAULT true,
    "nextEligibleAt" TIMESTAMP(3),
    "weeklyEventCount" INTEGER NOT NULL DEFAULT 0,
    "weeklyWindowStart" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlanetLifeState_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlanetEvent" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "eventTemplateKey" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "language" TEXT NOT NULL,
    "imageR2Key" TEXT NOT NULL,
    "imageR2Url" TEXT NOT NULL,
    "status" "PlanetEventStatus" NOT NULL DEFAULT 'UNREAD',
    "factsJson" JSONB NOT NULL,
    "giftInstanceId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readAt" TIMESTAMP(3),

    CONSTRAINT "PlanetEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventTemplate" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "locationPool" JSONB NOT NULL,
    "actionPool" JSONB NOT NULL,
    "timePool" JSONB NOT NULL,
    "atmospherePool" JSONB NOT NULL,
    "ambientDetailsPool" JSONB,
    "giftCompatible" BOOLEAN NOT NULL DEFAULT false,
    "weight" INTEGER NOT NULL DEFAULT 1,
    "cooldownDays" INTEGER,
    "speciesApplicability" JSONB,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EventTemplate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftAsset" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "nameZh" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "descriptionZh" TEXT NOT NULL,
    "descriptionEn" TEXT NOT NULL,
    "illustrationAssetName" TEXT NOT NULL,
    "eventCompatibility" JSONB NOT NULL,
    "repeatable" BOOLEAN NOT NULL DEFAULT true,
    "saleStatus" "GiftSaleStatus" NOT NULL DEFAULT 'ACTIVE',
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "speciesApplicability" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GiftAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftProduct" (
    "id" TEXT NOT NULL,
    "giftAssetId" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GiftProduct_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftInstance" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "giftAssetId" TEXT NOT NULL,
    "status" "GiftInstanceStatus" NOT NULL DEFAULT 'PENDING',
    "purchaseTransactionId" TEXT,
    "purchasedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GiftInstance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PlanetLifeState_petId_key" ON "PlanetLifeState"("petId");

-- CreateIndex
CREATE INDEX "PlanetEvent_petId_createdAt_idx" ON "PlanetEvent"("petId", "createdAt");

-- CreateIndex
CREATE INDEX "PlanetEvent_giftInstanceId_idx" ON "PlanetEvent"("giftInstanceId");

-- CreateIndex
CREATE UNIQUE INDEX "EventTemplate_key_key" ON "EventTemplate"("key");

-- CreateIndex
CREATE UNIQUE INDEX "GiftAsset_key_key" ON "GiftAsset"("key");

-- CreateIndex
CREATE UNIQUE INDEX "GiftProduct_productId_key" ON "GiftProduct"("productId");

-- CreateIndex
CREATE INDEX "GiftProduct_giftAssetId_idx" ON "GiftProduct"("giftAssetId");

-- CreateIndex
CREATE UNIQUE INDEX "GiftInstance_purchaseTransactionId_key" ON "GiftInstance"("purchaseTransactionId");

-- CreateIndex
CREATE INDEX "GiftInstance_petId_status_idx" ON "GiftInstance"("petId", "status");

-- AddForeignKey
ALTER TABLE "PlanetLifeState" ADD CONSTRAINT "PlanetLifeState_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanetEvent" ADD CONSTRAINT "PlanetEvent_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanetEvent" ADD CONSTRAINT "PlanetEvent_giftInstanceId_fkey" FOREIGN KEY ("giftInstanceId") REFERENCES "GiftInstance"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftProduct" ADD CONSTRAINT "GiftProduct_giftAssetId_fkey" FOREIGN KEY ("giftAssetId") REFERENCES "GiftAsset"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftInstance" ADD CONSTRAINT "GiftInstance_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftInstance" ADD CONSTRAINT "GiftInstance_giftAssetId_fkey" FOREIGN KEY ("giftAssetId") REFERENCES "GiftAsset"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
