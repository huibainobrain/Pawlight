# Pawlight Product Spec

> Pawlight 当前产品规则事实源。历史版本与研究材料位于 docs/archive/。

## Product

Pawlight = iOS Owner App + H5 Memorial Page。

内容分为两类：

**真实回忆**

- Photo
- Story
- Memorial Sentence
- Letter

**AI 想象纪念**

- AI Scene
- Observation Window
- Planet Life

AI 内容必须标识为想象式纪念，不模拟宠物人格或真实来世。

## User / Pet

- P0 一个 User 最多 1 个 Pet；
- Pet Type：CAT / DOG / OTHER；
- Visitor 无需登录。

## Entitlement

FREE：

- 基础纪念；
- Share / Hug；
- Album 9 张。

PAID：

- Album 50 张；
- Letters；
- AI Scene；
- Observation Window；
- Planet Life。

## AI Scene

~~~text
MAIN Photo + Scene
→ 4 Candidates
→ Owner Select
→ Video
→ Observation Window
~~~

真实照片始终保留。

## Planet Life

首次开启：

- PAID；
- 已完成 AI Scene。

调度：

~~~text
48–96h
每周最多 3 条
最多 1 条 UNREAD
Read 后重新计时
Pause 时停止生成
~~~

Event：

~~~text
UNREAD → READ
UNREAD / READ → BAD_CASE
~~~

## Content System

~~~text
Content Assets
→ Event Template
→ Event Facts
→ AI Text / Image
→ Quality Check
→ Planet Event
~~~

原则：

> Rules determine facts; AI expresses them.

文本生成、图片生成、文本质检、图片质检均通过独立 Provider Interface 接入生产模型。

## Identity

~~~text
Real Pet Photo
→ Pet Identity

Planet Style
+ Home Profile
+ Home Anchor
→ World Identity
~~~

Personal Scene 不自动写入 Canonical Planet World。

## Home

HomeProfile 第一次开启时初始化一次。

固定：

- Cottage
- Palette
- Roof
- Door
- Window
- Signature Plant
- Nameplate

保存 frozen visual snapshot。

Home Anchor：

~~~text
NONE
→ ESTABLISHED

Bad Case
→ INVALIDATED

Next valid Home Event
→ ESTABLISHED new version
~~~

## Gift

~~~text
Purchase
→ PENDING
→ Valid Event
→ COMPLETED
~~~

同一时间最多 1 个 Pending Gift。

Bad Case：

~~~text
COMPLETED → PENDING
~~~

价格来自 StoreKit。

## Share / Hug

Visibility：

~~~text
LINK / PRIVATE
~~~

Hug 去重：

~~~text
shareId + visitorFingerprint
~~~

## Explicitly Out of Scope

- AI Pet Chat；
- Pet Persona；
- Resurrection；
- Public Feed / Comment / Ranking；
- Task / Level / Currency；
- Multi-pet frontend；
- RPG-style Gift System。
