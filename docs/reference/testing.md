# Testing

> Pawlight 的测试目标是验证产品规则、状态转换、权限、AI 编排与异常路径在快速 AI Coding 迭代后仍然可信。

## Current Status

~~~text
Backend Unit / Contract    159+
Backend E2E                 28+
Backend build / lint        passed
iOS Debug build             passed
~~~

## Backend Coverage

主要验证：

~~~text
Ownership
Entitlement
Quota
Privacy
Purchase
ScenePortrait State
Planet Life Scheduling
Content Compatibility
Gift Lifecycle
Home Identity
QC Retry
Delete Cleanup
~~~

## Planet Life Key Cases

~~~text
Enable Gate
Unread Gate
Weekly Cap
Read → Reschedule
Pause
Gift PENDING / COMPLETED
Bad Case Rollback
HomeProfile Init Once
Snapshot Freeze
PlanetStyle Binding
Anchor Establish / Invalidate / Rebuild
~~~

## Test Layers

### Unit / Contract

~~~bash
cd backend
npm test
~~~

用于验证 Service 规则和 Provider Contract。

### E2E

~~~bash
DATABASE_URL_TEST=... npm run test:e2e
~~~

使用真实 NestJS AppModule + 测试 Postgres + 确定性测试适配器，验证 HTTP → Service → Prisma → State Transition。

## Test Boundary

CI 不调用真实付费 AI 服务。

CI 负责：

> 确定性业务逻辑、状态、权限与 Provider Contract。

真实模型验证负责：

> 效果、成本、时延、稳定性和完整生产链路。

两者职责分离。

## Client Validation

iOS 与 H5 当前主要采用：

~~~text
Build Validation
+
关键路径人工走查
~~~

重点覆盖 Onboarding、Purchase、AI Scene、Observation Window、PiP、Planet Life、Gift、Bad Case、Share / Hug 与 Account Delete。

## Completion Rule

AI Coding 改动至少需要通过：

~~~text
Build
Relevant Tests
Failure Path
Permission
State Consistency
Product Walkthrough
~~~

> **AI Coding 提高实现速度，但不能降低验收标准。**
