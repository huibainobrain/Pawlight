# API Reference

Derived directly from the current NestJS controllers under `backend/src/`.
This lists what exists today — not what was planned in `docs/archive/v1/`.
All paths are relative to the backend's base URL; all are prefixed
`/api/v1` except `GET /health`.

Auth column: **Public** (no guard), or **JWT** (`JwtAuthGuard`, requires
`Authorization: Bearer <token>`, `req.user.id` from the token's `sub` claim).

## Health

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/health` | Public | Returns `{ status: 'ok' }`. (`app.controller.ts`) |

## Auth (`auth/`)

| Method | Path | Auth | Body | Notes |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/login` | Public | `{ identity_token }` | Verifies the Apple identity token, creates the `User` + `Entitlement` (FREE) on first login, returns `{ access_token, user }`. Throws `UnauthorizedException` if the token is invalid. |
| POST | `/api/v1/auth/debug-login` | Public route, gated internally | header `X-Debug-Secret` | Only works if `DEBUG_SECRET` env var is set and matches; otherwise `ForbiddenException`. Always sets `tier: 'PAID', photoLimit: 50, mailboxEnabled: true` and **deletes all existing pets for that debug user**. |
| DELETE | `/api/v1/auth/me` | JWT | — | Deletes the account: `PhotosService.deleteAllForUser`, `ScenePortraitsService.deleteAllForUser`, then `prisma.user.delete` (cascades). Returns `{ status: 'success' }`. |

## Pets (`pets/`)

All routes require JWT.

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| POST | `/api/v1/pets` | `{ name, type }` (`type`: `CAT\|DOG\|OTHER`) | Rejects with `409 { code: 'PET_LIMIT_REACHED' }` if the user already owns a pet. Also creates a `Share` row (random slug) as part of pet creation. |
| GET | `/api/v1/pets/mine` | — | Returns every pet owned by the user (in practice 0 or 1), each with `albumPhotoCount`, `albumPhotoLimit`, `mailboxEnabled` merged in, plus `share` and `photos` relations. |
| PATCH | `/api/v1/pets/:id` | Partial `UpdatePetDto` (`name`, `type`, `arrivedOn`, `bornOn`, `leftOn`, `story`, `memorialSentence`, `mainPhotoId`) | 404 if not found, 403 if not owner. |

## Photos (`photos/`)

All routes require JWT.

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| POST | `/api/v1/pets/:petId/photos` | multipart: `file` (max 10MB) + `type?` (`MAIN\|ALBUM`, default `ALBUM`) | `ALBUM` uploads count against the account's photo quota (`400 { code: 'PHOTO_QUOTA_REACHED' }` when at limit); `MAIN` uploads do not. |
| GET | `/api/v1/pets/:petId/photos` | — | Returns only `ALBUM`-type photos, plus `albumPhotoCount`/`albumPhotoLimit`. |
| DELETE | `/api/v1/photos/:id` | — | `400 { code: 'CANNOT_DELETE_MAIN_PHOTO' }` if the photo's `type` is `MAIN`. |
| DELETE | `/api/v1/pets/:petId/photos/:photoId` | — | Same as above; `petId` in the path is accepted for REST-path symmetry with iOS but not used for the ownership check (ownership comes from the photo's own `pet.userId`). |

## Shares (`shares/`)

| Method | Path | Auth | Body | Notes |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/shares/:slug` | Public | query `?visitorFingerprint=` optional | `404 { status: 'not_found' }` if the slug doesn't resolve; `403 { status: 'private_or_unavailable' }` if `visibility === 'PRIVATE'`. On success returns a curated public DTO (see below) — never the owning `User`, `Entitlement`, purchase data, or `Letter` content. |
| GET | `/api/v1/pets/:petId/share` | JWT | — | Owner-only read of the raw `Share` row. |
| PATCH | `/api/v1/pets/:petId/share` | JWT | `{ visibility?, hugEnabled? }` | Owner-only. |

Public `GET /shares/:slug` response shape:
`{ status: 'ok', slug, visibility, hugEnabled, petName, petType, mainPhoto, memorialSentence, story, arrivedOn, bornOn, leftOn, albumPhotos: [{id, url, caption}], hugCount, viewerHasHugged }`.

## Hugs (`hugs/`)

| Method | Path | Auth | Body | Notes |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/shares/:slug/hugs` | Public | `{ visitorFingerprint, visitorName?, message? }` | Never throws for business outcomes — always `200` with `{ status, hug?, hugCount? }`. `status` is one of `success \| already_hugged \| not_found \| private_or_unavailable \| hug_disabled`. A duplicate `(shareId, visitorFingerprint)` insert racing the pre-check is caught via the Prisma `P2002` unique-constraint error and mapped to `already_hugged`. |
| GET | `/api/v1/pets/:petId/hugs` | JWT | — | Owner-only list, newest first. |

## Letters (`letters/`)

All routes require JWT and are mailbox-gated (`Entitlement.mailboxEnabled === true || tier === 'PAID'`, else `403 { code: 'MAILBOX_NOT_ENABLED' }`).

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| GET | `/api/v1/pets/:petId/letters` | — | Newest first. |
| POST | `/api/v1/pets/:petId/letters` | `{ title?, content }` | |
| PATCH | `/api/v1/pets/:petId/letters/:id` | `{ title?, content }` | 404 if the letter doesn't belong to `petId`. |
| DELETE | `/api/v1/pets/:petId/letters/:id` | — | 403 if the letter's pet is not owned by the caller. |

## Purchases (`purchases/`)

| Method | Path | Auth | Body | Notes |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/purchases/verify` | JWT | `{ jws_token }` | Verifies the signed transaction against Apple's root CA (Production verifier tried first when `APPLE_APP_APPLE_ID` is configured, Sandbox as fallback). `400` if `productId !== 'com.pawlight.full_memorial_space'`, if the transaction is revoked, or if verification fails. On success upserts `Entitlement` to `tier: PAID, photoLimit: 50, mailboxEnabled: true`. |

## Scene Portraits (`scene-portraits/`)

All routes require JWT.

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| POST | `/api/v1/pets/:petId/scene-portraits` | `{ sceneText }` (1-200 chars, required) | `403 { code: 'PAID_ONLY' }` if not paid. `400 { code: 'NO_MAIN_PHOTO' }` if the pet has no `MAIN` photo. `400 { code: 'SCENE_PORTRAIT_ATTEMPTS_EXHAUSTED', maxAttempts: 3 }` at the per-pet attempt cap (non-`FAILED` jobs only count toward it). Returns the created job (`status: QUEUED`) immediately; generation runs asynchronously afterward. |
| GET | `/api/v1/scene-portraits/:jobId` | — | Returns the job plus its `candidates`, ordered by `sortOrder`. 404/403 if the job doesn't belong to the caller. |
| POST | `/api/v1/scene-portraits/:jobId/select` | `{ candidateId }` | `400 { code: 'JOB_NOT_READY' }` unless `status === CANDIDATES_READY`. 404 if the candidate doesn't belong to this job. Advances to `GENERATING_VIDEO` and starts video generation asynchronously. |
| POST | `/api/v1/pets/:petId/observation-window/revert` | — | Clears `Pet.observationVideoJobId/Key/Url`. Does not delete the underlying `ScenePortraitJob` or its R2 objects. |

## Errors not modeled as HTTP status alone

Several endpoints return a structured body on top of the HTTP status so the
client can branch on `code` rather than parsing text: `PET_LIMIT_REACHED`,
`PHOTO_QUOTA_REACHED`, `CANNOT_DELETE_MAIN_PHOTO`, `MAILBOX_NOT_ENABLED`,
`PAID_ONLY`, `NO_MAIN_PHOTO`, `SCENE_PORTRAIT_ATTEMPTS_EXHAUSTED`,
`JOB_NOT_READY`. The public hug/share endpoints instead encode their outcome
in a `status` field on a `200` response (see Hugs and Shares above) rather
than using HTTP error codes, so a browser fetch never has to branch on
non-2xx just to render "already hugged" or "private" states.
