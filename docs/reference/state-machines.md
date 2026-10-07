# State Machines

> Pawlight 关键持久化状态与生命周期。

## Scene Portrait

~~~text
QUEUED
→ GENERATING_IMAGE
→ CANDIDATES_READY
→ GENERATING_VIDEO
→ DONE

in-flight error
→ FAILED
~~~

## Observation Window

~~~text
Static Photo
→ Video Active
→ Static Photo
~~~

Video Active 来自 ScenePortraitJob DONE；Owner Revert 后回到 Static Photo。

## Planet Life

~~~text
Disabled
→ Waiting
→ Due
→ Generate
→ Unread
→ Read
→ Waiting
~~~

生成前必须同时满足：

~~~text
enabled
AND !paused
AND eligible time
AND no unread event
AND under weekly cap
~~~

## Planet Event

~~~text
UNREAD → READ
UNREAD / READ → BAD_CASE
~~~

Read 后重新计算下一次等待。

## Gift

~~~text
PENDING → COMPLETED

Fulfillment Event → BAD_CASE
COMPLETED → PENDING
~~~

不重复收费。

## Home Anchor

~~~text
NONE
→ ESTABLISHED V1
→ INVALIDATED
→ ESTABLISHED V2
~~~

HomeProfile 不随 Anchor invalidation 重建。

Anchor Version 只在成功建立新 Anchor 时增加。

## Share / Hug

~~~text
Share:
LINK ↔ PRIVATE

Hug result:
success
already_hugged
not_found
private_or_unavailable
hug_disabled
~~~

hugEnabled 与 Share visibility 独立。

## Entitlement

~~~text
FREE → PAID
~~~

Gift 不改变 Entitlement Tier，而创建独立 GiftInstance。
