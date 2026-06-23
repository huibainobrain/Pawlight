import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Idempotent seed matching the V1 schema:
// - account-level Entitlement (one per user)
// - Photo.type MAIN vs ALBUM
// - Letter.title, Hug.visitorFingerprint
async function main() {
  const userId = 'seed_user_1';
  const petId = 'seed_pet_1';
  const shareId = 'seed_share_1';
  const mainPhotoId = 'seed_photo_main';

  // User
  const user = await prisma.user.upsert({
    where: { id: userId },
    update: {},
    create: {
      id: userId,
      appleUserId: 'seed_apple_user_1',
      email: 'seed@example.com',
      nickname: '示例用户',
    },
  });

  // Account-level entitlement (FREE).
  await prisma.entitlement.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      tier: 'FREE',
      photoLimit: 9,
      mailboxEnabled: false,
    },
  });

  // Pet
  const pet = await prisma.pet.upsert({
    where: { id: petId },
    update: {},
    create: {
      id: petId,
      userId: user.id,
      name: '豆豆',
      type: 'CAT',
      bornOn: '2015-04-01',
      leftOn: '2024-11-20',
      story: '豆豆陪伴了我九年，是家里最温柔的存在。',
      memorialSentence: '愿你在另一个世界继续晒太阳。',
    },
  });

  // Main photo (avatar) — type MAIN, not counted in album quota.
  await prisma.photo.upsert({
    where: { id: mainPhotoId },
    update: {},
    create: {
      id: mainPhotoId,
      petId: pet.id,
      type: 'MAIN',
      r2Key: 'pets/seed_pet_1/main.jpg',
      r2Url: 'https://example.com/pets/seed_pet_1/main.jpg',
      sortOrder: 0,
    },
  });

  // Point the pet at its main photo.
  await prisma.pet.update({
    where: { id: pet.id },
    data: { mainPhotoId },
  });

  // A couple of album photos — type ALBUM, counted in quota.
  for (let i = 1; i <= 2; i++) {
    const id = `seed_photo_album_${i}`;
    await prisma.photo.upsert({
      where: { id },
      update: {},
      create: {
        id,
        petId: pet.id,
        type: 'ALBUM',
        r2Key: `pets/seed_pet_1/album_${i}.jpg`,
        r2Url: `https://example.com/pets/seed_pet_1/album_${i}.jpg`,
        sortOrder: i,
      },
    });
  }

  // Share
  await prisma.share.upsert({
    where: { id: shareId },
    update: {},
    create: {
      id: shareId,
      petId: pet.id,
      slug: 'seeddoudou',
      visibility: 'LINK',
      hugEnabled: true,
    },
  });

  console.log('Seed complete:', {
    user: user.id,
    pet: pet.id,
    share: shareId,
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
