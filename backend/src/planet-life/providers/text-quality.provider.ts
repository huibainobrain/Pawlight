import type { EventFacts } from './event-text-gen.provider';
import type { GeneratedEventText } from './event-text-gen.provider';
import type { QualityCheckResult } from './image-quality.provider';

export const TEXT_QUALITY_PROVIDER = 'TEXT_QUALITY_PROVIDER';

export interface TextQualityCheckInput {
  text: GeneratedEventText;
  facts: EventFacts;
}

// Checks fact-consistency, no first-person/simulated-personality framing, no
// invented facts beyond what `facts` states, no real-world assertions.
// Swappable behind PLANET_LIFE_TEXT_QUALITY_PROVIDER — see planet-life.module.ts.
export interface TextQualityProvider {
  check(input: TextQualityCheckInput): Promise<QualityCheckResult>;
}
