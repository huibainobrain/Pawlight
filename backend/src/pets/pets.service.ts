import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PetType } from '@prisma/client';
import { randomBytes } from 'crypto';

export class CreatePetDto {
  name: string;
  type: PetType;
}

export class UpdatePetDto {
  name?: string;
  type?: PetType;
  arrivedOn?: string;
  bornOn?: string;
  leftOn?: string;
  story?: string;
  memorialSentence?: string;
  mainPhotoId?: string;
}

@Injectable()
export class PetsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreatePetDto) {
    const slug = randomBytes(6).toString('hex');
    const pet = await this.prisma.pet.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        entitlement: { create: { tier: 'FREE' } },
        share: { create: { slug } },
      },
      include: { entitlement: true, share: true },
    });
    return pet;
  }

  async findMine(userId: string) {
    return this.prisma.pet.findMany({
      where: { userId },
      include: { entitlement: true, share: true, photos: { take: 1, orderBy: { sortOrder: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(userId: string, petId: string, dto: UpdatePetDto) {
    await this.assertOwner(userId, petId);
    return this.prisma.pet.update({
      where: { id: petId },
      data: dto,
    });
  }

  private async assertOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.userId !== userId) throw new ForbiddenException();
    return pet;
  }
}
