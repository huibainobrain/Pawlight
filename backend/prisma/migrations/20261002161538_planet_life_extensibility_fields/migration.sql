-- AlterTable
ALTER TABLE "EventTemplate" ADD COLUMN     "category" TEXT;

-- AlterTable
ALTER TABLE "GiftAsset" ADD COLUMN     "actionCompatibility" JSONB,
ADD COLUMN     "category" TEXT;
