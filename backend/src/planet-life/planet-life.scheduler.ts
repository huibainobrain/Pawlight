import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PlanetEventGenerationService } from './planet-event-generation.service';
import { SCHEDULER_TICK_CRON } from './planet-life.constants';

// The only background-timing mechanism Planet Life needs: no queue, no
// separate worker process — this backend had zero scheduler infrastructure
// before this (confirmed: no @Cron/@Interval/queue anywhere), so this is
// intentionally the smallest viable addition, not a new subsystem.
@Injectable()
export class PlanetLifeScheduler {
  private readonly logger = new Logger(PlanetLifeScheduler.name);

  constructor(private generation: PlanetEventGenerationService) {}

  @Cron(SCHEDULER_TICK_CRON)
  async tick() {
    try {
      await this.generation.runTick();
    } catch (err) {
      this.logger.error(
        `Planet life scheduler tick failed: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }
}
