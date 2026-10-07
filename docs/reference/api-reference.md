# API Reference

> 当前 Backend HTTP Surface。所有业务 API 默认位于 /api/v1。

Auth：

- Public：无需 JWT；
- JWT：需要 Authorization Bearer Token。

## Auth

~~~text
POST   /api/v1/auth/login
DELETE /api/v1/auth/me
~~~

## Pet / Photo

~~~text
POST   /api/v1/pets
GET    /api/v1/pets/mine
PATCH  /api/v1/pets/:id

POST   /api/v1/pets/:petId/photos
GET    /api/v1/pets/:petId/photos
DELETE /api/v1/photos/:id
DELETE /api/v1/pets/:petId/photos/:photoId
~~~

## Share / Hug

~~~text
GET   /api/v1/shares/:slug
GET   /api/v1/pets/:petId/share
PATCH /api/v1/pets/:petId/share

POST /api/v1/shares/:slug/hugs
GET  /api/v1/pets/:petId/hugs
~~~

## Letters

~~~text
GET    /api/v1/pets/:petId/letters
POST   /api/v1/pets/:petId/letters
PATCH  /api/v1/pets/:petId/letters/:id
DELETE /api/v1/pets/:petId/letters/:id
~~~

## Purchase

~~~text
POST /api/v1/purchases/verify
~~~

按 Product ID 路由：

~~~text
Full Memorial Space → Entitlement
Gift Product        → GiftInstance
~~~

同一 Apple transaction 不允许重复产生多个 GiftInstance。

## AI Scene

~~~text
POST /api/v1/pets/:petId/scene-portraits
GET  /api/v1/scene-portraits/:jobId
POST /api/v1/scene-portraits/:jobId/select
POST /api/v1/pets/:petId/observation-window/revert
~~~

Start 校验：

- Owner；
- PAID；
- MAIN Photo；
- 生成次数。

只有 CANDIDATES_READY 的 Job 可以进入 Video Generation。

## Planet Life

~~~text
GET   /api/v1/pets/:petId/planet-life
POST  /api/v1/pets/:petId/planet-life/enable
PATCH /api/v1/pets/:petId/planet-life/settings

GET  /api/v1/pets/:petId/planet-life/events
POST /api/v1/pets/:petId/planet-life/events/:eventId/read
POST /api/v1/pets/:petId/planet-life/events/:eventId/bad-case

GET /api/v1/pets/:petId/gifts
~~~

Enable 校验：

- Owner；
- Planet Life capability；
- 已完成至少一次 AI Scene。

Mark Read：

~~~text
UNREAD
→ READ
→ reschedule nextEligibleAt
~~~

Bad Case：

~~~text
Event → BAD_CASE

Gift（如有）→ PENDING

Current Home Anchor（如有关联）→ INVALIDATED
~~~

## Important Business Errors

~~~text
PET_LIMIT_REACHED
PHOTO_QUOTA_REACHED
MAILBOX_NOT_ENABLED
PAID_ONLY
NO_MAIN_PHOTO
JOB_NOT_READY
GIFT_ALREADY_PENDING
~~~

## Debug-only

Debug API 必须同时受 JWT + X-Debug-Secret 保护。

用于 Planet Life 测试触发、Gift 模拟、真实生成链路验证和测试状态重置。
