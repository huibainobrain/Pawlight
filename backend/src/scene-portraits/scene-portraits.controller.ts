import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ScenePortraitsService } from './scene-portraits.service';
import { SCENE_TEXT_MAX_LENGTH } from './scene-portraits.constants';

class StartScenePortraitDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(SCENE_TEXT_MAX_LENGTH)
  sceneText: string;
}

class SelectCandidateDto {
  @IsString()
  @IsNotEmpty()
  candidateId: string;
}

@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class ScenePortraitsController {
  constructor(private readonly scenePortraitsService: ScenePortraitsService) {}

  @Post('pets/:petId/scene-portraits')
  start(
    @CurrentUser() user: { id: string },
    @Param('petId') petId: string,
    @Body() dto: StartScenePortraitDto,
  ) {
    return this.scenePortraitsService.startJob(user.id, petId, dto.sceneText);
  }

  @Get('scene-portraits/:jobId')
  getJob(@CurrentUser() user: { id: string }, @Param('jobId') jobId: string) {
    return this.scenePortraitsService.getJob(user.id, jobId);
  }

  @Post('scene-portraits/:jobId/select')
  select(
    @CurrentUser() user: { id: string },
    @Param('jobId') jobId: string,
    @Body() dto: SelectCandidateDto,
  ) {
    return this.scenePortraitsService.selectCandidate(user.id, jobId, dto.candidateId);
  }

  @Post('pets/:petId/observation-window/revert')
  revert(@CurrentUser() user: { id: string }, @Param('petId') petId: string) {
    return this.scenePortraitsService.revertObservationWindow(user.id, petId);
  }
}
