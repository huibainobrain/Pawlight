import type { HomeVisualSnapshot } from '../home-profile.types';

// Optional extra context attached only when the resolved Location for this
// generation is HOME_BASE — a Nearby event never builds one of these, and a
// provider never needs to treat Home/Nearby as two different interfaces (see
// EventImageGenProvider / ImageQualityProvider), just check whether this is
// present.
export interface HomeGenerationContext {
  visualSnapshot: HomeVisualSnapshot;
  // Present only once this pet's Home Anchor is actually ESTABLISHED — the
  // very first Home event (or any Home event generated while a prior anchor
  // is INVALIDATED) has none yet, and must not fabricate one.
  anchorImageUrl?: string;
  // 0 until a first anchor is ever established, then increments each time a
  // new one replaces an invalidated one.
  anchorVersion: number;
}
