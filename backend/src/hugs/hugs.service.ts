import { Injectable, NotFoundException } from '@nestjs/common';
import { IsOptional, IsString } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

export class CreateHugDto {
  // Client-generated UUID persisted in H5 localStorage; used for dedup.
  @IsString()
  visitorFingerprint: string;

  @IsString() @IsOptional() visitorName?: string;
  @IsString() @IsOptional() message?: string;
}

export type HugStatus =
  | 'success'
  | 'already_hugged'
  | 'not_found'
  | 'private_or_unavailable'
  | 'hug_disabled';

@Injectable()
export class HugsService {
  constructor(private prisma: PrismaService) {}

  // Public: called from H5 by visitors. Always returns a consistent
  // { status, ... } object instead of throwing for business outcomes.
  async create(
    slug: string,
    dto: CreateHugDto,
  ): Promise<{ status: HugStatus; hug?: unknown; hugCount?: number }> {
    const share = await this.prisma.share.findUnique({
      where: { slug },
      include: { pet: true },
    });

    // Share or its pet missing.
    if (!share || !share.pet) {
      return { status: 'not_found' };
    }
    if (share.visibility === 'PRIVATE') {
      return { status: 'private_or_unavailable' };
    }
    if (share.hugEnabled === false) {
      return { status: 'hug_disabled' };
    }

    // Dedup by (shareId, visitorFingerprint).
    const existing = await this.prisma.hug.findFirst({
      where: { shareId: share.id, visitorFingerprint: dto.visitorFingerprint },
    });
    if (existing) {
      return { status: 'already_hugged' };
    }

    try {
      const hug = await this.prisma.hug.create({
        data: {
          shareId: share.id,
          visitorFingerprint: dto.visitorFingerprint,
          visitorName: dto.visitorName,
          message: dto.message,
        },
      });
      const hugCount = await this.prisma.hug.count({
        where: { shareId: share.id },
      });
      return { status: 'success', hug, hugCount };
    } catch (err) {
      // Concurrent request hit the unique constraint first — treat as dedup.
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        return { status: 'already_hugged' };
      }
      throw err;
    }
  }

  async findByPet(userId: string, petId: string) {
    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
      include: {
        share: { include: { hugs: { orderBy: { createdAt: 'desc' } } } },
      },
    });
    if (!pet) throw new NotFoundException();
    if (pet.userId !== userId) throw new NotFoundException();
    return pet.share?.hugs ?? [];
  }
}
