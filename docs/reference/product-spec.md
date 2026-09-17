# Pawlight Product Spec

> 当前产品规则事实源。
> 历史 V1 文档位于 `docs/archive/`。

## 1. 定位

Pawlight 是面向宠物离世后纪念需求的：

```text
iOS Owner App
+
H5 Visitor Memorial Page
```

核心产品闭环：

```text
创建
→ 纪念
→ 分享
→ Hug
→ Owner 回访
```

V2 增加 AI 场景画像和动态观察窗。

## 2. 用户

### Owner

可以：

- 创建 1 只 Pet；
- 设置 MAIN Photo；
- 编辑 Story / Memorial Note；
- 管理 Album；
- 使用 Share；
- 查看 Hug；
- PAID 使用 Letters；
- PAID 使用 AI Scene。

### Visitor

通过 Share Link 进入 H5。

无需登录。

只能访问 Public-safe Memorial Data。

## 3. 当前明确不做

- 社区 / Feed；
- 评论；
- 关注；
- 排行榜；
- 游戏化；
- AI 宠物聊天；
- AI 回复；
- 宠物人格模拟；
- 复活叙事；
- 多宠前台管理。

## 4. Photo

```text
MAIN
ALBUM
```

MAIN：

- Pet 主视觉；
- AI reference；
- 不计 Album quota；
- 不通过 Album delete flow 删除。

ALBUM：

```text
FREE  9
PAID 50
```

Quota 由 Backend 最终校验。

## 5. Entitlement

绑定 User。

| FeatureFREEPAID |   |    |
| --------------- | - | -- |
| Pet             | 1 | 1  |
| Story           | ✓ | ✓  |
| Share           | ✓ | ✓  |
| Hug             | ✓ | ✓  |
| Album           | 9 | 50 |
| Letters         | — | ✓  |
| AI Scene        | — | ✓  |

当前 PAID 为一次性购买。

## 6. Share

Visibility：

```text
LINK
PRIVATE
```

Hug Enabled 独立保存。

规则：

- LINK 可通过分享地址访问；
- PRIVATE 由 Backend 拒绝；
- Public Response 不包含 User / Entitlement / Letter / Purchase 等私密数据。

## 7. Hug

```text
shareId + visitorFingerprint
```

唯一约束。

状态至少包括：

```text
success
already_hugged
hug_disabled
private_or_unavailable
not_found
```

## 8. Letters

- PAID only；
- Owner only；
- Private；
- 不进入 H5；
- 不提供 AI Reply。

## 9. AI Scene

流程：

```text
MAIN Photo
+ Scene

→ Job
→ 4 Candidates
→ Owner Select
→ Video
→ R2
→ observationVideo
```

AI Scene：

- PAID only；
- 有生成尝试上限；
- AI 内容不覆盖 MAIN Photo；
- 支持恢复原照片；
- Job 必须有明确 DONE / FAILED 状态。

## 10. AI 边界

允许：

- Reference image generation；
- Scene generation；
- Light-motion video。

不允许：

- AI Reply；
- Pet Persona；
- Continuous AI Chat；
- “Pet is back” 类表达。

## 11. Purchase

```text
StoreKit
→ Signed Transaction
→ Backend Verification
→ Product / Revocation Check
→ User Entitlement
```

客户端 Purchase State 不是最终服务端权益事实。

## 12. Delete Account

```text
Sign out
≠
Delete account
```

Delete Account 需处理：

- Photo assets；
- AI assets；
- User；
- 关联 DB records。

## 13. V1 → V2

V1：

```text
Basic Memorial Loop
```

V2：

```text
Basic Memorial Loop
+
AI Scene / Dynamic Planet Window
```
