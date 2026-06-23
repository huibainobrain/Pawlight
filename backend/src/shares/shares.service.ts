import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
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

  // Public: used by the H5 memorial page. Returns ONLY public-safe fields.
  // Never returns letters, the full hug list, owner account info, or purchase
  // info. PRIVATE shares are rejected with HTTP 403.
  async findBySlug(slug: string, visitorFingerprint?: string) {
    const share = await this.prisma.share.findUnique({
      where: { slug },
      include: {
        pet: {
          include: {
            photos: { orderBy: { sortOrder: 'asc' } },
          },
        },
        _count: { select: { hugs: true } },
      },
    });

    if (!share || !share.pet) {
      throw new NotFoundException({ status: 'not_found' });
    }
    if (share.visibility === 'PRIVATE') {
      throw new ForbiddenException({ status: 'private_or_unavailable' });
    }

    const pet = share.pet;
    const albumPhotos = pet.photos
      .filter((p) => p.type === 'ALBUM')
      .map((p) => ({ id: p.id, url: p.r2Url, caption: p.caption }));

    // Resolve the main photo from the explicit mainPhotoId, falling back to any
    // MAIN-typed photo.
    const mainPhotoRecord =
      pet.photos.find((p) => p.id === pet.mainPhotoId) ??
      pet.photos.find((p) => p.type === 'MAIN');
    const mainPhoto = mainPhotoRecord?.r2Url ?? null;

    let viewerHasHugged = false;
    if (visitorFingerprint) {
      const hug = await this.prisma.hug.findFirst({
        where: { shareId: share.id, visitorFingerprint },
        select: { id: true },
      });
      viewerHasHugged = !!hug;
    }

    return {
      status: 'ok' as const,
      slug: share.slug,
      visibility: share.visibility,
      hugEnabled: share.hugEnabled,
      petName: pet.name,
      petType: pet.type,
      mainPhoto,
      memorialSentence: pet.memorialSentence,
      story: pet.story,
      arrivedOn: pet.arrivedOn,
      bornOn: pet.bornOn,
      leftOn: pet.leftOn,
      albumPhotos,
      hugCount: share._count.hugs,
      viewerHasHugged,
    };
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
