# AI Provider Integration

> Pawlight 通过 Provider Interface 将业务规则与模型 Vendor 解耦。

Pawlight 当前有两套 AI Pipeline：

~~~text
AI Scene
= 用户主动创作

Planet Life
= 系统长期内容生成
~~~

## AI Scene

~~~text
ImageGenProvider
VideoGenProvider
~~~

ImageGenProvider：

~~~text
Real Pet Reference
+ User Scene
+ Candidate Count
→ Candidate Images
~~~

VideoGenProvider：

~~~text
Selected Image
+ Motion Prompt
+ Duration
→ Async Video Task
→ Video Result
~~~

ScenePortraitsService 只依赖接口，不直接依赖具体 Vendor。

## Planet Life

~~~text
EventTextGenProvider
EventImageGenProvider
TextQualityProvider
ImageQualityProvider
~~~

EventTextGenProvider 输入：

~~~text
Event Facts
+ Narrative Rules
+ Language
~~~

EventImageGenProvider 输入：

~~~text
Real Pet Reference
+ Planet Style
+ Event Facts
+ Home Context（HOME_BASE only）
~~~

Quality Providers 分别检查文本事实 / 叙事边界，以及图片身份 / 场景 / Gift / 世界一致性。

## Input Responsibility

~~~text
Real Pet Photo
→ Pet Identity

Planet Style
→ Global World Style

Home Context
→ HOME_BASE Consistency

Event Facts
→ Current Scene
~~~

Home Anchor 只能作为 World Visual Reference，不能替代真实宠物照片成为 Identity Source。

## Provider Registry

~~~text
Environment Provider Key
→ Registry Lookup
→ Production Adapter
→ Vendor
~~~

未知 Provider Key 必须 Fail Fast。

禁止配置错误时静默 fallback 到另一家生产模型。

## Model Switch

切换模型主要修改：

~~~text
Provider Adapter
+
Registry / Environment
~~~

不应修改：

~~~text
Event Template
Gift Lifecycle
HomeProfile
Scheduler
API
Product Flow
~~~

## Asset Persistence

第三方模型返回的临时资源需要转存：

~~~text
Vendor Result
→ Download
→ Pawlight R2
→ Persist
~~~

适用于 Scene Candidate、Scene Video 和 Planet Event Image。

## New Provider Acceptance

至少验证：

- Contract；
- Error Handling；
- Real API；
- Product Chain；
- Effect；
- Latency；
- Cost；
- Stability。

CI 验证确定性系统逻辑；真实链路验证模型效果与第三方服务表现。
