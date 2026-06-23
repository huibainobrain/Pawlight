-- CreateEnum
CREATE TYPE "PetType" AS ENUM ('CAT', 'DOG', 'OTHER');

-- CreateEnum
CREATE TYPE "Tier" AS ENUM ('FREE', 'PAID');

-- CreateEnum
CREATE TYPE "Visibility" AS ENUM ('LINK', 'PRIVATE');

-- CreateTable
CREATE TABLE "Entitlement" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "tier" "Tier" NOT NULL DEFAULT 'FREE',
    "purchaseId" TEXT,
    "expiredAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Entitlement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Hug" (
    "id" TEXT NOT NULL,
    "shareId" TEXT NOT NULL,
    "visitorName" TEXT,
    "message" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Hug_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Letter" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Letter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pet" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "PetType" NOT NULL DEFAULT 'CAT',
    "arrivedOn" TEXT,
    "bornOn" TEXT,
    "leftOn" TEXT,
    "mainPhotoId" TEXT,
    "story" TEXT,
    "memorialSentence" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Pet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Photo" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "r2Key" TEXT NOT NULL,
    "r2Url" TEXT NOT NULL,
    "caption" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Photo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Share" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "visibility" "Visibility" NOT NULL DEFAULT 'LINK',
    "hugEnabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Share_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "appleUserId" TEXT NOT NULL,
    "email" TEXT,
    "nickname" TEXT,
    "avatarUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Entitlement_petId_key" ON "Entitlement"("petId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Share_petId_key" ON "Share"("petId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Share_slug_key" ON "Share"("slug" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "User_appleUserId_key" ON "User"("appleUserId" ASC);

-- AddForeignKey
ALTER TABLE "Entitlement" ADD CONSTRAINT "Entitlement_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Hug" ADD CONSTRAINT "Hug_shareId_fkey" FOREIGN KEY ("shareId") REFERENCES "Share"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Letter" ADD CONSTRAINT "Letter_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Photo" ADD CONSTRAINT "Photo_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Share" ADD CONSTRAINT "Share_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

