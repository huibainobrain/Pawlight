# Data Model

> 当前数据模型参考。backend/prisma/schema.prisma 是具体 Schema 事实源；本文只记录模型职责与关键业务约束。

## Core

| Model | Purpose |
| --- | --- |
| User | Account / language |
| Pet | Memorial owner object |
| Entitlement | Account-level feature access |
| Photo | MAIN / ALBUM |
| Share | Public access config |
| Hug | Visitor reaction |
| Letter | Private memorial letter |

## AI Scene

| Model | Purpose |
| --- | --- |
| ScenePortraitJob | 一次 Scene → Video 流程 |
| ScenePortraitCandidate | Job 的图片候选 |

## Planet Life

| Model | Purpose |
| --- | --- |
| PlanetLifeState | enabled / paused / scheduling |
| PlanetEvent | 已发布纪事及 facts snapshot |
| EventTemplate | 合法事件结构 |
| LocationAsset | 地点 |
| ActionAsset | 行为 |
| ContentAsset | Time / Atmosphere / Ambient |
| PlanetStyle | 全局世界风格版本 |
| HomeVariantAsset | Home 初始化资产 |
| HomeProfile | 每只 Pet 的固定家园事实 |
| GiftAsset | 礼物类型 |
| GiftProduct | StoreKit Product Mapping |
| GiftInstance | 一次真实购买 |

## Key States

~~~text
PlanetEvent:
UNREAD / READ / BAD_CASE

HomeAnchor:
NONE / ESTABLISHED / INVALIDATED

GiftInstance:
PENDING / COMPLETED
~~~

## Key Fields

### PlanetEvent.factsJson

保存每条 Event 实际使用的 Location / Action / Time / Atmosphere / Gift 等事实快照。

资产库后续变化时，历史 Event 仍可追溯。

### HomeProfile.visualSnapshot

HomeProfile 初始化时冻结的家园视觉事实。

HomeVariantAsset 后续修改不能追溯改变已有 Home。

### HomeProfile.homeAnchor*

保存当前有效 Home Anchor 的状态、版本和图片指针。

### GiftInstance.purchaseTransactionId

唯一 Apple transaction id，用于保证购买验证幂等。

## Key Constraints

- Pet Identity 只来自真实照片；
- HomeVariant 修改不追溯影响现有 HomeProfile；
- GiftAsset ≠ GiftInstance；
- Gift 价格来自 StoreKit；
- 单宠限制由 Service 层执行；
- Share Hug 通过 (shareId, visitorFingerprint) 唯一约束去重；
- PlanetEvent 与 Gift / Home Anchor 的最终状态需要保持发布一致性。
