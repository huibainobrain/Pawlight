import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { randomBytes } from 'crypto';

@Injectable()
export class PhotosService {
  private s3: S3Client;
  private bucket = process.env.R2_BUCKET!;
  private publicUrl = process.env.R2_PUBLIC_URL!;

  constructor(private prisma: PrismaService) {
    this.s3 = new S3Client({
      region: 'auto',
      endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID!,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
      },
    });
  }

  async upload(userId: string, petId: string, file: Express.Multer.File) {
    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
      include: { entitlement: true, _count: { select: { photos: true } } },
    });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();

    const limit = pet.entitlement?.tier === 'PAID' ? 50 : 9;
    if (pet._count.photos >= limit) {
      throw new BadRequestException(`Photo quota reached (${limit})`);
    }

    const ext = file.originalname.split('.').pop() ?? 'jpg';
    const key = `pets/${petId}/${randomBytes(8).toString('hex')}.${ext}`;

    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );

    const r2Url = `${this.publicUrl}/${key}`;
    const photo = await this.prisma.photo.create({
      data: { petId, r2Key: key, r2Url },
    });

    return photo;
  }

  async findByPet(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new ForbiddenException();
    return this.prisma.photo.findMany({
      where: { petId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async remove(userId: string, photoId: string) {
    const photo = await this.prisma.photo.findUnique({
      where: { id: photoId },
      include: { pet: true },
    });
    if (!photo) throw new NotFoundException();
    if (photo.pet.userId !== userId) throw new ForbiddenException();

    await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: photo.r2Key }));
    await this.prisma.photo.delete({ where: { id: photoId } });
  }
}
