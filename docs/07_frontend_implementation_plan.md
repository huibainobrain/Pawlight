# 07 Frontend Implementation Plan

## 1. 总体建议

真实开发优先面向 iOS App + H5。HTML原型只作为开发参照，不应直接复制为生产代码。

建议工程分层：

```text
iOS App
  App Shell / Navigation
  Auth
  Onboarding
  Home
  Memory
  Album
  Mailbox
  Hugs
  Mine
  Entitlement
  Share & Permission

H5
  Share Landing
  Public Memorial Page
  Hug Flow
  Inaccessible State

Shared Contract
  API DTO
  State Definitions
  Error Codes
  Copywriting Constants
```

## 2. App端推荐页面结构

```text
AppRoot
├── AuthGate
├── MainTabs
│   ├── HomeTab
│   ├── MemoryTab
│   └── MineTab
├── OnboardingStack
│   ├── OnboardingStart
│   ├── LoginBind
│   ├── PetInfo
│   ├── MainPhotoUpload
│   ├── TierSelect
│   ├── PaymentState
│   └── CreateSuccess
└── ModalLayer
    ├── SharePanel
    ├── AddPhoto
    ├── PhotoLimit
    ├── AddPetUnavailable
    └── DeleteAccountConfirm
```

## 3. H5端推荐页面结构

```text
H5ShareApp
├── ShareRoute /s/:share_id
├── PermissionLoader
├── MemorialPublicPage
├── HugSuccess
├── HugRepeat
└── Inaccessible
```

H5必须通过 `share_id` 加载公开内容，不应依赖 App 内状态。

## 4. 前端状态管理建议

App端建议区分：

| 状态类型 | 示例 | 来源 |
| --- | --- | --- |
| 服务端状态 | User, Pet, Entitlement, Photos, Story, Letters, Hugs, Share | API |
| 本地UI状态 | 当前Tab、弹窗开关、输入草稿、上传进度 | 客户端 |
| 派生状态 | 是否免费满额、信箱是否锁定、H5是否可抱抱 | 服务端状态计算 |

不要让关键权限只存在前端，例如照片额度、信箱权限、H5可访问性、抱抱去重都必须由后端返回或确认。

## 5. mock数据迁移到真实接口

| HTML mock | 真实实现 |
| --- | --- |
| `state.ownerStage` | `/me` + `/entitlement` + `/pets/current` |
| `state.photos` | `/pets/{pet_id}/photos` |
| `state.storyContent` | `/pets/{pet_id}/story` |
| `state.letters` | `/pets/{pet_id}/letters` |
| `state.hugs` | `/pets/{pet_id}/hugs` |
| `state.share` | `/pets/{pet_id}/share` |
| `visibility/hugEnabled` | Share/Permission API |
| `mainPhotoVersion` | Photo url/version/cache key |

## 6. 可以先静态实现的页面

- 未入驻首页；
- 入驻起始页；
- 登录/账号绑定UI；
- 宠物基础信息页；
- 权益选择页；
- 入驻成功页；
- 我的Tab基础结构；
- 权益页静态结构；
- H5不可访问页；
- 协议/隐私/客服入口占位。

## 7. 必须等后端接口的页面/能力

- 获取当前用户；
- 创建宠物；
- 上传主照片；
- 获取/更新当前宠物；
- 获取相册列表；
- 上传相册照片；
- 保存/获取故事；
- 保存/获取信件；
- 权益校验；
- 支付/恢复购买；
- 分享链接生成；
- H5公开内容加载；
- 抱抱创建和去重；
- 抱抱记录列表。

## 8. 前端兜底状态

前端应兜底：

- 网络失败；
- 图片上传失败；
- 支付取消；
- 表单空输入；
- H5不可访问；
- 重复点击；
- 本地缓存过期；
- 服务端返回字段缺失时的空状态。

前端不应自行决定：

- 是否有付费权益；
- 是否可上传更多照片；
- H5是否可访问；
- 访客是否已抱抱；
- 信箱是否开放；
- 分享链接是否有效。

## 9. App端和H5端共享模型

建议共享以下 DTO 定义：

- PublicPetDTO；
- PhotoDTO；
- StoryDTO；
- ShareDTO；
- HugStatusDTO；
- PermissionDTO；
- ErrorCode。

App端可以拿完整数据，H5只能拿公开数据：

```text
App Pet Detail = Pet + Story + Photos + Letters + Hugs + Entitlement
H5 Public Detail = PublicPet + PublicStory + PublicPhotos + HugStatus
```

信件、购买记录、账号资料不进入H5公开接口。

## 10. H5根据share_id加载公开内容

推荐流程：

1. H5打开 `/s/:share_id`；
2. 请求 `/api/v1/h5/shares/{share_id}/permission`；
3. 若不可访问，展示不可访问页；
4. 若可访问，请求公开内容；
5. 请求抱抱状态；
6. 根据 `hug_enabled` 和 `has_hugged` 展示按钮或已抱抱状态；
7. 点击抱抱时调用创建抱抱接口。

伪代码：

```ts
const permission = await getSharePermission(shareId)
if (!permission.accessible) showInaccessible()
else {
  const page = await getPublicShare(shareId)
  const hugStatus = await getHugStatus(shareId, visitorFingerprint)
  render(page, hugStatus)
}
```

