import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { LettersService, UpsertLetterDto } from './letters.service';

@Controller('api/v1/pets/:petId/letters')
@UseGuards(JwtAuthGuard)
export class LettersController {
  constructor(private lettersService: LettersService) {}

  @Get()
  findAll(@CurrentUser() user: { id: string }, @Param('petId') petId: string) {
    return this.lettersService.findByPet(user.id, petId);
  }

  @Post()
  create(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: UpsertLetterDto,
  ) {
    return this.lettersService.upsert(user.id, petId, null, dto);
  }

  @Put(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Param('id') id: string,
    @Body() dto: UpsertLetterDto,
  ) {
    return this.lettersService.upsert(user.id, petId, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.lettersService.remove(user.id, id);
  }
}
