import type { EventFacts } from './event-text-gen.provider';

export const EVENT_IMAGE_GEN_PROVIDER = 'EVENT_IMAGE_GEN_PROVIDER';

export interface GeneratedEventImage {
  buffer: Buffer;
  contentType: string;
}

export interface GenerateEventImageInput {
  // The pet's real reference photo + a stable identity/world-visual
  // description — kept together so the pipeline can evolve the "stable pet
  // generation profile" (PRD §42) without changing this provider's shape.
  referenceImageUrl: string;
  stableIdentityDescription: string;
  worldVisualDescription: string;
  facts: EventFacts;
}

// Swappable behind PLANET_LIFE_IMAGE_PROVIDER — see planet-life.module.ts.
export interface EventImageGenProvider {
  generate(input: GenerateEventImageInput): Promise<GeneratedEventImage>;
}
