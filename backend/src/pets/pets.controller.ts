import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CreatePetDto, PetsService, UpdatePetDto } from './pets.service';

@Controller('api/v1/pets')
@UseGuards(JwtAuthGuard)
export class PetsController {
  constructor(private petsService: PetsService) {}

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreatePetDto) {
    return this.petsService.create(user.id, dto);
  }

  @Get('mine')
  findMine(@CurrentUser() user: { id: string }) {
    return this.petsService.findMine(user.id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdatePetDto,
  ) {
    return this.petsService.update(user.id, id, dto);
  }
}
