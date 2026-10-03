import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { PhotosModule } from '../photos/photos.module';
import { ScenePortraitsModule } from '../scene-portraits/scene-portraits.module';
import { PlanetLifeModule } from '../planet-life/planet-life.module';
import { requireEnv } from '../config/env.validation';

@Module({
  imports: [
    PassportModule,
    JwtModule.register({
      secret: requireEnv('JWT_SECRET'),
      signOptions: { expiresIn: '365d' },
    }),
    PhotosModule,
    ScenePortraitsModule,
    PlanetLifeModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
})
export class AuthModule {}
