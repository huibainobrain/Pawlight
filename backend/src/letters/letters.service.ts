import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { IsOptional, IsString } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';

export class UpsertLetterDto {
  @IsString() @IsOptional() title?: string;

  @IsString()
  content: string;
}

@Injectable()
export class LettersService {
  constructor(private prisma: PrismaService) {}

  async findByPet(userId: string, petId: string) {
    await this.assertMailboxOwner(userId, petId);
    // title is selected implicitly with the full record.
    return this.prisma.letter.findMany({
      where: { petId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async upsert(
    userId: string,
    petId: string,
    letterId: string | null,
    dto: UpsertLetterDto,
  ) {
    await this.assertMailboxOwner(userId, petId);
    if (letterId) {
      // Verify the letter belongs to this pet before updating.
      const existing = await this.prisma.letter.findUnique({
        where: { id: letterId },
      });
      if (!existing || existing.petId !== petId) throw new NotFoundException();
      return this.prisma.letter.update({
        where: { id: letterId },
        data: { title: dto.title, content: dto.content },
      });
    }
    return this.prisma.letter.create({
      data: { petId, title: dto.title, content: dto.content },
    });
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

  // Mailbox (天堂信箱) access is an account-level entitlement, read from the
  // user's entitlement — not the pet's.
  private async assertMailboxOwner(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new ForbiddenException();

    const entitlement = await this.prisma.entitlement.findUnique({
      where: { userId },
    });
    const mailboxEnabled =
      entitlement?.mailboxEnabled === true || entitlement?.tier === 'PAID';
    if (!mailboxEnabled) {
      throw new ForbiddenException({
        code: 'MAILBOX_NOT_ENABLED',
        message: 'Requires paid tier',
      });
    }
    return pet;
  }
}
