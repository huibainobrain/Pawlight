# AGENTS

Rules for AI coding agents working in Pawlight.

## Fact Priority

When sources disagree:

~~~text
User latest instruction
→ docs/reference/product-spec.md
→ current code / schema
→ other reference docs
→ portfolio
→ archive
~~~

product-spec.md 可以有意领先于单次代码提交。

不要因为旧代码尚未同步，就自动把 Product Spec 改回旧状态。

## Before Coding

先阅读：

~~~text
product-spec.md
+
对应 reference
+
相关 code
~~~

## Current Product Domains

当前范围包括：

~~~text
Core Memorial
Share / Hug / Letters
AI Scene
Observation Window / PiP
Planet Life
Content Assets / Event Template
Planet Style / Home Profile / Home Anchor
Gift
Generation / Quality Providers
~~~

不要把这些当作未来规划。

## AI Rules

~~~text
Real Pet Photo
= Pet Identity Source

Planet Style + Home Profile + Home Anchor
= World Identity
~~~

核心原则：

> Rules determine facts; AI expresses them.

Personal Scene 不自动改写 Canonical Planet World。

## Provider Rules

Vendor 必须通过 Provider Interface 接入。

未知 Provider Key 必须 fail fast。

禁止业务层直接依赖 Vendor implementation。

## Product Boundaries

未经用户明确要求，不增加：

~~~text
AI Pet Chat
Pet Persona
Resurrection
Public Feed / Comment / Ranking
Task / Points / Level
RPG Gift Economy
Multi-pet Frontend
~~~

## Planet Life Invariants

生成要求：

~~~text
enabled
AND !paused
AND eligible time
AND no unread event
AND under weekly cap
~~~

生成结果只有通过质量检查后才能发布。

Bad Case：

- 隐藏 Event；
- 恢复相关 Gift 为 Pending；
- 如命中当前 Home Anchor，则使 Anchor 失效。

HomeProfile：

- 初始化一次；
- re-enable 不重新随机；
- 使用 frozen visualSnapshot；
- HomeVariant 后续修改不能改变已有 Home。

## Purchase / Entitlement

Paid Gate 必须服务端校验。

StoreKit Transaction 由 Backend 验证。

Gift 价格来自 StoreKit，不硬编码进 GiftAsset。

## Validation

Backend 变更完成前至少执行：

~~~text
Unit / Contract
Relevant E2E
Build
Lint
~~~

真实第三方模型调用不进入普通确定性 CI。

## Undefined Requirements

如果用户要求、Product Spec 与当前实现都没有定义某个行为：

- 不自行扩展相邻功能；
- 先确认要求，或明确说明 open question；
- 不使用 archive 补齐当前需求。
