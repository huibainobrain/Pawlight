import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export class CreateHugDto {
  visitorName?: string;
  message?: string;
}

@Injectable()
export class HugsService {
  constructor(private prisma: PrismaService) {}

  // Public: called from H5 by visitors
  async create(slug: string, dto: CreateHugDto) {
    const share = await this.prisma.share.findUnique({ where: { slug } });
    if (!share) throw new NotFoundException('Share not found');
    if (!share.hugEnabled) throw new BadRequestException('Hugs are disabled for this memorial');

    return this.prisma.hug.create({
      data: { shareId: share.id, ...dto },
    });
  }

  async findByPet(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
      include: { share: { include: { hugs: { orderBy: { createdAt: 'desc' } } } } },
    });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new NotFoundException();
    return pet.share?.hugs ?? [];
  }
}
