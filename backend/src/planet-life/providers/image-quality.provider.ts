import type { EventFacts } from './event-text-gen.provider';
import type { GeneratedEventImage } from './event-image-gen.provider';
import type { HomeGenerationContext } from './home-context';

export const IMAGE_QUALITY_PROVIDER = 'IMAGE_QUALITY_PROVIDER';

export interface ImageQualityCheckInput {
  image: GeneratedEventImage;
  facts: EventFacts;
  hasGift: boolean;
  // Present only for a HOME_BASE event — lets a future real provider check
  // World/Home Consistency (does this still look like the established
  // home?) in addition to identity/scene/gift/bad-image checks. The very
  // first anchor-establishing event has visualSnapshot but no
  // anchorImageUrl yet, so that check can only compare against
  // visualSnapshot's description, not a prior image.
  home?: HomeGenerationContext;
}

export interface QualityCheckResult {
  pass: boolean;
  reason?: string;
}

// Checks identity consistency, scene correctness, gift presence (when
// hasGift), general "bad image" artifacts, and — only when `home` is
// present — World/Home Consistency. Swappable behind
// PLANET_LIFE_IMAGE_QUALITY_PROVIDER — see planet-life.module.ts.
export interface ImageQualityProvider {
  check(input: ImageQualityCheckInput): Promise<QualityCheckResult>;
}
