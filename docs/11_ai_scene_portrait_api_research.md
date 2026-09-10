# 11 AI 场景画像功能 — 图像生成 API 调研

> 状态：调研稿 / 待决策
> 日期：2026-09-10
> 关联：[01 产品范围](01_product_scope_summary.md) · [06 上传存储支付](06_upload_storage_payment.md) · [10 开放问题与风险](10_open_questions_and_risks.md)

---

## 0. 功能定义

用户基于已上传的宠物照片 + 一段自然语言场景描述，生成"宠物在该场景下的动漫形象"，可将其设为**首页星球观察窗**的图片。

- 输入：1~N 张宠物照片 + 场景文本（如"在樱花树下打盹""坐在窗台看夕阳"）
- 输出：单张动漫风格图，宠物身份高度还原
- **第一优先级：宠物身份保持** —— 花色/斑纹、体型、耳形、眼睛颜色、面部特征必须与本尊一致。丧宠场景下，"画得不像"是会造成情感伤害的失败，比"画得不好看"严重得多。

底层就是接一个图生图 / 参考图编辑 API：`照片 + 场景描述 → 对应场景的动漫图`。

---

## 1. 结论速览（TL;DR）

| 决策项 | 建议 |
| --- | --- |
| 技术路线 | **零样本参考图编辑**（不做每宠微调），MVP 够用；微调作为画质投诉后的保底升级路径 |
| 主力 API | **Google Nano Banana Pro**（`gemini-3-pro-image`）—— 当前主体一致性 + 场景/光照融合公认最强 |
| 候选生成用 | **Nano Banana 2**（`gemini-3.1-flash-image`）或 **Seedream 5.0 Lite** —— 便宜快，用来一次出 3~4 张草稿 |
| 国内友好备选 | **ByteDance Seedream 5.0**（火山引擎国内直连）；或 **FLUX.2 [pro] Edit**（经 fal.ai / Replicate） |
| 保底方案 | 单宠 **LoRA 微调**（fal.ai / Replicate / Astria），仅在零样本还原度不达标时启用 |
| 成本量级 | 每次"生成尝试"（3 张草稿 + 定稿）约 **$0.1~0.4**，取决于模型档位；需做次数限制 |
| 架构 | 后端异步任务（Postgres job 表 + iOS 轮询/APNs），图片存 R2，与现有照片链路一致 |
| 产品定位 | 对外叫"纪念画像 / 星球画像"，**绝不叫"AI 生成""复活"**；原始照片始终是默认，画像是可回退的附加项 |

⚠️ 本文所有价格、模型 ID、参数均为 **2026-09 时点的公开信息**，该领域月度迭代，落地前必须以官方文档现价为准。

---

## 2. 技术难点：为什么"宠物身份保持"比想象中难

### 2.1 现成的"身份锁定"技术大多是给人脸做的

市面上强身份保持的方案（InstantID、PhotoMaker、IP-Adapter-FaceID 等）底层依赖**人脸识别 embedding**，在**人脸数据集**上训练。它们对猫狗基本无效 —— 动物没有对应的"面部识别向量"。

因此宠物身份保持只能靠两条路：

1. **通用上下文编辑模型**（Nano Banana / FLUX Kontext / GPT Image / Seedream）—— 不做人脸专门处理，靠模型自身的视觉 token 对齐能力，对动物同样生效。这是目前唯一"零训练"可行的路子。
2. **针对该宠物微调**（DreamBooth / LoRA）—— 用几张到十几张照片教模型一个"专有名词"，之后生成时点名调用。对动物效果好，但要训练。

### 2.2 "保身份"和"换风格"本质是冲突的

核心难题叫 **identity-preserving style transfer**：既要把写实照片变成动漫风，又要在扩散/生成过程中不丢失这一只（而不是这个品种）的独有特征。风格化强度越高，身份漂移风险越大。评测里常见的失败：

- 橘猫变成"标准橘猫"，丢掉它右耳的缺口 / 独有的花纹分布
- 长毛变短毛、圆脸变尖脸
- 眼睛颜色被"美化"（琥珀色 → 蓝色）
- 多次编辑后逐渐偏离（累积漂移）

Google 官方社区也确认 Nano Banana Pro "无法 100% 保持与原图一致"。**没有任何 API 能保证一次成功**，这决定了产品侧必须做"多候选 + 用户选择 + 有限次重生成"。

### 2.3 输入照片质量是最大变量

清晰、正面、光照均匀、宠物占画面主体的照片，效果显著好于模糊/侧脸/暗光/远景。丧宠用户手里的照片往往参差不齐，需要在交互上引导用户挑最好的几张，并对低质量输入给预期管理。

---

## 3. 两条技术路线

### 3.1 路线 A：零样本参考图编辑（推荐用于 MVP）

**流程**：用户选 1~3 张照片 + 场景文本 → 拼 prompt → 调 API → 出图。

| 优点 | 缺点 |
| --- | --- |
| 零训练、无每宠存储成本 | 还原度上限略低于微调，疑难 case（特征复杂/花色罕见）可能翻车 |
| 首图延迟 4~20s，用户体验可接受 | 依赖 prompt 工程 + 多候选来兜底 |
| 单张成本 $0.02~0.15 | |
| 只要几张甚至 1 张照片就能跑 | |

对"纪念画像"这种**艺术化、非鉴证级**的诉求，现代零样本模型（尤其 Nano Banana Pro）的还原度已经够用。**MVP 就走这条。**

### 3.2 路线 B：单宠 LoRA / DreamBooth 微调（画质保底方案）

**流程**：用户上传 8~15 张该宠物照片 → 触发训练（约 10 分钟）→ 得到一个专属 LoRA → 之后每次生成点名调用。

| 优点 | 缺点 |
| --- | --- |
| 还原度最高，能吃下罕见花色 / 复杂特征 | 需要 8~15 张多角度照片，很多丧宠用户凑不齐 |
| 训练一次，之后无限次生成都稳定 | 训练延迟 10+ 分钟，需额外的任务态和 UI |
| | 训练成本约 $1~3 / 宠 + 每宠 LoRA 权重存储 |
| | 平台：fal.ai、Replicate、Astria（均有 API） |

**建议**：不进 MVP。作为"零样本结果用户不满意"时的付费升级项，或未来版本能力。

---

## 4. 候选 API 逐个评估

### 4.1 Google Nano Banana 家族（Gemini 3 Pro / 3.1 Flash Image）★ 首选

四个型号（`ai.google.dev/gemini-api/docs/image-generation`）：

| 型号 | Model ID | 定位 | 参考图上限 | 分辨率 | 备注 |
| --- | --- | --- | --- | --- | --- |
| Nano Banana Pro | `gemini-3-pro-image` | 旗舰，复杂指令 | **5 张角色 + 6 张物体** | 1K/2K/4K | 主体一致性 + 场景光照融合最强 |
| Nano Banana 2 | `gemini-3.1-flash-image` | 主力干活 | 4 张角色 + 10 物体 + 3 风格 | 最高 4K | 性价比高，适合出候选 |
| Nano Banana 2 Lite | `gemini-3.1-flash-lite-image` | 最快最便宜 | 14 物体（**无角色参考位**）| 仅 1K | 身份保持偏弱，仅适合粗草稿 |
| Nano Banana（老） | `gemini-2.5-flash-image` | legacy | — | — | 不建议新接 |

- **身份/主体一致性**：★★★★★ 评测普遍认为是当前最强，且"连光照都能保持一致"。宠物花色/比例跨场景保持能力最好。
- **场景融合**：★★★★★ 主体和背景自然交互、光影氛围统一 —— 直接命中"宠物在场景下"的需求。
- **动漫风格化**：★★★★ 动漫脸更干净、畸变少；但风格迁移时偶尔会轻微改动细节。
- **图像编辑**：支持 text-and-image-to-image + 多轮对话式编辑（可"再把耳朵调回来一点"）。
- **宽高比**：`1:1 / 3:2 / 2:3 / 3:4 / 4:3 / 4:5 / 5:4 / 9:16 / 16:9 / 21:9` —— 观察窗按需选。
- **水印**：所有输出含**隐形 SynthID**；**API / 付费档输出没有可见水印**（可见的"Gemini 星芒"只加在免费网页版）。→ 观察窗可用。
- **延迟**：简单 2~5s；4K 默认 15~20s，调 `thinking_level=low` + 用 2K 可压到 8s 内。
- **价格**（付费 Standard API）：约 **$0.134 / 张（1K~2K）**、$0.24 / 张（4K）。token 计价 $2/M 输入、$120/M 输出。
- **国内可用性**：❌ Gemini API 中国大陆不直连。**从 Railway（美国）后端调用没问题**；本地开发调试需科学上网，或走中转。
- **发布**：Nano Banana Pro 2026-06-18。

### 4.2 Black Forest Labs FLUX.2 [pro] Edit / FLUX.1 Kontext ★ 备选/AB

- **FLUX.2 [pro] Edit**（2025-11-25 发布）：文本 + 一张或多张参考图，做定向编辑、主体替换、风格迁移、**多参考图身份一致生成**。支持 **最多 8 张参考图**，编辑精度到 4MP。
  - 价格：**$0.03 / 百万像素**（2K ≈ 2.1MP ≈ $0.063 / 张；1 credit = $0.01）。
  - 渠道：BFL 官方 API、fal.ai、Replicate、OpenRouter。
  - 特点：纹理更写实、更"实"，风格化不如 Nano Banana 灵。动物特征保持在动漫化测试中"全部保留"，但背景融合不如 Nano Banana 自然。
- **FLUX.1 Kontext [pro]**：上一代上下文编辑模型，更便宜（约 $0.04/张，1MP），仍可用作低成本档。
- **水印**：无强制可见水印。
- **国内可用性**：⚠️ 官方 API 需海外网络；经 fal.ai / Replicate 同样在海外。
- **价值**：作为 Nano Banana 被内容策略拦截时的 fallback，或做 A/B 对比。

### 4.3 OpenAI GPT Image 2

- 发布 2026-06-24（稳定版约 2026-04）。多图参考理解 + 自然语言控制强，被部分评测称为"2026 最强通用图像模型"。
- 价格：token 计价 $5/M 输入、$30/M 输出。折算单张 1024²：低质 ~$0.006 / 中质 ~$0.053 / **高质 ~$0.21**；1024×1536 高质 ~$0.165。
- 延迟：偏慢，10~30s。
- 水印：C2PA 元数据（非画面可见水印）。
- 国内可用性：❌ 不直连，从美国后端调用可行。
- **评估**：能力够，但**单张高质成本是 Nano Banana Pro 的 ~1.5 倍、Seedream 的 ~5 倍**，且身份一致性口碑不如 Nano Banana 突出。列为第三选择。

### 4.4 ByteDance Seedream 5.0（Pro / Lite）★ 国内友好首选

- **Seedream 5.0 Pro**：$0.045/张（标准）、$0.09/张（高分辨率）、$0.003/张（图像输入）。
- **Seedream 5.0 Lite**：$0.035/张，比上一代便宜。
- 特点：高保真、写实感强，适合"定稿级"输出；风格化灵活度中等。
- 渠道：**火山引擎（国内直连、中文文档、可开发票）**；海外经 fal.ai / OpenRouter / Vercel AI Gateway。
- 水印：随渠道。
- **价值**：如果希望**国内低延迟 / 国内合规 / 人民币结算**，Seedream 是最现实的主力。质量与 Nano Banana 有差距但不大，成本只有其 ~1/3。

### 4.5 Alibaba Qwen-Image-Edit（开源，可自部署）

- **Apache 2.0 开源**，权重可下载，可本地/自有 GPU 部署。
- 强项：场景理解、多语言文字准确、跨帧连续性（角色不崩）；写实度不是强项。
- 渠道：阿里云 DashScope API（国内，价格低）或 fal.ai，或自部署。
- **价值**：如果未来量大到 API 费用敏感，自部署可把边际成本压到接近电费。MVP 阶段不必自部署（运维成本 > 省下的钱）。

### 4.6 微调路线平台（保底方案用）

| 平台 | 能力 | 备注 |
| --- | --- | --- |
| **fal.ai** | FLUX LoRA 训练 + 推理，异步 + webhook | 训练约 10 min；API 成熟 |
| **Replicate** | FLUX / SDXL DreamBooth 训练，按 GPU 秒计费 | 生态大，冷启动稍慢 |
| **Astria** | 专门做微调 API，官方文档明确支持宠物 | 面向"训练一个专属模型"场景 |

### 4.7 聚合层：fal.ai vs Replicate

两者都提供统一 HTTP/WebSocket 接口、异步提交 + webhook 回调、按图或按 GPU 秒计费，单图 $0.008~0.04。

| | fal.ai | Replicate |
| --- | --- | --- |
| 速度 | 更快（1~4s 级调度） | 稍慢（2~8s） |
| 模型覆盖 | FLUX / Seedream / Nano Banana / Kling / Qwen 等 | 同类 + 社区模型更多 |
| 适合 | 生产低延迟 | 快速试验、非主流模型 |

**建议**：用聚合层做前期选型对比（一套代码切多个模型），主力模型确定后，Nano Banana 直连 Google、Seedream 直连火山，减少一层加价和依赖。

---

## 5. 横向对比表

综合评测口径（非硬 benchmark），5 星制：

| 模型 | 宠物身份保持 | 场景融合 | 动漫风格化 | 延迟 | 单张价格(≈) | 国内直连 | 画面水印 |
| --- | :---: | :---: | :---: | :---: | --- | :---: | --- |
| **Nano Banana Pro** | ★★★★★ | ★★★★★ | ★★★★ | 5~20s | $0.13 (2K) / $0.24 (4K) | ❌ | 仅隐形 SynthID |
| Nano Banana 2 | ★★★★ | ★★★★ | ★★★★ | 4~8s | < Pro | ❌ | 隐形 SynthID |
| Nano Banana 2 Lite | ★★★ | ★★★ | ★★★ | ~4s | $0.017~0.034 | ❌ | 隐形 SynthID |
| FLUX.2 [pro] Edit | ★★★★ | ★★★★ | ★★★ | 5~15s | ~$0.06 (2K) | ⚠️ 经聚合层 | 无 |
| FLUX.1 Kontext [pro] | ★★★★ | ★★★ | ★★★ | 4~10s | ~$0.04 (1MP) | ⚠️ | 无 |
| GPT Image 2 | ★★★★ | ★★★★ | ★★★★ | 10~30s | ~$0.05 中 / ~$0.21 高 | ❌ | C2PA 元数据 |
| Seedream 5.0 Pro | ★★★★ | ★★★★ | ★★★ | 5~15s | $0.045 / $0.09 高清 | ✅ 火山引擎 | 随渠道 |
| Seedream 5.0 Lite | ★★★ | ★★★ | ★★★ | 快 | $0.035 | ✅ | 随渠道 |
| Qwen-Image-Edit（自部署） | ★★★ | ★★★★ | ★★★ | 自定 | ≈ GPU 电费 | ✅ 阿里云 | 自控 |
| 单宠 LoRA 微调 | ★★★★★ | ★★★★ | ★★★★ | 训练10min+推理 | 训练 $1~3 + 每图 $0.01~0.05 | ⚠️ | 自控 |

---

## 6. 推荐方案

### 6.1 MVP（零样本 + 双模型分工）

```
候选草稿：Nano Banana 2 (gemini-3.1-flash-image)  —— 一次出 3~4 张，便宜快
用户选中后定稿/高清化：Nano Banana Pro (gemini-3-pro-image) 2K —— 只对最终 1 张花旗舰的钱
```

- 这样每次尝试成本 ≈ 3×(便宜档) + 1×(旗舰档) ≈ $0.1~0.2，而不是全程旗舰的 $0.5+。
- 全部经 Railway 后端调用 Google API（美国 egress，可达）。

### 6.2 如果要国内主力 / 人民币结算

主力换 **Seedream 5.0 Lite 出候选 + Seedream 5.0 Pro 定稿**，走火山引擎。质量略降、成本更低、国内延迟更好、合规更简单。

### 6.3 fallback 链

`主模型内容策略拦截 / 超时` → 自动降级到备选模型（FLUX.2 Edit 或另一家）重试一次 → 仍失败则返回友好错误 + 不计次数。

### 6.4 保底升级

上线后如果收到明显的"画得不像"反馈聚集 → 对该宠物启用 **fal.ai FLUX LoRA 微调**（引导用户补传照片），作为付费增值项。

---

## 7. 端到端架构设计

```
iOS
 └─ 用户选 1~3 张已上传照片 + 输入场景文本 + 选宽高比
      │  POST /api/v1/pets/:id/scene-portraits   {photoIds[], sceneText, aspectRatio}
      ▼
NestJS (Railway)
 ├─ 校验：entitlement 是否允许 / 剩余次数 / 输入是动物（moderation）
 ├─ 落库：scene_portrait_job (status=QUEUED)   ← 新增 Prisma 表
 ├─ 拼 prompt（见 §9）+ 取 R2 原图
 ├─ 调图像 API（异步）：先出 N 张候选
 └─ 返回 jobId
      ▼
后端 worker / 同进程 async
 ├─ 收到候选图 → 上传 R2 → job.candidates[] += url, status=CANDIDATES_READY
 └─ （可选）APNs 静默推送通知 iOS "画像好了"
      ▼
iOS 轮询 GET /api/v1/scene-portraits/:jobId
 ├─ 展示 3~4 张候选，用户挑一张 / 全部不满意 → 重新生成（有限次）
 └─ 选定 → POST .../select {candidateId}
      ▼
NestJS
 ├─ （可选）旗舰模型对选中图做 2K 定稿/高清化
 ├─ 存 R2，写入 pet.observationWindowPhotoId
 └─ status=DONE
```

**关键设计点**：

- **不引入 Redis**：现有后端没有队列基建。用 Postgres `scene_portrait_job` 表 + 后端 `setInterval` 轮询 pending job，或直接在请求里 `await`（图像 API 本身几秒到几十秒，用 fal.ai 的 webhook 回调更干净）。与项目"最小基建"取向一致。
- **图片一律进 R2**：和现有 photos 链路复用，观察窗读的还是一个 URL。
- **观察窗字段独立**：新增 `pet.observationWindowPhotoId`，与 `mainPhotoId` 分开。用户可随时切回真实主照片（见 §10）。
- **幂等 / 防刷**：jobId 幂等；每次生成扣次数在"候选出图成功"时扣，不在"发起"时扣。
- **审核**：
  - 输入图：调用一次视觉判断"是否包含猫/狗/小动物"，非动物直接拒。
  - 场景文本：过滤明显不当内容（暴力、成人、真人名人等），可用一个便宜的文本审核。

---

## 8. 成本测算

假设：付费用户（¥29.9 ≈ $4.1 一次性）可用该功能；每次"生成尝试" = 3 张候选 + 1 张定稿；用户平均 2 次尝试后满意。

| 方案 | 每次尝试 | 平均每用户（2 次） | 占客单价 |
| --- | --- | --- | --- |
| 全程 Nano Banana Pro 2K | 4 × $0.134 ≈ $0.54 | ≈ $1.08 | ~26% ❌ 太高 |
| **Nano Banana 2 候选 + Pro 定稿** | 3×(~$0.04) + 1×$0.134 ≈ $0.25 | ≈ $0.50 | ~12% ⚠️ 可控 |
| Seedream 5.0 Lite 候选 + Pro 定稿 | 3×$0.035 + 1×$0.09 ≈ $0.20 | ≈ $0.40 | ~10% |
| 全程 Seedream 5.0 Lite | 4 × $0.035 ≈ $0.14 | ≈ $0.28 | ~7% ✅ 最省 |

外加图像输入 token（每次 $0.003~0.01，可忽略）。

**控成本手段**：

1. **次数限制**：付费用户含 1 次完整生成（3 候选 + 2 次重生成），超出走 credit 包（如 ¥6 / 3 次）。
2. **候选用便宜档**，只有定稿花旗舰。
3. **缓存**：同一 `(photoIds, sceneText)` 命中直接返回，不重复调用。
4. 免费用户给 **1 次试用**（强转化钩子），结果打样式水印预览、需付费解锁去水印/设为观察窗。

---

## 9. Prompt 策略

零样本模型的还原度 70% 靠 prompt。后端把用户输入包进固定模板：

```
[固定风格前缀] 统一全 App 的动漫画风，锁定为一种：
  "soft warm anime illustration, gentle pastel palette, painterly light,
   Studio-Ghibli-adjacent, no harsh outlines"
  （和 App 现有插画气质一致，保证所有用户的结果风格统一）

[身份锁定] 从原图提取并显式写出 3~5 个判别性特征：
  "preserve exactly: <品种/体型>, <毛色与花纹分布>, <耳朵形状>,
   <眼睛颜色>, <独有特征如某处斑点/缺耳/胡子颜色>.
   Keep the face structure and markings unchanged."

[场景] 用户输入的自然语言场景（做过审核/清洗）

[负向约束] "do not change breed, do not restyle markings, do not alter
   eye color, no text, no watermark, no human faces"
```

- 品种/毛色等特征可以让一个**便宜的多模态模型先对原图做一次结构化描述**，再填进模板 —— 比让用户手填靠谱。
- 多轮编辑能力（Nano Banana）可用于"微调不满意的局部"：先出图，用户点"耳朵不对" → 第二轮 `"make the left ear match the reference: folded tip"`。
- 宽高比按观察窗实际展示比例固定（避免裁切丢主体）。

---

## 10. 产品与合规风险

### 10.1 与产品定位的张力（重要）

`docs/01` 和 `docs/10` 明确写了 V1 不做 **"AI 宠物复活 / AI 动态宠物"**，且措辞上要求**回避"复活、召回、回复"等词**。

本功能是**静态的、艺术化的纪念画像**，性质上更接近"定制宠物插画"（一个成熟且常见的纪念品类），与"复活"是两回事。但**框架和话术必须极其克制**：

- 对外命名：**"纪念画像""星球画像""为 TA 画一幅"**，绝不用"AI 生成""复活""让 TA 动起来"。
- 交互上：原始照片**永远是默认**，画像是**可一键切回**的附加层，不覆盖、不替换。
- 不做：动图、说话、多表情、"TA 在看你"这类拟人化叙事。
- 建议在 `docs/10` 补一条：本功能是否纳入产品边界，需要产品决策拍板。

### 10.2 情感风险

丧宠用户对"画得不像"的容忍度极低。缓解：

- 永远给 **3~4 张候选**让用户选，而不是直接给一张。
- 明确的"重新生成""调整描述""这张不像哪里"入口。
- 生成前对低质量输入照片给**预期管理文案**（"照片越清晰，画像越像 TA"）。
- 结果页不强推"设为观察窗"，让用户自己决定要不要用。

### 10.3 版权与水印

- Nano Banana：付费 API 输出**无可见水印**，仅隐形 SynthID（不影响观感，且是 AI 透明度合规的加分项）。可商用。
- FLUX / Seedream：确认所选渠道的授权条款允许商用 + 无强制可见水印。
- 生成图归属：主流 API 条款允许商用，但**"像某真人/某版权角色"仍可能有责任**——本功能只处理用户自己的宠物照片，风险低；prompt 负向约束里禁止出现人脸。

### 10.4 内容安全

- 输入照片必须校验是动物（防止拿人脸/不当图生成）。
- 场景文本过滤（暴力、成人、政治敏感、真人名人）。
- 各家 API 自带安全过滤，被拒时要有 fallback 和友好文案，不能让用户对着"无响应"。

### 10.5 国内可用性

- Gemini / OpenAI 国内不直连。**生产环境从 Railway（美国）调用没问题**；本地开发调试需代理。
- 若判断国内用户占比高、或未来要迁国内合规，**Seedream（火山引擎）是更稳的主力选择**。

---

## 11. 上线前验证清单

在写生产代码前，先用聚合层（fal.ai）花 $20~30 跑一轮实测：

- [ ] 收集 10~15 只真实宠物照片，覆盖：纯色 / 复杂花纹 / 长毛 / 短毛 / 深色（黑猫黑狗最难）/ 侧脸 / 暗光
- [ ] 每只 × 3 个场景 × 候选模型（Nano Banana Pro / Seedream 5.0 / FLUX.2 Edit）各出 3 张
- [ ] 人工打分：花色还原、体型还原、特征还原、风格统一度、场景合理度
- [ ] 特别测"黑猫黑狗"和"复杂三花/奶牛猫"—— 这两类是零样本模型的公认弱项，决定了要不要上微调
- [ ] 确认所选模型付费档输出**确无可见水印**
- [ ] 确认从 Railway 区域调用的实际延迟（p50 / p95）
- [ ] 确认内容策略：宠物照 + 常见场景描述的**拒绝率**
- [ ] 核算：按预估使用率，月度 API 成本 vs 付费转化增量

---

## 12. 开放问题

1. **是否纳入产品边界** —— 需产品决策：这是"纪念画像"还是滑向了"AI 复活"？（倾向：可做，但话术严格约束）
2. **免费 / 付费边界** —— 免费给不给试用？给几次？定稿去水印是不是付费点？
3. **主力模型** —— 走 Google（质量最优、需美国 egress）还是火山 Seedream（国内友好、成本低、质量够）？取决于目标用户地域分布。
4. **异步基建** —— 接受"请求内 await 几十秒"还是上 job 表 + 轮询 / webhook？
5. **微调** —— 是否从一开始就把"补传照片 → 训练专属画像模型"作为付费增值项规划进去？
6. **观察窗以外的复用** —— 生成的画像能不能也用在 H5 分享页、纪念主页头图？（会放大"AI 生成"在对外场景的暴露面，需谨慎）

---

## 附：信息来源

- [Gemini API — Image generation 官方文档](https://ai.google.dev/gemini-api/docs/image-generation)
- [Nano Banana Pro (Gemini 3 Pro Image) — OpenRouter 定价](https://openrouter.ai/google/gemini-3-pro-image)
- [Nano Banana API Pricing 2026 — myarchitectai](https://www.myarchitectai.com/blog/nano-banana-api-pricing)
- [Nano Banana Pro 速度优化实测 — apiyi](https://help.apiyi.com/en/nano-banana-pro-speed-optimization-guide-en.html)
- [Nano Banana Pro 水印说明（可见 vs SynthID）— aifreeapi](https://www.aifreeapi.com/en/posts/nano-banana-pro-watermark-commercial-use)
- [FLUX.2 Pro Edit (I2I) — Atlas Cloud](https://www.atlascloud.ai/models/black-forest-labs/flux-2-pro/edit)
- [FLUX API 定价 — Black Forest Labs 官方](https://bfl.ai/pricing)
- [GPT Image 2 — OpenRouter](https://openrouter.ai/openai/gpt-image-2)
- [GPT Image 2 Pricing Breakdown 2026 — nemovideo](https://www.nemovideo.com/blog/gpt-image-2-pricing-breakdown)
- [Seedream 5.0 Pro — OpenRouter](https://openrouter.ai/bytedance-seed/seedream-5-0-pro)
- [Seedream 5.0 Lite API 指南 — apiyi](https://help.apiyi.com/en/seedream-5-0-lite-api-guide-cheaper-than-4-5-en.html)
- [Seedream 4 vs Qwen Image vs Nano Banana — Segmind](https://blog.segmind.com/seedream-4-qwen-image-ai-showdown/)
- [Is Nano Banana Really Better Than Flux Kontext? — Medium](https://medium.com/@team_36250/is-nano-banana-really-better-than-flux-kontext-f1e7548f72d9)
- [FLUX Kontext vs Nano Banana — PicLumen](https://www.piclumen.com/blog/flux-kontext-vs-nano-banana/)
- [Best AI Image Editing Models With Reference Images 2026 — magichour](https://magichour.ai/blog/best-ai-image-editing-models-with-reference-images)
- [Building with AI Pet Portrait APIs — DEV](https://dev.to/jakub_inithouse/building-with-ai-pet-portrait-apis-what-i-learned-about-image-to-image-generation-15da)
- [Anime Pet Portrait — Pawtograph](https://www.pawtograph.app/ai-pet-portrait/anime)
- [Fine-tune Flux on your pet using LoRA — Modal Docs](https://modal.com/docs/examples/diffusers_lora_finetune)
- [Fine-Tuning FLUX.1 on Astria](https://www.astria.ai/articles/fine-tuning-flux.1/)
- [Nano Banana Pro 一致性讨论 — Google Gemini 社区](https://support.google.com/gemini/thread/395344000/)
- [FAL.AI vs Replicate 2026 — teamday](https://www.teamday.ai/blog/fal-ai-vs-replicate-comparison)
- [AI Image Model Pricing 对比 — Price Per Token](https://pricepertoken.com/image)
