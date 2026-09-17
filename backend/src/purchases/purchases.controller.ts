import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PurchasesService } from './purchases.service';
import { IsString, IsNotEmpty } from 'class-validator';

class VerifyPurchaseDto {
  @IsString()
  @IsNotEmpty()
  jws_token: string;
}

@Controller('api/v1/purchases')
@UseGuards(JwtAuthGuard)
export class PurchasesController {
  constructor(private readonly purchasesService: PurchasesService) {}

  @Post('verify')
  verify(@CurrentUser() user: { id: string }, @Body() dto: VerifyPurchaseDto) {
    return this.purchasesService.verifyAndApply(user.id, dto.jws_token);
  }
}
