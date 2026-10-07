# Architecture

> Pawlight 当前系统组成与核心调用关系。产品规则以 product-spec.md 为准。

~~~text
iOS / SwiftUI
        │
        ▼
NestJS Backend
        │
 ┌──────┼──────────┐
Postgres R2      StoreKit
        │
   AI Providers

H5 / Next.js
        │
   Public Share API
~~~

## AI Scene

~~~text
Scene Input
→ ScenePortraitJob
→ Image Provider
→ Candidates
→ Owner Select
→ Video Provider
→ Observation Video
~~~

## Planet Life

~~~text
Scheduler
→ Eligibility
→ Event Template + Assets
→ Event Facts
→ Text Generation + QC
→ Image Generation + QC
→ Planet Event
~~~

## Home Identity

~~~text
Real Pet Photo
→ Pet Identity

Planet Style
→ Home Profile
→ Home Anchor
→ World Identity
~~~

HOME_BASE 使用 Home Context；NEARBY 只继承 Planet Style。

## Main Modules

~~~text
auth
pets
photos
shares
hugs
letters
purchases
scene-portraits
planet-life
storage
prisma
~~~

## Planet Life Responsibilities

~~~text
PlanetLifeService
├─ scheduling / enable / pause / read / bad-case
├─ HomeProfileService
├─ GiftsService
└─ PlanetEventGenerationService
      ├─ EventTemplate + Content Assets
      ├─ Text / Image Providers
      └─ Text / Image Quality Providers
~~~

## Publish Consistency

一次 Event 正式发布时，需要同步处理：

- PlanetEvent；
- weekly counter；
- Gift completion（如有）；
- Home Anchor establish（如有）。

相关写入应保持事务一致性。

## Storage

长期资产包括：

~~~text
Pet Photos
Scene Portrait Candidates
Scene Portrait Video
Planet Event Images
Home Anchor Reference
~~~

第三方模型返回的临时资源需要转存 Pawlight 自己控制的 R2。

## Purchase

~~~text
StoreKit
→ Signed Transaction
→ Backend Verification
→ Entitlement / GiftInstance
~~~

Gift 价格来自 StoreKit，不硬编码进业务 Asset。

## Account Delete

~~~text
Delete R2 Assets
→ Delete User
→ DB Cascade
~~~

## Architecture Constraint

当前 AI 长任务使用 Backend 异步执行。

产品规模显著扩大后，再考虑 Queue / Worker。
