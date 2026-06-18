import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export class UpsertLetterDto {
  content: string;
}

@Injectable()
export class LettersService {
  constructor(private prisma: PrismaService) {}

  async findByPet(userId: string, petId: string) {
    await this.assertPaidOwner(userId, petId);
    return this.prisma.letter.findMany({
      where: { petId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async upsert(userId: string, petId: string, letterId: string | null, dto: UpsertLetterDto) {
    await this.assertPaidOwner(userId, petId);
    if (letterId) {
      return this.prisma.letter.update({ where: { id: letterId }, data: dto });
    }
    return this.prisma.letter.create({ data: { petId, ...dto } });
  }

  async remove(userId: string, letterId: string) {
    const letter = await this.prisma.letter.findUnique({
      where: { id: letterId },
      include: { pet: true },
    });
    if (!letter) throw new NotFoundException();
    if (letter.pet.userId !== userId) throw new ForbiddenException();
    return this.prisma.letter.delete({ where: { id: letterId } });
  }

  private async assertPaidOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
      include: { entitlement: true },
    });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new ForbiddenException();
    if (pet.entitlement?.tier !== 'PAID') throw new ForbiddenException('Requires paid tier');
    return pet;
  }
}
