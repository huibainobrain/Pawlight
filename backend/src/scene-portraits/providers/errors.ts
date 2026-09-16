// Thrown by the real (Ark) providers when ARK_API_KEY is blank, so the
// service can tag a failed job with a specific, non-alarming error code
// instead of a generic failure — this is the concrete signal that the real
// adapter code path is wired up correctly even before a real key exists.
export class ScenePortraitProviderNotConfiguredError extends Error {
  constructor(provider: string) {
    super(`${provider} is not configured (missing ARK_API_KEY)`);
    this.name = 'ScenePortraitProviderNotConfiguredError';
  }
}
