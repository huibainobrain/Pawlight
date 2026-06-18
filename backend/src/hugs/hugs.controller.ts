import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CreateHugDto, HugsService } from './hugs.service';

@Controller('api/v1')
export class HugsController {
  constructor(private hugsService: HugsService) {}

  // Public: H5 visitors send hugs via share slug
  @Post('shares/:slug/hugs')
  create(@Param('slug') slug: string, @Body() dto: CreateHugDto) {
    return this.hugsService.create(slug, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('pets/:petId/hugs')
  findAll(@CurrentUser() user: { id: string }, @Param('petId') petId: string) {
    return this.hugsService.findByPet(user.id, petId);
  }
}
