import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { IsEnum, IsOptional } from 'class-validator';
import { PhotoType } from '@prisma/client';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PhotosService } from './photos.service';

export class UploadPhotoDto {
  // Defaults to ALBUM in the service when omitted. The pet-creation main-photo
  // upload passes type=MAIN.
  @IsEnum(PhotoType) @IsOptional() type?: PhotoType;
}

@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class PhotosController {
  constructor(private photosService: PhotosService) {}

  @Post('pets/:petId/photos')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }),
  )
  upload(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadPhotoDto,
  ) {
    return this.photosService.upload(user.id, petId, file, dto.type ?? 'ALBUM');
  }

  @Get('pets/:petId/photos')
  findAll(@CurrentUser() user: { id: string }, @Param('petId') petId: string) {
    return this.photosService.findByPet(user.id, petId);
  }

  @Delete('photos/:id')
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.photosService.remove(user.id, id);
  }
}
