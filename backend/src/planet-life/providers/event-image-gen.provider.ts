import type { EventFacts } from './event-text-gen.provider';
import type { HomeGenerationContext } from './home-context';

export const EVENT_IMAGE_GEN_PROVIDER = 'EVENT_IMAGE_GEN_PROVIDER';

export interface GeneratedEventImage {
  buffer: Buffer;
  contentType: string;
}

export interface GenerateEventImageInput {
  // The pet's real reference photo — the ONLY identity source. Never an
  // AI-generated image (not a prior PlanetEvent image, not the Home Anchor
  // image below) — see HomeGenerationContext's own doc comment for why.
  referenceImageUrl: string;
  // A stable identity description kept separate so the pipeline can evolve
  // the "stable pet generation profile" (PRD §42) without changing this
  // provider's shape.
  stableIdentityDescription: string;
  // Resolved from this pet's bound PlanetStyle.imageGenGuidance — global,
  // not per-pet. Renamed from the earlier worldVisualDescription placeholder
  // now that "what does the WORLD look like" has split into this (global
  // style) and HomeGenerationContext (per-pet home identity) below.
  planetStyleDescription: string;
  facts: EventFacts;
  // Present only when the resolved Location is HOME_BASE. The Home Anchor
  // image inside it is a VISUAL REFERENCE for world consistency only — it
  // must never be treated as a pet-identity source; referenceImageUrl above
  // is the only thing that decides what the pet looks like.
  home?: HomeGenerationContext;
}

// Swappable behind PLANET_LIFE_IMAGE_PROVIDER — see planet-life.module.ts.
export interface EventImageGenProvider {
  generate(input: GenerateEventImageInput): Promise<GeneratedEventImage>;
}
