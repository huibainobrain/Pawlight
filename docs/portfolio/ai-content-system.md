# Pawlight：AI 内容系统设计

> 如何把开放式生成能力，变成长期可控的内容供给。

## 背景

AI Scene 是一次性主动生成：

~~~text
真实照片 + 用户场景
→ 图片
→ 用户确认
→ 视频
~~~

进入「星球生活」后，生成变成长期行为。

在本功能下，用户会间断收到关于宠物在新星球上生活的剪影和描述，会拿到一张图片+描述性内容

如果每次都让模型自由决定地点、行为和故事，会出现：

- 内容重复；
- 设定冲突；
- 行为不合理；
- 世界视觉漂移；
- AI 擅自补充人格、情绪或来世事实。

因此长期内容采用的核心原则是：

> **规则确定事实，AI 负责表达。**

## 1. 内容结构

一条 Event 的事实由结构化资产组成：

| 维度 | 示例 |
| --- | --- |
| Location | 小花园、湖边、林间 |
| Action | 休息、散步、玩耍 |
| Time | 白天、黄昏 |
| Atmosphere | 晴朗、微风 |
| Ambient Detail | 花草、落叶 |
| Gift | 小球、毯子 |

Event Template 定义这些资产的合法组合，并同时承载：

- 权重；
- 冷却；
- 物种适用；
- Location × Action 兼容；
- Gift 兼容。

因此新增内容主要是**增加资产和模板**，而不是持续扩大 Prompt。

## 2. 生成链路

~~~text
检查生成资格
→ 选择 Event Template
→ 解析 Event Facts
→ Text Generation
→ Text Quality Check
→ Image Generation
→ Image Quality Check
→ 发布 Planet Event
~~~

质量不合格时自动重试一次；仍不合格则本次不发布。

AI 不负责决定本次“发生什么”，而负责把已经确定的事实表达好。

## 3. Pet Identity 与 World Identity 分离

### Pet Identity

始终来自：

> **真实宠物照片。**

不使用上一张 AI 图作为下一张图的宠物身份来源。

### World Identity

由三层控制：

~~~text
Planet Style
→ 整体视觉规则

Home Profile
→ 每只 Pet 固定的家园设定

Home Anchor
→ 已验证家园图片的视觉参考
~~~

Home Anchor 只负责世界视觉连续性，不承担宠物身份。

如果 Anchor 对应图片被用户标记为 Bad Case：

~~~text
Anchor Invalidated
→ Home Profile 保留
→ 后续合格 Home Event 建立新 Anchor
~~~

## 4. Personal Scene 与 Canonical World 解耦

用户主动生成的海边、雪山、太空等自由场景属于一次 Personal Scene。

它不会自动改写 Planet Life 的长期世界。

这样既保留用户创作自由，又避免一次生成永久污染长期设定。

## 5. 内容节奏

星球生活不是 Feed。

当前策略：

~~~text
48–96h 非固定等待
最多 1 条未读
每周设置生成上限
阅读后重新计时
Template 权重 + 冷却
~~~

目标不是让用户每天回来，而是维持低压力的长期期待。

## 6. Gift

Gift 是一次内容介入，不是养成资产。

~~~text
Purchase
→ Pending Gift
→ 后续兼容 Event
→ Gift 正确出现
→ QC Pass
→ Completed
~~~

如果对应 Event 成为 Bad Case，Gift 恢复 Pending，不重复收费。

## 设计结果

最终系统把 AI 的自由度限制在：

> **表达层。**

而把长期稳定性放在：

> **资产、模板、状态、世界设定和质量控制层。**

这使 Pawlight 可以继续增加内容供给，而不需要每增加一种内容都重写整个生成逻辑。
