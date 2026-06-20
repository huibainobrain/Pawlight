import { Body, Controller, Headers, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { IsString } from 'class-validator';

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
}
