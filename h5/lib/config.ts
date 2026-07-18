// Central place for the support contact address. Edit this one line to change
// the email used across the support page (button, visible text, and mailto link).
export const SUPPORT_EMAIL = "ntuwangyiming@gmail.com";

// Backend API origin (no trailing slash), e.g. https://pet-memory-production.up.railway.app.
// Required in every environment: NEXT_PUBLIC_* vars are inlined into the
// client bundle at build time, so there is no safe runtime fallback (and no
// localhost default — this project's local dev also targets a real deployed
// backend, see h5/.env.local). Missing it must fail loudly instead of
// silently fetching "undefined/api/v1/...".
function readApiUrl(): string {
  const value = process.env.NEXT_PUBLIC_API_URL;
  if (!value) {
    throw new Error(
      "NEXT_PUBLIC_API_URL is not set. Add it to h5/.env.local for local development " +
        "(see h5/.env.example), or set it in your deployment platform's environment " +
        "variables (e.g. Vercel Project Settings > Environment Variables) for production.",
    );
  }
  return value;
}

export const API_URL = readApiUrl();
