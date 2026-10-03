import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { StorageModule } from '../storage/storage.module';
import { PlanetLifeController } from './planet-life.controller';
import { PlanetLifeService } from './planet-life.service';
import { PlanetEventGenerationService } from './planet-event-generation.service';
import { PlanetLifeScheduler } from './planet-life.scheduler';
import { GiftsService } from './gifts.service';
import { EVENT_TEXT_GEN_PROVIDER } from './providers/event-text-gen.provider';
import type { EventTextGenProvider as EventTextGenProviderImpl } from './providers/event-text-gen.provider';
import { EVENT_IMAGE_GEN_PROVIDER } from './providers/event-image-gen.provider';
import type { EventImageGenProvider as EventImageGenProviderImpl } from './providers/event-image-gen.provider';
import { IMAGE_QUALITY_PROVIDER } from './providers/image-quality.provider';
import type { ImageQualityProvider as ImageQualityProviderImpl } from './providers/image-quality.provider';
import { TEXT_QUALITY_PROVIDER } from './providers/text-quality.provider';
import type { TextQualityProvider as TextQualityProviderImpl } from './providers/text-quality.provider';
import { FakeEventTextGenProvider } from './providers/fake-event-text-gen.provider';
import { FakeEventImageGenProvider } from './providers/fake-event-image-gen.provider';
import { FakeImageQualityProvider } from './providers/fake-image-quality.provider';
import { FakeTextQualityProvider } from './providers/fake-text-quality.provider';

// Same explicit-registry-with-throw-on-unknown pattern as
// scene-portraits.module.ts (AGENTS.md §6). Unlike scene-portraits, there is
// no real vendor yet for any of these four — only 'fake' is registered, so
// ANY other value (including an unset var pointing at a typo'd future vendor
// name) fails app startup rather than silently resolving to fake.
const TEXT_PROVIDERS: Record<string, new () => EventTextGenProviderImpl> = {
  fake: FakeEventTextGenProvider,
};
const IMAGE_PROVIDERS: Record<string, new () => EventImageGenProviderImpl> = {
  fake: FakeEventImageGenProvider,
};
const IMAGE_QUALITY_PROVIDERS: Record<
  string,
  new () => ImageQualityProviderImpl
> = {
  fake: FakeImageQualityProvider,
};
const TEXT_QUALITY_PROVIDERS: Record<
  string,
  new () => TextQualityProviderImpl
> = {
  fake: FakeTextQualityProvider,
};

function resolve<T>(
  envVar: string,
  registry: Record<string, new () => T>,
): new () => T {
  const name = process.env[envVar] ?? 'fake';
  const cls = registry[name];
  if (!cls) {
    throw new Error(
      `Unknown ${envVar} "${name}". Valid values: ${Object.keys(registry).join(', ')}`,
    );
  }
  return cls;
}

@Module({
  imports: [StorageModule, ScheduleModule.forRoot()],
  controllers: [PlanetLifeController],
  providers: [
    PlanetLifeService,
    PlanetEventGenerationService,
    PlanetLifeScheduler,
    GiftsService,
    {
      provide: EVENT_TEXT_GEN_PROVIDER,
      useClass: resolve('PLANET_LIFE_TEXT_PROVIDER', TEXT_PROVIDERS),
    },
    {
      provide: EVENT_IMAGE_GEN_PROVIDER,
      useClass: resolve('PLANET_LIFE_IMAGE_PROVIDER', IMAGE_PROVIDERS),
    },
    {
      provide: IMAGE_QUALITY_PROVIDER,
      useClass: resolve(
        'PLANET_LIFE_IMAGE_QUALITY_PROVIDER',
        IMAGE_QUALITY_PROVIDERS,
      ),
    },
    {
      provide: TEXT_QUALITY_PROVIDER,
      useClass: resolve(
        'PLANET_LIFE_TEXT_QUALITY_PROVIDER',
        TEXT_QUALITY_PROVIDERS,
      ),
    },
  ],
  exports: [GiftsService, PlanetLifeService],
})
export class PlanetLifeModule {}
