import {
  Controller, Delete, Get, Param, Post,
  UploadedFile, UseGuards, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PhotosService } from './photos.service';

@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class PhotosController {
  constructor(private photosService: PhotosService) {}

  @Post('pets/:petId/photos')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  upload(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.photosService.upload(user.id, petId, file);
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
