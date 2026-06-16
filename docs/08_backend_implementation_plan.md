# 08 Backend Implementation Plan

## 1. 后端目标

V1后端应支撑：

- 账号与权益绑定；
- 单宠创建；
- 主照片和相册上传；
- 纪念语、故事、信件保存；
- 分享链接与H5访问权限；
- 访客抱抱和去重；
- 购买与恢复购买；
- 私密化、删除、注销后的访问控制。

不要在V1后端引入社区、发现流、评论、AI聊天、复杂多宠、Push任务调度等超范围能力。

## 2. 推荐数据表

### users

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| user_id | uuid pk | 用户ID |
| login_provider | varchar | apple/phone/other |
| provider_user_id | varchar | 平台用户ID |
| nickname | varchar | 昵称 |
| status | varchar | active/deleted |
| created_at | datetime | 创建时间 |
| deleted_at | datetime | 注销时间 |

索引：

- unique(provider, provider_user_id)
- index(status)

### pets

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| pet_id | uuid pk | 宠物ID |
| owner_user_id | uuid fk | 主人 |
| name | varchar | 宠物名 |
| type | varchar | cat/dog/other |
| main_photo_id | uuid | 主照片 |
| memorial_sentence | text | 纪念语 |
| met_or_adoption_date | json | 部分日期 |
| birth_date | json | 部分日期 |
| passed_away_date | json | 部分日期 |
| status | varchar | active/hidden/deleted |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

索引：

- index(owner_user_id, status)
- unique(owner_user_id) for V1 active pet，可用业务校验代替硬唯一以便未来多宠。

### entitlements

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| entitlement_id | uuid pk | 权益ID |
| user_id | uuid fk | 用户 |
| entitlement_type | varchar | free/paid |
| photo_limit | int | 9/50 |
| mailbox_enabled | boolean | 信箱开关 |
| purchase_status | varchar | none/paid/refunded |
| purchase_time | datetime | 购买时间 |
| updated_at | datetime | 更新时间 |

索引：

- unique(user_id)

### photos

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| photo_id | uuid pk | 图片ID |
| pet_id | uuid fk | 宠物 |
| user_id | uuid fk | 上传者 |
| type | varchar | main/album |
| url | text | 图片URL |
| thumbnail_url | text | 缩略图URL |
| upload_status | varchar | pending/success/failed/rejected |
| is_main | boolean | 是否主图 |
| sort_order | int | 排序 |
| deleted_at | datetime | 删除时间 |
| created_at | datetime | 创建时间 |

索引：

- index(pet_id, type, deleted_at)
- index(user_id, created_at)

### stories

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| story_id | uuid pk | 故事ID |
| pet_id | uuid fk | 宠物 |
| content | text | 内容 |
| visibility | varchar | private/public_link |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

索引：

- unique(pet_id) for V1

### letters

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| letter_id | uuid pk | 信件ID |
| pet_id | uuid fk | 宠物 |
| user_id | uuid fk | 作者 |
| title | varchar | 标题 |
| content | text | 内容 |
| visibility | varchar | V1固定private |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |
| deleted_at | datetime | 删除时间 |

索引：

- index(pet_id, created_at desc)
- index(user_id, created_at desc)

### shares

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| share_id | uuid pk | 分享ID |
| pet_id | uuid fk | 宠物 |
| owner_user_id | uuid fk | 主人 |
| share_url | text | 分享链接 |
| visibility | varchar | private/link |
| hug_enabled | boolean | 是否允许抱抱 |
| status | varchar | active/disabled/deleted |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

索引：

- index(pet_id)
- index(owner_user_id)
- unique(share_id)

### hugs

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| hug_id | uuid pk | 抱抱ID |
| pet_id | uuid fk | 宠物 |
| share_id | uuid fk | 分享 |
| visitor_fingerprint | varchar | 匿名访客指纹 |
| visitor_name | varchar | 默认匿名访客 |
| source | varchar | h5_share_page |
| created_at | datetime | 创建时间 |

索引：

- index(pet_id, created_at desc)
- unique(share_id, visitor_fingerprint) 可作为轻去重

### purchases

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| purchase_id | uuid pk | 购买ID |
| user_id | uuid fk | 用户 |
| product_id | varchar | 商品 |
| platform | varchar | ios |
| platform_transaction_id | varchar | 平台交易ID |
| amount | decimal | 金额 |
| currency | varchar | CNY |
| status | varchar | pending/success/failed/cancelled/refunded |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

索引：

- index(user_id, created_at desc)
- unique(platform_transaction_id)

### in_app_events

V1只做App内轻提示，不做系统Push。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| event_id | uuid pk | 事件ID |
| user_id | uuid | 用户 |
| pet_id | uuid | 宠物 |
| event_type | varchar | new_hug |
| payload | json | 内容 |
| is_read | boolean | 是否已读 |
| created_at | datetime | 创建时间 |

## 3. 表关系

```text
users 1 - 1 entitlements
users 1 - N pets (V1业务限制为1)
pets 1 - N photos
pets 1 - 1 stories (V1)
pets 1 - N letters
pets 1 - N shares
shares 1 - N hugs
users 1 - N purchases
users 1 - N in_app_events
```

## 4. 权限校验

主人侧接口必须校验：

- 当前用户已登录；
- pet.owner_user_id == current_user.user_id；
- user.status != deleted；
- pet.status == active；
- 付费能力需校验 entitlement。

H5接口不要求登录，但必须校验：

- share存在；
- share.status == active；
- share.visibility == link；
- pet.status == active；
- owner未注销；
- 若抱抱，需 share.hug_enabled == true。

## 5. H5访问校验

返回不可访问的情况：

- `visibility=private`；
- share不存在；
- share disabled/deleted；
- pet hidden/deleted；
- owner deleted；
- 内容不存在或异常。

用户侧文案统一为：

```text
这个星球暂时不能访问
```

不要向访客暴露404、权限错误、删除原因等工程细节。

## 6. 抱抱去重

V1建议轻去重：

- H5本地生成 `local_visitor_id`；
- 服务端结合 `share_id + local_visitor_id`；
- 可辅助 user_agent_hash/IP短期窗口；
- unique(share_id, visitor_fingerprint)；
- 重复时返回 `ALREADY_HUGGED`。

不建议V1要求访客登录。

## 7. 图片存储

建议：

- 对象存储 + CDN；
- 上传前获取签名URL；
- 服务端记录 Photo；
- 异步生成缩略图；
- H5优先返回缩略图/中等图；
- 原图保留策略待成本确认。

## 8. 购买权益校验

购买成功后：

1. 接收App端购买结果；
2. 服务端校验平台交易；
3. 写 purchases；
4. 更新 entitlements；
5. 返回 paid 权益；
6. 客户端刷新照片额度和信箱权限。

恢复购买走同样的交易校验与权益更新。

## 9. 删除 / 私密化后的H5表现

| 后端状态 | H5表现 |
| --- | --- |
| visibility=private | 不可访问 |
| share disabled/deleted | 不可访问 |
| pet hidden/deleted | 不可访问 |
| user deleted | 不可访问 |

不要在H5显示“已删除”“账号注销”等敏感原因，除非产品/法务确认。

## 10. 未来多宠扩展

当前表结构已支持 pet_id。未来需要：

- 移除V1单宠业务限制；
- App增加宠物列表；
- 分享、相册、故事、信件按pet_id隔离；
- 权益策略确认：账号权益覆盖所有宠物，还是按宠物/权益包计费。

## 11. 未来提醒和Push扩展

V1不做系统Push和周年提醒，但可预留：

- reminders；
- device_tokens；
- notification_settings；
- push_events。

不要在V1首屏索取Push权限。

