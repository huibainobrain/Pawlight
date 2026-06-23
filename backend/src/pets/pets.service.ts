import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { PetType } from '@prisma/client';
import { randomBytes } from 'crypto';
import { albumPhotoLimit } from '../common/entitlement.util';

export class CreatePetDto {
  @IsString()
  name: string;

  @IsEnum(PetType)
  type: PetType;
}

export class UpdatePetDto {
  @IsString() @IsOptional() name?: string;
  @IsEnum(PetType) @IsOptional() type?: PetType;
  @IsString() @IsOptional() arrivedOn?: string;
  @IsString() @IsOptional() bornOn?: string;
  @IsString() @IsOptional() leftOn?: string;
  @IsString() @IsOptional() story?: string;
  @IsString() @IsOptional() memorialSentence?: string;
  @IsString() @IsOptional() mainPhotoId?: string;
}

@Injectable()
export class PetsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreatePetDto) {
    // V1: a user may only own a single pet.
    const existing = await this.prisma.pet.count({ where: { userId } });
    if (existing > 0) {
      throw new ConflictException({
        code: 'PET_LIMIT_REACHED',
        message: 'V1阶段暂时只支持创建一只宠物',
      });
    }

    // Entitlement is account-level, created at login — not per pet.
    const slug = randomBytes(6).toString('hex');
    const pet = await this.prisma.pet.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        share: { create: { slug } },
      },
      include: { share: true },
    });
    return this.withQuota(userId, pet);
  }

  async findMine(userId: string) {
    const pets = await this.prisma.pet.findMany({
      where: { userId },
      include: {
        share: true,
        // Include ALL photos (MAIN + ALBUM) so the client can display the
        // main photo in the header and album thumbnails in the grid.
        photos: { orderBy: { sortOrder: 'asc' } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const entitlement = await this.prisma.entitlement.findUnique({
      where: { userId },
    });
    const limit = albumPhotoLimit(entitlement);

    return Promise.all(
      pets.map(async (pet) => {
        const albumPhotoCount = await this.prisma.photo.count({
          where: { petId: pet.id, type: 'ALBUM' },
        });
        return {
          ...pet,
          albumPhotoCount,
          albumPhotoLimit: limit,
          mailboxEnabled: entitlement?.mailboxEnabled ?? false,
        };
      }),
    );
  }

  async update(userId: string, petId: string, dto: UpdatePetDto) {
    await this.assertOwner(userId, petId);
    const pet = await this.prisma.pet.update({
      where: { id: petId },
      data: dto,
      include: { share: true },
    });
    return this.withQuota(userId, pet);
  }

  private async withQuota<T extends { id: string }>(userId: string, pet: T) {
    const entitlement = await this.prisma.entitlement.findUnique({
      where: { userId },
    });
    const albumPhotoCount = await this.prisma.photo.count({
      where: { petId: pet.id, type: 'ALBUM' },
    });
    return {
      ...pet,
      albumPhotoCount,
      albumPhotoLimit: albumPhotoLimit(entitlement),
      mailboxEnabled: entitlement?.mailboxEnabled ?? false,
    };
  }

  private async assertOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();
    return pet;
  }
}
