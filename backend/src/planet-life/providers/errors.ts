// Thrown by a real provider when its required credentials are missing, so the
// generation pipeline can silently defer to the next tick with a specific,
// non-alarming reason instead of a generic failure. No real provider exists
// yet this round (see planet-life.module.ts) — this exists so adding one
// later follows the same pattern scene-portraits already established.
export class PlanetLifeProviderNotConfiguredError extends Error {
  constructor(provider: string) {
    super(`${provider} is not configured`);
    this.name = 'PlanetLifeProviderNotConfiguredError';
  }
}
