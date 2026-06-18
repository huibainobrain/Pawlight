import { Module } from '@nestjs/common';
import { HugsController } from './hugs.controller';
import { HugsService } from './hugs.service';

@Module({
  controllers: [HugsController],
  providers: [HugsService],
})
export class HugsModule {}
