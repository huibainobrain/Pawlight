# Pawlight

> 为离开的宠物留下一颗温柔、私密、可以反复回看的纪念星球。

Pawlight 是我独立推进的一款 **AI 宠物纪念产品**，已上线海外 App Store，并获得 **50+ 付费用户**。

产品以真实照片与回忆为基础，通过 **AI 场景生成、动态「星球观察窗」和低频「星球生活」**，让纪念内容从一次保存延伸为可以持续回看的体验。

产品设计重点解决三个问题：**模型是否真的适合这个场景、AI 内容怎样保持可控、长期内容怎样保持新鲜而不过度打扰。**

## 项目概览

|  |  |
| --- | --- |
| 角色 | 产品经理｜独立开发 |
| 产品形态 | iOS App + H5 分享页 |
| 真实验证 | 海外 App Store 上线，50+ 付费用户 |
| 核心体验 | 纪念空间 / AI 场景 / 星球观察窗 / 星球生活 |
| AI 使用方式 | 主动场景生成 + 人工确认 + 低频自动纪事 + 质量兜底 |
| 商业设计 | 买断制纪念权益 + 单次付费礼物 |
| 产品边界 | AI 扩展纪念表达，不模拟宠物人格，不做养成游戏 |

**重点材料：**

1. [AI 模型评测与选型](docs/portfolio/ai-model-evaluation.md)
2. [AI 内容系统设计](docs/portfolio/ai-content-system.md)
3. [产品决策复盘](docs/portfolio/product-decisions.md)
4. [独立开发 Case Study](docs/portfolio/independent-build.md)

---

## 30 秒看产品

### 1. 创建纪念星球

<p align="center">
  <img src="https://github.com/user-attachments/assets/9a736528-35e3-4b44-a664-90bbdcfb9be1" width="240" alt="01-onboarding" />
  <img src="https://github.com/user-attachments/assets/9f6227b6-1496-4a90-b4b4-8618b63402db" width="240" alt="02-pet-info" />
  <img src="https://github.com/user-attachments/assets/c7cd1435-3d45-4428-9ae5-2c1f52bb6260" width="240" alt="03-main-photo" />
</p>

主人可以为 TA 建立独立的纪念星球，保存真实照片、故事与回忆，并决定哪些内容只留给自己、哪些内容可以分享给亲友。

### 2. AI 场景与星球观察窗

<p align="center">
  <img src="https://github.com/user-attachments/assets/7a70bf7e-fa8c-4d10-a84b-f28520b0ac1d" width="240" alt="04-tier-select" />
  <img src="https://github.com/user-attachments/assets/8b4512db-c107-4fe5-aaef-bdf83d16df12" width="240" alt="05-scene-input" />
  <img src="https://github.com/user-attachments/assets/c1656543-9ec5-44a1-8ce0-d2acba251963" width="240" alt="06-candidates" />
</p>

主人描述一个希望看到 TA 出现的场景，系统基于真实宠物照片生成候选画像，由主人选择最像 TA 的结果，再生成轻动态视频并展示在「星球观察窗」中。

**AI 场景生成与星球观察窗效果：**

https://github.com/user-attachments/assets/97a828cd-6919-4d33-a49e-28a9532b5648

点击「陪我一会儿」，还可以把已有动态场景以系统画中画的方式带到 App 之外。

### 3. 星球生活

除了主人主动生成场景，Pawlight 也会以低频、不固定的节奏留下 TA 在小世界中的新纪事，每条纪事由图片和短文本组成。

主人也可以「给 TA 留点什么」：一次赠礼对应一次独立付费，并会在之后合适的纪事中自然出现，而不是变成背包、数值或养成道具。

### 4. 回忆与亲友分享

<p align="center">
  <img src="https://github.com/user-attachments/assets/380e96d6-14f7-490f-8125-d3f20aee96de" width="240" alt="07-memory-tab" />
  <img src="https://github.com/user-attachments/assets/6b0e2c4a-5090-497e-890d-e6a5d23a96a6" width="240" alt="08-story-edit" />
  <img src="https://github.com/user-attachments/assets/48324681-7c82-4f91-b7b6-d73f6442c3e7" width="240" alt="09-album" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/c8dfe93c-f871-48e2-99c7-3d2544e828fe" width="240" alt="10-mailbox" />
  <img src="https://github.com/user-attachments/assets/7d9d20e1-7d0d-4d4a-a868-d444fae40461" width="240" alt="11-hugs" />
</p>

真实照片、故事与来信始终保留在独立的回忆空间中，与 AI 想象内容区分。

亲友无需安装 App 或登录，即可通过 H5 分享页查看主人公开的纪念内容，并「轻轻抱抱 TA」。

<details>
<summary>展开查看完整 H5 分享页</summary>

<br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/1e93fc8e-2cef-498a-a2be-5654743d55ae" width="420" alt="12-h5-share" />
</p>

</details>

---

## 三个核心产品问题

### 01｜如何让 AI 生成的仍然是「TA」？

在宠物纪念场景里，模型最昂贵的错误不是「画得不好看」，而是：

> **主人觉得这已经不是自己的宠物。**

因此模型选型不能只看审美。我围绕真实产品链路完成 **3 款候选图片模型、10 个宠物 / 场景用例、每个模型 2 次生成，共 60 张结果**的评测，重点比较身份保持、场景实现、审美与指令遵从、稳定性以及成本。

评测之外，产品链路也没有把一次生成直接当作最终答案：

```text
真实照片 + 场景描述
→ 生成 4 张候选
→ 主人选择最像 TA 的一张
→ 图生视频
→ 星球观察窗
```

模型负责扩大候选空间，主人保留最终身份判断权；真实照片始终是宠物身份的事实来源。

[**查看完整模型评测与选型过程 →**](docs/portfolio/ai-model-evaluation.md)

---

### 02｜如何把开放生成变成可控、可扩展的内容系统？

一次 AI 场景生成主要解决「这一张像不像 TA」；进入长期「星球生活」后，如果让模型每次自由决定 TA 去哪里、做什么，很快就会出现重复、行为失真、前后矛盾，甚至越过纪念产品的情绪边界。

因此我没有把完整故事直接交给模型，而是先把内容拆成可组合资产：

```text
地点：小花园 / 湖边 / 林间
行为：休息 / 散步 / 玩耍
时间：白天 / 黄昏
环境：晴朗 / 微风 / 花草
```

再由事件模板限定合理组合：

```text
内容资产
→ 事件模板限定可发生的组合
→ 系统确定本次「发生什么」
→ AI 完成图片与短文本表达
→ 质量检查 / 失败重试
→ 发布星球纪事
```

核心原则是：

> **规则确定事实，AI 负责表达。**

模板与兼容规则约束物种、地点、行为和礼物之间的关系；新增内容时主要扩充资产和模板，而不是不断改写 Prompt。

对于会反复出现的家园场景，系统还保存稳定的家园设定与视觉锚点，避免同一个小世界在不同纪事中不断「变样」。生成结果则通过质量检查、失败重试和 Bad Case 回滚处理模型的不确定性。

[**查看 AI 内容系统设计 →**](docs/portfolio/ai-content-system.md)

---

### 03｜如何让长期内容有期待感，而不是变成另一个 Feed？

「星球生活」不是无限生成的内容流。目标不是让用户每天回来，而是让用户偶尔打开 Pawlight 时仍然有新的内容，同时不产生未读和提醒压力。

因此内容采用 **低频、非固定间隔**产生，同一时间最多保留一条未读；用户阅读后才重新进入下一轮等待。模板通过权重和冷却控制重复，让熟悉的世界保持变化，而不是每天制造「新剧情」。

商业化也遵循同样的克制原则。「礼物」不是永久解锁的养成道具，而是主人一次主动介入星球生活的行为：

```text
选择礼物
→ 单次付费
→ 形成一次独立赠礼
→ 在后续 1–3 条有效纪事内完成回应
```

只有成功发布、内容与礼物一致且通过质量检查的纪事才算完成履约；生成或质检失败不会直接消耗这次赠礼。

---

## 我刻意没有做什么

Pawlight 使用 AI，但不把宠物变成一个需要被持续「养」的 AI 角色：

- 不替宠物回复主人，也不长期模拟宠物人格；
- 不把 AI 想象包装成真实的「来世事实」；
- 不做公共 Feed、排行榜和社交竞争；
- 不做签到、任务、等级、金币等养成式游戏化。

核心边界是：

> **AI 可以扩展纪念表达，但不能替代真实宠物，也不能替主人定义 TA 的人格。**

[**查看产品决策复盘 →**](docs/portfolio/product-decisions.md)

---

## 从产品方案到真实系统

Pawlight 不是单页 Demo，而是由 iOS App、H5 与后端共同组成的完整产品：

```text
iOS / SwiftUI
        │
        ▼
NestJS Backend ── PostgreSQL
      │
      ├──────── Cloudflare R2
      ├──────── StoreKit / Apple Verification
      └──────── Generation / Quality Providers

H5 / Next.js
      │
      └──────── Public Memorial / Hug
```

当前系统已经覆盖：

- 账户、支付、隐私权限与 H5 分享互动；
- AI 图片 / 视频异步生成、对象存储与星球观察窗；
- 系统画中画「随身观察窗」；
- 星球生活的事件调度、内容模板、家园一致性与质量检查；
- 单次礼物购买、Pending 状态、后续内容履约与异常回滚；
- 账号删除时的数据与对象存储清理。

开发过程中使用 Claude / Codex 等 AI Coding 工具提高实现效率；**产品规则、模型方案、数据边界、验收标准与最终 Review 由我负责**。

[**查看独立开发 Case Study →**](docs/portfolio/independent-build.md)

---

<details>
<summary><strong>工程实现与测试</strong></summary>

<br>

```text
Backend Unit / Contract    149+ tests passed
Backend E2E                 24+ tests passed
Backend build / lint        passed
iOS Debug build             passed
```

真实生成模型不在 CI 中反复调用，而通过独立测试流程验证模型效果与正式调用链路。

技术参考：

- [Architecture](docs/reference/architecture.md)
- [Data Model](docs/reference/data-model.md)
- [API Reference](docs/reference/api-reference.md)
- [State Machines](docs/reference/state-machines.md)
- [AI Provider Integration](docs/reference/ai-provider-integration.md)
- [Testing](docs/reference/testing.md)

当前 AI 长任务沿用现有后端异步机制，没有额外引入独立 Queue / Worker；客户端自动化测试也仍以核心链路和构建验证为主。这些是当前产品规模下主动接受的工程取舍。

</details>

---

Pawlight 的核心不是增加更多生成能力，而是：

> **把不确定的模型能力，变成可控、可持续、真正可以长期使用的产品体验。**
