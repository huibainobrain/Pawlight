# Pawlight H5

Next.js (App Router) visitor-facing page for a shared Pawlight memorial. No
login; reads from and writes to the NestJS backend over HTTP.

## Purpose

Renders the public memorial page at a share slug, and lets a visitor send one
"hug" per share. Everything on this page is intentionally public-safe — see
`docs/reference/api-reference.md` (Shares/Hugs sections) for exactly what the
backend does and does not return to this endpoint.

## Share slug

Each `Pet` has one `Share` row with a unique `slug` (`backend/prisma/schema.prisma`).
The page lives at `app/s/[slug]/page.tsx` and fetches
`GET {NEXT_PUBLIC_API_URL}/api/v1/shares/:slug` server-side on each request
(`next: { revalidate: 60 }`).

## Public memorial endpoint

The backend's public response for a valid, non-private slug includes: pet
name/type, main photo, memorial sentence, story, arrival/birth/left dates,
album photos, and the current hug count. It never includes the owning user's
account info, entitlement/purchase data, or `Letter` content — the private
mailbox has no H5 surface at all, by design, not by omission.

Non-`ok` responses the page handles explicitly:

- `403` → share `visibility === 'PRIVATE'` — rendered as a
  private/unavailable state.
- `404` → slug does not resolve to any share.
- Any other non-2xx, or a thrown fetch error → a generic error state.

## Hug

`app/s/[slug]/HugButton.tsx` posts to
`POST {NEXT_PUBLIC_API_URL}/api/v1/shares/:slug/hugs` with
`{ visitorFingerprint }`. The backend's response `status` field drives the UI:
`success` and `already_hugged` both mark the visitor as "hugged" locally;
`hug_disabled` renders a static "hugs aren't open right now" message instead
of a button; anything else is treated as a transient error with a retry
affordance.

## Visitor fingerprint

A random UUID (`crypto.randomUUID()`) generated once per browser and stored
in `localStorage` under `sf_visitor_id`; whether this browser has already
hugged a given slug is tracked separately under `sf_hug:{slug}`. This is
purely a client-side convenience for the "already hugged" UI state — the
backend's actual dedup constraint is `@@unique([shareId, visitorFingerprint])`
in Postgres, so clearing `localStorage` lets a visitor send a UI-level repeat
request, but the backend still returns `already_hugged` for it rather than
creating a second row.

## Private / unavailable state

A `PRIVATE` share and a nonexistent slug are both handled as explicit page
states (not a generic 500), so a visitor sees a clear "not available" message
in either case rather than a broken page or leaked error detail.

## Environment variables

Copy `.env.example` to `.env.local`:

- `NEXT_PUBLIC_API_URL` — required, no fallback. Backend origin, no trailing
  slash. Being `NEXT_PUBLIC_*`, it is inlined into the client bundle at build
  time; `lib/config.ts` throws immediately if it's missing, in both dev and
  build. Local development also targets a real deployed backend by design —
  there is no localhost default.

On Vercel this must be set under Project Settings → Environment Variables for
every environment (Production/Preview/Development) that should work.

## Local development

```bash
npm install
npm run dev
```

## Lint

```bash
npm run lint
```

## Build

```bash
npm run build
npm run start   # serve the production build locally
```

## Deployment

`.github/workflows/deploy-h5.yml` triggers a Vercel deploy hook on push to
`main` under `h5/**`, after `npm ci`, `npm run lint`, and `npm run build` all
succeed in CI — a commit with a lint or build failure does not trigger a
deploy. See `.github/workflows/ci.yml` for the full CI job.
