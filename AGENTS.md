# AGENTS

Rules for AI coding agents (Claude, Codex, or others) working in this repository.

## 1. Fact Priority

When the user's request, code, and docs disagree, resolve in this order:

1. The user's most recent explicit request in the current conversation.
2. `docs/reference/product-spec.md`, when it exists — the current intended
   product rules, written directly by the user (see section 2).
3. The current code (`ios/`, `backend/src/`, `h5/`) and the current Prisma
   schema (`backend/prisma/schema.prisma`) — what is actually implemented.
4. The rest of `docs/reference/*` — technical facts derived from current
   code.
5. `docs/archive/*` — historical reference only.

`product-spec.md` describes what the product is currently *meant* to do; the
code and schema show what it *actually* does. These can disagree — a spec
change not yet implemented, or an implementation that drifted from the spec.
When they do:

- do not guess which one is "right" and silently change the other to match;
- state the conflict explicitly in your response;
- let the user's current task decide whether the spec or the implementation
  is the one that should change;
- `docs/archive/*` never overrides either one, regardless of this conflict.

`product-spec.md` not existing yet is the current normal state — do not
create it yourself (see section 2).

## 2. Reference Docs

Current, code-derived technical facts live under `docs/reference/`:

- `docs/reference/architecture.md` — module map and call relationships.
- `docs/reference/data-model.md` — Prisma models, fields, constraints.
- `docs/reference/api-reference.md` — controllers, routes, auth, error codes.
- `docs/reference/state-machines.md` — ScenePortrait job states, Share/Hug/
  Entitlement states, and iOS-only UI states.
- `docs/reference/ai-provider-integration.md` — ImageGenProvider /
  VideoGenProvider architecture, provider registry, environment variables.
- `docs/reference/testing.md` — test layers, how to run them, CI behavior.

Read the relevant one before changing that area of the system, instead of
re-deriving it from scratch or relying on a possibly stale mental model.

Two additional reference paths are reserved for the user to write directly —
do not create or edit them: `docs/reference/product-spec.md`,
`docs/reference/localization.md`.

## 3. `docs/archive/` Is Historical, Not Authoritative

`docs/archive/v1/` and `docs/archive/research/` record a past state of the
product, or a research snapshot at a point in time. Do not:

- treat an archived doc as the current spec for anything;
- change current code to match an archived doc;
- rewrite an archived doc's body to match current behavior — its value is
  recording what was true when it was written.

If an archived doc and the current code disagree, the code wins, always.

## 4. Current Scope Boundaries

Do not add the following unless the user explicitly asks for it:

- community features, a public discovery/feed page, a public comment system;
- AI chat with the pet, or the pet "replying" as if it were present;
- pet-resurrection framing of any kind;
- task/points/ranking systems, a marketplace or shop;
- multi-pet management beyond the current one-pet-per-account limit enforced
  in `PetsService.create` (the schema itself does not hard-block more, the
  service does);
- system push notifications, anniversary reminders;
- user-uploaded video as a memory type (distinct from the AI-generated scene
  video described below, which already exists).

The AI scene portrait / dynamic observation window feature — natural-language
scene description → generated candidate portraits → a generated looping video
in the home planet window, paid-only — **is implemented**. See
`backend/src/scene-portraits/` and
`ios/MemorialApp/Sources/Features/ScenePortrait/`. Do not treat it as out of
scope, and do not describe it as unimplemented or planned in new writing.

## 5. Undefined Requirements

If something is not covered by the current code, `docs/reference/*`, or an
explicit user request:

- do not invent product scope;
- do not silently implement an adjacent feature while working on something
  else;
- ask the user, or note it as an open question in your response.

## 6. Engineering Conventions

- Backend: NestJS + Prisma + PostgreSQL. A new external vendor integration
  (image/video generation, etc.) goes behind an interface with an explicit,
  exhaustive provider registry — see
  `backend/src/scene-portraits/scene-portraits.module.ts`. An unrecognized
  provider name must fail at startup; it must never silently resolve to some
  default vendor.
- Never commit real secrets. `.env.example` documents variable names only,
  left blank.
- `npm run lint` (backend and h5) may rewrite source (`--fix` on the backend
  script); CI must use a non-mutating check instead (`npm run lint:check` on
  the backend) so a CI run never silently modifies the working tree.
- Run backend unit tests, provider contract tests, and e2e tests before
  considering a backend change done — see `docs/reference/testing.md`.
- Live third-party AI APIs (Ark/Seedream/Seedance, and any future vendor)
  must never run inside CI. Validate them with the smoke script
  (`backend/scripts/smoke-scene-provider.ts`) instead.
- iOS: DEBUG-only scaffolding must be wrapped in `#if DEBUG` and must have no
  effect on Release builds. A paid-gated feature must be enforced
  server-side; hiding its entry point in the UI alone is not enough.
