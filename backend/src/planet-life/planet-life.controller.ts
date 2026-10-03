import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PlanetLifeService } from './planet-life.service';
import { GiftsService } from './gifts.service';

class EnableStarLifeDto {
  @IsBoolean()
  notifyOnNewEvent: boolean;
}

class UpdateStarLifeSettingsDto {
  @IsBoolean()
  @IsOptional()
  notifyOnNewEvent?: boolean;

  @IsBoolean()
  @IsOptional()
  paused?: boolean;
}

class DebugSimulatePurchaseDto {
  @IsString()
  giftAssetKey: string;
}

@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class PlanetLifeController {
  constructor(
    private readonly planetLifeService: PlanetLifeService,
    private readonly giftsService: GiftsService,
  ) {}

  @Get('pets/:petId/planet-life')
  getStatus(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    return this.planetLifeService.getStatus(user.id, petId);
  }

  @Post('pets/:petId/planet-life/enable')
  enable(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: EnableStarLifeDto,
  ) {
    return this.planetLifeService.enable(user.id, petId, dto.notifyOnNewEvent);
  }

  @Patch('pets/:petId/planet-life/settings')
  updateSettings(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: UpdateStarLifeSettingsDto,
  ) {
    return this.planetLifeService.updateSettings(user.id, petId, dto);
  }

  @Get('pets/:petId/planet-life/events')
  listEvents(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    return this.planetLifeService.listEvents(user.id, petId);
  }

  @Post('pets/:petId/planet-life/events/:eventId/read')
  markRead(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Param('eventId') eventId: string,
  ) {
    return this.planetLifeService.markRead(user.id, petId, eventId);
  }

  @Post('pets/:petId/planet-life/events/:eventId/bad-case')
  markBadCase(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Param('eventId') eventId: string,
  ) {
    return this.planetLifeService.markBadCase(user.id, petId, eventId);
  }

  @Get('pets/:petId/gifts')
  listGifts(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    return this.giftsService.listAssets(user.id, petId);
  }

  // ── DEBUG-only (behind X-Debug-Secret, same mechanism as
  // AuthService.debugLogin — not a #if DEBUG compile flag, since this is a
  // backend; see AGENTS.md §6's "no silent fallback" principle applied here
  // as "no silent secret bypass"). Backs the iOS "测试：模拟星球来信" /
  // "测试：真实生成一次" DEBUG tools. ──────────────────────────────────────

  @Post('debug/pets/:petId/planet-life/fake-trigger')
  debugFakeTrigger(
    @Headers('x-debug-secret') secret: string,
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    this.assertDebugSecret(secret);
    return this.planetLifeService.debugForceTick(user.id, petId);
  }

  @Post('debug/pets/:petId/planet-life/live-trigger')
  debugLiveTrigger(
    @Headers('x-debug-secret') secret: string,
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    this.assertDebugSecret(secret);
    return this.planetLifeService.debugLiveTrigger(user.id, petId);
  }

  @Post('debug/pets/:petId/gifts/simulate-purchase')
  debugSimulatePurchase(
    @Headers('x-debug-secret') secret: string,
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: DebugSimulatePurchaseDto,
  ) {
    this.assertDebugSecret(secret);
    return this.giftsService.simulateDebugPurchase(
      user.id,
      petId,
      dto.giftAssetKey,
    );
  }

  @Post('debug/pets/:petId/planet-life/reset')
  debugReset(
    @Headers('x-debug-secret') secret: string,
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
  ) {
    this.assertDebugSecret(secret);
    return this.planetLifeService.debugReset(user.id, petId);
  }

  private assertDebugSecret(secret: string | undefined) {
    if (!process.env.DEBUG_SECRET || secret !== process.env.DEBUG_SECRET) {
      throw new ForbiddenException('Debug endpoint disabled');
    }
  }
}
