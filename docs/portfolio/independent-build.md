# Pawlight：独立开发 Case Study

> 我想证明的不是“会写多少代码”，而是能不能把产品规则真正落成系统。

我的工作流程：

~~~text
产品判断
→ 规则拆解
→ 数据 / 状态 / 接口设计
→ AI Coding
→ Review
→ 测试
→ 产品走查
~~~

## Case 1：Hug

一个「抱抱 TA」按钮最终需要处理：

~~~text
Visitor Identity
→ Share Permission
→ Hug Enabled
→ Duplicate Check
→ DB Unique Constraint
→ Owner Record
~~~

它让我把一个简单交互继续拆成：

> 身份、权限、状态和异常闭环。

## Case 2：AI Scene

~~~text
Scene Input
→ Job
→ Image Provider
→ 4 Candidates
→ User Select
→ Video Provider
→ Poll
→ R2
→ Observation Window
~~~

对应持久化状态：

~~~text
QUEUED
→ GENERATING_IMAGE
→ CANDIDATES_READY
→ GENERATING_VIDEO
→ DONE / FAILED
~~~

真正上线以后，AI API 只是整个链路的一部分。

## Case 3：Planet Life

一句需求：

> “每隔几天自动留下一条新的生活纪事。”

最终需要落成：

~~~text
Scheduling
Content Assets
Event Templates
Generation
Quality Control
Home Identity
Gift Fulfillment
Bad Case Rollback
~~~

其中：

~~~text
真实照片
→ Pet Identity

Planet Style + Home Profile + Home Anchor
→ World Identity
~~~

当前 Backend 已覆盖：

~~~text
159+ Unit / Contract Tests
28+ E2E Tests
~~~

包括 Planet Life 调度、Gift、QC、HomeProfile 与 Home Anchor 生命周期等关键规则。

## 对 AI PM Coding 能力的理解

独立 Coding 对我最有价值的不是替代工程师，而是让我更早看见：

- 一个需求需要哪些状态；
- 权限和异常会在哪里出现；
- 模型失败应该由谁处理；
- 产品规则怎样落进数据和接口。

> **AI Coding 提高实现速度，但不能替代产品判断和验收。**
