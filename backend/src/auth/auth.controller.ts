import {
  Body,
  Controller,
  Delete,
  Headers,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

class LoginDto {
  @IsString()
  identity_token: string;
}

@Controller('api/v1/auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.loginWithApple(dto.identity_token);
  }

  @Post('debug-login')
  debugLogin(@Headers('x-debug-secret') secret: string) {
    return this.authService.debugLogin(secret);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('me')
  async deleteMe(@CurrentUser() user: { id: string }) {
    await this.authService.deleteAccount(user.id);
    return { status: 'success' };
  }
}
