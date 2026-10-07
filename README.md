# Pawlight

> 为离开的宠物留下一颗温柔、私密、可以反复回看的纪念星球。

Pawlight 是我独立设计并开发的一款 **AI 宠物纪念产品**，已上线海外 App Store，并获得 **50+ 付费用户**。

产品以真实照片和回忆为基础，逐步扩展出 AI 场景画像、动态「星球观察窗」和低频「星球生活」。我主要在这个项目中解决三个问题：

**模型怎么选、AI 内容怎么控、长期生成怎么稳定运行。**

|  |  |
| --- | --- |
| 角色 | 产品经理 / 独立开发 |
| 产品形态 | iOS App + H5 |
| AI 能力 | 图片模型评测、场景生成、长期内容生成、质量控制 |
| 商业设计 | 买断制纪念权益 + 单次付费礼物 |
| 产品边界 | AI 扩展纪念表达，不模拟宠物人格 |

**重点材料：**  
[模型评测与选型](docs/portfolio/ai-model-evaluation.md) · [AI 内容系统](docs/portfolio/ai-content-system.md) · [产品决策](docs/portfolio/product-decisions.md) · [独立开发](docs/portfolio/independent-build.md)

---

## 30 秒看产品

### 创建纪念空间

<p align="center">
  <img src="https://github.com/user-attachments/assets/9a736528-35e3-4b44-a664-90bbdcfb9be1" width="240" alt="01-onboarding" />
  <img src="https://github.com/user-attachments/assets/9f6227b6-1496-4a90-b4b4-8618b63402db" width="240" alt="02-pet-info" />
  <img src="https://github.com/user-attachments/assets/c7cd1435-3d45-4428-9ae5-2c1f52bb6260" width="240" alt="03-main-photo" />
</p>

用户可以保存照片、故事、纪念语和私密信件，并通过 H5 分享给亲友；访客无需登录即可查看并「轻轻抱抱 TA」。

### AI 场景与观察窗

<p align="center">
  <img src="https://github.com/user-attachments/assets/7a70bf7e-fa8c-4d10-a84b-f28520b0ac1d" width="240" alt="04-tier-select" />
  <img src="https://github.com/user-attachments/assets/8b4512db-c107-4fe5-aaef-bdf83d16df12" width="240" alt="05-scene-input" />
  <img src="https://github.com/user-attachments/assets/c1656543-9ec5-44a1-8ce0-d2acba251963" width="240" alt="06-candidates" />
</p>

~~~text
真实照片 + 用户场景
→ 生成 4 张候选
→ 用户选择最像 TA 的一张
→ 图生视频
→ 星球观察窗
~~~

**实际效果：**

https://github.com/user-attachments/assets/97a828cd-6919-4d33-a49e-28a9532b5648

用户还可以通过「陪我一会儿」将动态观察窗以系统 PiP 的方式带到 App 外。

### 星球生活

系统会以低频、不固定的节奏生成新的「星球纪事」。

与自由故事生成不同，纪事先由**地点、行为、时间、环境等结构化内容**确定本次发生的事实，再由 AI 生成图文。

用户也可以单次购买礼物，让礼物在后续合适的纪事中出现。

---

## 三个核心设计

### 1. 身份保持优先于“画得好看”

在宠物纪念场景中，最严重的错误不是审美不好，而是：

> **“这已经不是我的宠物。”**

因此我围绕身份保持建立模型评测体系，对 **3 个模型、60 张结果**进行统一评测，并在产品链路中保留用户最终确认环节。

[查看模型评测 →](docs/portfolio/ai-model-evaluation.md)

### 2. 规则确定事实，AI 负责表达

长期生成没有直接采用自由故事模式，而是：

~~~text
内容资产
→ Event Template
→ 确定 Event Facts
→ AI 生成图文
→ Quality Check
→ 发布
~~~

宠物身份始终来自真实照片；Planet Style、Home Profile 与 Home Anchor 则负责长期世界一致性。

[查看 AI 内容系统 →](docs/portfolio/ai-content-system.md)

### 3. 不把长期内容做成 Feed

星球生活采用低频生成、单条未读、阅读后重新计时、模板权重与冷却等机制。

目标不是提高每天打开次数，而是：

> **让用户偶尔回来时，仍然能看到一点新的东西。**

礼物同样被设计为一次内容介入，而不是背包、等级或养成系统。

---

## 产品边界

Pawlight 明确不做：

- 宠物 AI 聊天或人格模拟；
- “TA 回来了”式复活叙事；
- 公共 Feed / 排行 / 评论；
- 签到、任务、等级等养成机制。

真实回忆记录过去真正发生的事；AI 内容只负责扩展纪念表达。

---

## 从产品方案到真实系统

产品目前覆盖：

~~~text
iOS / SwiftUI
H5 / Next.js
NestJS Backend
PostgreSQL
Cloudflare R2
StoreKit
Generation / Quality Providers
~~~

核心业务已覆盖 **159+ Unit / Contract Tests、28+ E2E Tests**。

开发过程中大量使用 Claude / Codex 等 AI Coding 工具；产品规则、模型方案、系统边界、验收标准与最终 Review 由我负责。

[查看独立开发 Case Study →](docs/portfolio/independent-build.md)

---

> **Pawlight 最重要的不是“用了 AI”，而是把不确定的模型能力变成了可控、可持续的产品体验。**
