# Pawlight

> 为离开的宠物留下一颗温柔、私密、可以反复回看的纪念星球。

Pawlight 是我独立推进的一款宠物纪念产品，已完成海外 App Store 上线并获得 **50+ 付费用户**。

产品以真实照片、故事与亲友纪念为基础，并在 V2 中引入生成式 AI：主人可以描述一个想看到 TA 所在的场景，由模型生成候选画像，再由主人选择最像 TA 的结果并生成轻动态视频，最终展示在「星球观察窗」中。

我在项目中负责从**产品定义、AI 模型评测与选型、交互设计，到 iOS / H5 / Backend 的独立开发与上线验证**。工程实现大量借助 Claude / Codex 等 AI Coding 工具完成。

## 项目概览

|       |                                                           |
| ----- | --------------------------------------------------------- |
| 角色    | 产品经理｜独立开发（AI Coding）                                      |
| 产品形态  | iOS App + H5 分享页                                          |
| 商业验证  | 海外 App Store 上线，50+ 付费用户                                  |
| AI 应用 | 参考图生成 → 4 张候选 → 主人选择 → 图生视频                               |
| 模型能力  | Seedream / Seedance 等真实 API 链路已跑通                         |
| 产品边界  | AI 增强纪念表达，不模拟宠物人格                                         |
| 工程形态  | SwiftUI / Next.js / NestJS / PostgreSQL / R2 / StoreKit 2 |

---

## 30 秒看产品

---

## 我解决的核心问题

宠物离世后，照片和故事通常散落在相册、聊天记录和社交平台中。

我希望做的不是另一个“宠物内容产品”，而是一个：

> **可以安静保存回忆、偶尔回来看看，也允许亲近的人轻轻表达关心的地方。**

因此 Pawlight 的核心闭环很简单：

```text
创建 TA 的纪念星球
→ 保存照片与故事
→ 分享给亲友
→ 亲友无需登录打开 H5
→ 轻轻抱抱 TA
→ 主人在 App 内看到抱抱
→ 再次回来看看 TA
```

免费用户也能完整经历这条闭环。

---

## AI 为什么这样做

在宠物纪念场景中，模型最严重的错误不是“画得不好看”，而是：

> **主人觉得这已经不是自己的宠物。**

因此我把模型评测中的“身份保持”放在画面美感之前。

产品也没有采用：

```text
照片 → AI → 自动替换最终结果
```

而是：

```text
主照片 + 场景描述
→ 生成 4 张候选
→ 主人选择最像 TA 的一张
→ 图生视频
→ 星球观察窗
```

这里模型负责扩大候选空间，主人保留最终身份判断权。

同时，真实主照片始终保留，AI 内容可以随时撤销。

更完整的模型评测和选型过程见：

[**AI 模型评测与选型**](docs/portfolio/ai-model-evaluation.md)

---

## 我刻意没有做什么

Pawlight 使用 AI，但不做：

- AI 替宠物回复主人；
- 模拟宠物长期人格；
- AI 陪聊；
- “TA 回来了”式复活叙事；
- 宠物社区、排行榜、公共 Feed；
- 任务、签到和游戏化养成。

AI 在这里负责的是：

> **纪念表达。**

而不是：

> **人格代理。**

关键产品取舍见：

[**产品决策复盘**](docs/portfolio/product-decisions.md)

---

## 从产品方案到真实系统

Pawlight 不是单页 Demo。

当前包含：

```text
iOS / SwiftUI
        │
        ▼
NestJS Backend ── PostgreSQL
      │
      ├──────── Cloudflare R2
      ├──────── StoreKit / Apple Verification
      └──────── Image / Video Provider

H5 / Next.js
      │
      └──────── Public Memorial / Hug
```

已经实现：

- Sign in with Apple；
- StoreKit 2 与服务端支付验证；
- H5 分享和隐私权限；
- Hug 去重与并发保护；
- 图片 / AI 视频对象存储；
- AI 异步任务状态机；
- 图像 / 视频 Provider 抽象；
- 删除账号时的数据与对象存储清理。

我大量使用 AI Coding 提高开发效率，但产品规则、数据边界、模型方案、验收标准和最终 Review 由我负责。

完整过程见：

[**独立开发 Case Study**](docs/portfolio/independent-build.md)

---

## 工程质量

当前 Backend 已建立核心业务自动化测试：

```text
Lint                  0 error / 0 warning
Unit / Contract       92 tests passed
E2E                    8 tests passed
Backend build          passed
H5 lint / build        passed
iOS simulator build    passed
```

真实生成模型不在 CI 中反复调用，而通过独立 Live Smoke Test 验证。

技术细节：

- [Architecture](docs/reference/architecture.md)
- [Data Model](docs/reference/data-model.md)
- [API Reference](docs/reference/api-reference.md)
- [State Machines](docs/reference/state-machines.md)
- [AI Provider Integration](docs/reference/ai-provider-integration.md)
- [Testing](docs/reference/testing.md)

---

## 当前已知边界

Pawlight 仍然是资源有限条件下的独立产品。

当前 AI 长任务仍由 Web Server 进程内异步执行，没有引入独立 Queue / Worker；iOS / H5 也尚未建立完整客户端行为自动化测试。

这些是我明确知道并接受的当前技术债，而不是为了作品集强行隐藏的问题。

---

## 文档导航

如果只看三份补充材料：

1. [**AI 模型评测与选型**](docs/portfolio/ai-model-evaluation.md)
2. [**产品决策复盘**](docs/portfolio/product-decisions.md)
3. [**独立开发 Case Study**](docs/portfolio/independent-build.md)

当前产品事实：

- [Product Spec](docs/reference/product-spec.md)
- [Docs Index](docs/README.md)

---

Pawlight 对我最大的意义并不是“独立写了一个 App”。

而是让我完整经历了：

> **判断一个场景是否应该使用 AI → 找到模型最昂贵的错误 → 设计模型评测与产品兜底 → 把产品做上线 → 获得真实用户与付费验证。**
