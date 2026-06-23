import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SharesService, UpdateShareDto } from './shares.service';

@Controller('api/v1')
export class SharesController {
  constructor(private sharesService: SharesService) {}

  // Public endpoint — no auth. Optional visitorFingerprint resolves
  // viewerHasHugged for the H5 page.
  @Get('shares/:slug')
  findBySlug(
    @Param('slug') slug: string,
    @Query('visitorFingerprint') visitorFingerprint?: string,
  ) {
    return this.sharesService.findBySlug(slug, visitorFingerprint);
  }

  @UseGuards(JwtAuthGuard)
  @Get('pets/:petId/share')
  findByPet(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    return this.sharesService.findByPet(user.id, petId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('pets/:petId/share')
  update(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: UpdateShareDto,
  ) {
    return this.sharesService.update(user.id, petId, dto);
  }
}
