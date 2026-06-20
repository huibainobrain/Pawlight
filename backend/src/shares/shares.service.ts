import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { Visibility } from '@prisma/client';

export class UpdateShareDto {
  @IsEnum(Visibility) @IsOptional() visibility?: Visibility;
  @IsBoolean() @IsOptional() hugEnabled?: boolean;
}

@Injectable()
export class SharesService {
  constructor(private prisma: PrismaService) {}

  // Public: used by H5
  async findBySlug(slug: string) {
    const share = await this.prisma.share.findUnique({
      where: { slug },
      include: {
        pet: {
          include: {
            photos: { orderBy: { sortOrder: 'asc' } },
            entitlement: true,
          },
        },
      },
    });
    if (!share) throw new NotFoundException('Share not found');
    if (share.visibility === 'PRIVATE') throw new ForbiddenException('This memorial is private');
    return share;
  }

  async update(userId: string, petId: string, dto: UpdateShareDto) {
    const share = await this.prisma.share.findUnique({
      where: { petId },
      include: { pet: true },
    });
    if (!share) throw new NotFoundException();
    if (share.pet.userId !== userId) throw new ForbiddenException();

    return this.prisma.share.update({ where: { petId }, data: dto });
  }

  async findByPet(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new ForbiddenException();
    return this.prisma.share.findUnique({ where: { petId } });
  }
}
