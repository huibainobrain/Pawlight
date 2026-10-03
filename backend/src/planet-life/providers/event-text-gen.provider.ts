export const EVENT_TEXT_GEN_PROVIDER = 'EVENT_TEXT_GEN_PROVIDER';

// A resolved content asset (LocationAsset / ActionAsset / ContentAsset row),
// shaped for provider consumption — carries both what a human reads
// (nameZh/nameEn) and what an image-gen model is given
// (visualDescription — LocationAsset.imageGenPrompt / ActionAsset.
// visualAction / ContentAsset.visualDescription), so a provider never needs
// to query Prisma itself to resolve a fact's full content.
export interface ResolvedAsset {
  key: string;
  nameZh: string;
  nameEn: string;
  visualDescription: string;
}

export interface EventFacts {
  location: ResolvedAsset;
  action: ResolvedAsset;
  time: ResolvedAsset;
  atmosphere: ResolvedAsset;
  ambientDetails?: ResolvedAsset;
  giftNameZh?: string;
  giftNameEn?: string;
}

export interface GenerateEventTextInput {
  facts: EventFacts;
  // Fixed narrative rules the text must obey (no first person, no simulated
  // personality, no invented facts beyond `facts`, no real-world assertions)
  // — passed as data, not hardcoded per-provider, so the rules are provider-
  // agnostic and centrally defined once (see prompts.ts).
  narrativeRules: string;
  language: string;
}

export interface GeneratedEventText {
  title: string;
  body: string;
}

// Swappable behind PLANET_LIFE_TEXT_PROVIDER — see planet-life.module.ts.
// The provider only expresses the given facts; it never decides what
// happened — that's EventTemplate's job.
export interface EventTextGenProvider {
  generate(input: GenerateEventTextInput): Promise<GeneratedEventText>;
}
