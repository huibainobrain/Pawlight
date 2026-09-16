-- CreateEnum
CREATE TYPE "ScenePortraitJobStatus" AS ENUM ('QUEUED', 'GENERATING_IMAGE', 'CANDIDATES_READY', 'GENERATING_VIDEO', 'DONE', 'FAILED');

-- AlterTable
ALTER TABLE "Pet" ADD COLUMN     "observationVideoJobId" TEXT,
ADD COLUMN     "observationVideoKey" TEXT,
ADD COLUMN     "observationVideoUrl" TEXT;

-- CreateTable
CREATE TABLE "ScenePortraitJob" (
    "id" TEXT NOT NULL,
    "petId" TEXT NOT NULL,
    "sceneText" TEXT NOT NULL,
    "status" "ScenePortraitJobStatus" NOT NULL DEFAULT 'QUEUED',
    "selectedCandidateId" TEXT,
    "videoR2Key" TEXT,
    "videoR2Url" TEXT,
    "errorCode" TEXT,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ScenePortraitJob_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ScenePortraitCandidate" (
    "id" TEXT NOT NULL,
    "jobId" TEXT NOT NULL,
    "r2Key" TEXT NOT NULL,
    "r2Url" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ScenePortraitCandidate_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ScenePortraitJob_petId_createdAt_idx" ON "ScenePortraitJob"("petId" ASC, "createdAt" ASC);

-- CreateIndex
CREATE INDEX "ScenePortraitCandidate_jobId_idx" ON "ScenePortraitCandidate"("jobId" ASC);

-- AddForeignKey
ALTER TABLE "ScenePortraitJob" ADD CONSTRAINT "ScenePortraitJob_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScenePortraitCandidate" ADD CONSTRAINT "ScenePortraitCandidate_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "ScenePortraitJob"("id") ON DELETE CASCADE ON UPDATE CASCADE;
