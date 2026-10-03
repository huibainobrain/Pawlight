import type { EventFacts } from './event-text-gen.provider';
import type { GeneratedEventImage } from './event-image-gen.provider';

export const IMAGE_QUALITY_PROVIDER = 'IMAGE_QUALITY_PROVIDER';

export interface ImageQualityCheckInput {
  image: GeneratedEventImage;
  facts: EventFacts;
  hasGift: boolean;
}

export interface QualityCheckResult {
  pass: boolean;
  reason?: string;
}

// Checks identity consistency, scene correctness, gift presence (when
// hasGift), and general "bad image" artifacts. Swappable behind
// PLANET_LIFE_IMAGE_QUALITY_PROVIDER — see planet-life.module.ts.
export interface ImageQualityProvider {
  check(input: ImageQualityCheckInput): Promise<QualityCheckResult>;
}
