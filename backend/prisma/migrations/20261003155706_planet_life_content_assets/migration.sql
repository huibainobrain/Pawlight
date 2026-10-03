/*
  Warnings:

  - You are about to drop the column `actionPool` on the `EventTemplate` table. All the data in the column will be lost.
  - You are about to drop the column `ambientDetailsPool` on the `EventTemplate` table. All the data in the column will be lost.
  - You are about to drop the column `atmospherePool` on the `EventTemplate` table. All the data in the column will be lost.
  - You are about to drop the column `locationPool` on the `EventTemplate` table. All the data in the column will be lost.
  - You are about to drop the column `timePool` on the `EventTemplate` table. All the data in the column will be lost.
  - Added the required column `actionKeys` to the `EventTemplate` table without a default value. This is not possible if the table is not empty.
  - Added the required column `atmosphereKeys` to the `EventTemplate` table without a default value. This is not possible if the table is not empty.
  - Added the required column `locationKeys` to the `EventTemplate` table without a default value. This is not possible if the table is not empty.
  - Added the required column `timeKeys` to the `EventTemplate` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "ContentAssetKind" AS ENUM ('TIME', 'ATMOSPHERE', 'AMBIENT_DETAIL');

-- AlterTable
ALTER TABLE "EventTemplate" DROP COLUMN "actionPool",
DROP COLUMN "ambientDetailsPool",
DROP COLUMN "atmospherePool",
DROP COLUMN "locationPool",
DROP COLUMN "timePool",
ADD COLUMN     "actionKeys" JSONB NOT NULL,
ADD COLUMN     "ambientDetailKeys" JSONB,
ADD COLUMN     "atmosphereKeys" JSONB NOT NULL,
ADD COLUMN     "locationKeys" JSONB NOT NULL,
ADD COLUMN     "timeKeys" JSONB NOT NULL;

-- CreateTable
CREATE TABLE "LocationAsset" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "nameZh" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "visualDefinition" TEXT NOT NULL,
    "imageGenPrompt" TEXT NOT NULL,
    "speciesApplicability" JSONB,
    "incompatibleActionKeys" JSONB,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LocationAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ActionAsset" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "nameZh" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "visualAction" TEXT NOT NULL,
    "speciesApplicability" JSONB,
    "incompatibleLocationKeys" JSONB,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ActionAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ContentAsset" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "kind" "ContentAssetKind" NOT NULL,
    "nameZh" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "visualDescription" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ContentAsset_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LocationAsset_key_key" ON "LocationAsset"("key");

-- CreateIndex
CREATE UNIQUE INDEX "ActionAsset_key_key" ON "ActionAsset"("key");

-- CreateIndex
CREATE UNIQUE INDEX "ContentAsset_key_key" ON "ContentAsset"("key");

-- CreateIndex
CREATE INDEX "ContentAsset_kind_idx" ON "ContentAsset"("kind");
