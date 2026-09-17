# Pawlight：独立开发 Case Study

> 我在这个项目里想证明的不是“会多少技术栈”，而是：**能不能把产品规则真正变成一个可以运行、可以验证的系统。**

工程实现过程中，我大量使用 Claude / Codex 等 AI Coding 工具。

我的主要工作是：

```text
产品判断
→ 需求拆解
→ 数据 / 状态 / 接口规则
→ AI Coding
→ Code Review
→ 联调
→ 产品走查
→ 测试
→ 迭代
```

下面只选三个最能代表这套能力的 Case。

---

## Case 1：把「轻轻抱抱」从一个按钮做成完整产品闭环

表面需求：

> H5 上加一个“抱抱 TA”的按钮。

真正实现前需要先定义：

```text
访客登录吗？
同一个人能抱几次？
如何判断同一个访客？
主人可以关闭吗？
PRIVATE 页面怎么办？
并发点击怎么办？
主人在哪里看到？
```

最终规则：

```text
Visitor 无需登录
→ 本地 visitorFingerprint
→ Backend 校验 Share
→ 校验 Hug Enabled
→ DB Unique Constraint
→ 重复返回 already_hugged
→ Owner 可以查看 Hug
```

这里最重要的不是数据库本身。

而是把一句产品需求拆成：

> **身份、权限、状态、异常和反馈闭环。**

---

## Case 2：把 AI 生成从 Demo 做成真实产品能力

最简单 Demo：

```text
Photo
→ API
→ Image
```

Pawlight 的真实链路是：

```text
Owner 输入 Scene
→ Backend 校验权益 / MAIN Photo / 次数
→ 创建 Job
→ Image Provider
→ 生成 4 Candidates
→ 保存 R2
→ Owner Select
→ Video Provider
→ Polling
→ 下载结果
→ 转存 R2
→ Job DONE
→ Pet observationVideo 更新
→ iOS 首页播放
```

失败也必须成为产品状态：

```text
QUEUED
GENERATING_IMAGE
CANDIDATES_READY
GENERATING_VIDEO
DONE
FAILED
```

这个过程让我把模型能力进一步拆成：

- 产品状态；
- 成本；
- 失败；
- 用户选择；
- 资产持久化；
- 回退路径。

AI 产品真正上线之后，模型只是系统中的一部分。

---

## Case 3：从「AI Coding 能跑」到「结果可信」

AI Coding 很容易让项目快速进入：

> 看起来已经能用了。

但“能跑”不等于“可靠”。

因此后续补了一轮核心业务测试：

```text
Backend lint
0 error / 0 warning

Unit / Provider Contract
92 tests

E2E
8 tests
```

覆盖：

- 权益；
- Photo quota；
- Owner 权限；
- Share Privacy；
- Hug 并发；
- Purchase；
- Delete Account；
- ScenePortrait；
- Provider Contract；
- Video timeout。

测试过程中还发现过一个真实 Build Bug：

```text
deleteOutDir
+
incremental cache

→ 第二次 build 可能先删 dist
→ 编译器又认为大量文件不用重新生成
→ 命令表面成功
→ dist 实际不完整
```

修复后通过连续多次 build 验证完整产物。

这个 Case 对我最大的启发是：

> **AI Coding 的完成标准不能是“AI 说完成了”，甚至不能只是“Build 显示成功”。验证过程本身也必须可靠。**

---

## 我现在怎么理解 AI PM 的 Coding 能力

我不认为 AI 产品经理需要代替专业工程团队。

但在 0→1 阶段，独立 Coding 能让我：

- 更快验证复杂产品假设；
- 不只停留在 PRD 层理解状态；
- 更早发现权限和数据问题；
- 理解模型调用背后的成本与异常；
- 与工程讨论真实的数据契约；
- 区分问题来自模型、产品还是实现；
- 用更低资源成本跑出真实用户验证。

Pawlight 对我最大的价值不是：

> “我独立写了多少代码。”

而是：

> **当我提出一个产品方案时，我越来越清楚它最终会怎样落到数据、状态、权限、模型和异常中。**
