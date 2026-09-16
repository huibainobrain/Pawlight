import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { PetsModule } from './pets/pets.module';
import { PhotosModule } from './photos/photos.module';
import { SharesModule } from './shares/shares.module';
import { HugsModule } from './hugs/hugs.module';
import { LettersModule } from './letters/letters.module';
import { PurchasesModule } from './purchases/purchases.module';
import { ScenePortraitsModule } from './scene-portraits/scene-portraits.module';
import { validateRequiredEnv } from './config/env.validation';

validateRequiredEnv();

@Module({
  controllers: [AppController],
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    PetsModule,
    PhotosModule,
    SharesModule,
    HugsModule,
    LettersModule,
    PurchasesModule,
    ScenePortraitsModule,
  ],
})
export class AppModule {}
