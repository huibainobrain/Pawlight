> **Historical V1 document**
>
> This file records Pawlight's V1 product/design state and is kept for historical reference.
> It does not describe the current implementation.

# 03 Data Model

以下为真实开发建议的数据模型。字段名使用 snake_case 便于后端落库，客户端可按平台规范转换。

## 1. User

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| user_id | string/uuid | 是 | `usr_001` | 用户唯一ID | 是 | 多端同步主键 |
| login_status | enum | 是 | `logged_in` | logged_out/logged_in/deleted | 是 | 风控状态 |
| login_provider | enum | 是 | `apple` | Apple/phone/other | 是 | 多登录方式 |
| nickname | string | 否 | `我的账号` | 用户昵称 | 否 | 社交资料 |
| avatar_url | string | 否 | `https://...` | 用户头像 | 否 | 个人中心 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 审计 |
| deleted_at | datetime | 否 | null | 注销时间 | 是 | 数据删除流程 |

## 2. Pet

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| pet_id | string/uuid | 是 | `pet_001` | 宠物唯一ID | 是 | 多宠扩展核心 |
| owner_user_id | string/uuid | 是 | `usr_001` | 所属用户 | 是 | 一个用户多只宠物 |
| name | string | 是 | `棉花` | 宠物名字 | 是 | H5/分享展示 |
| type | enum/string | 是 | `cat` | cat/dog/other | 是 | 未来品类扩展 |
| main_photo_id | string | 是 | `photo_main_001` | 主照片ID | 是 | 与Photo关联 |
| memorial_sentence | string | 否 | `愿你在有风和阳光的地方...` | 一句纪念语 | 是 | 多语言/历史版本 |
| met_or_adoption_date | date_partial | 否 | `{precision:"year", value:"2016"}` | 来到身边日期 | 否 | 提醒扩展 |
| birth_date | date_partial | 否 | `{precision:"unknown"}` | 生日 | 否 | 提醒扩展 |
| passed_away_date | date_partial | 否 | `{precision:"month", value:"2025-11"}` | 离开日期 | 否 | 提醒扩展 |
| status | enum | 是 | `active` | active/hidden/deleted | 是 | H5访问控制 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 排序 |

### date_partial

日期字段需要支持：

- `unknown`：未知；
- `year`：仅年份，如 `2016`；
- `month`：年月，如 `2025-11`；
- `day`：完整日期，如 `2025-11-03`。

## 3. Entitlement

权益绑定账号，不绑定单只宠物。

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| entitlement_id | string/uuid | 是 | `ent_001` | 权益ID | 是 | 多权益包 |
| user_id | string/uuid | 是 | `usr_001` | 所属用户 | 是 | 账号级权益 |
| entitlement_type | enum | 是 | `free` | free/paid/future | 是 | 订阅/单项包 |
| photo_limit | integer | 是 | 9 | 免费9，付费50 | 是 | 动态配置 |
| mailbox_enabled | boolean | 是 | false | 天堂信箱是否开放 | 是 | 更多功能开关 |
| purchase_status | enum | 否 | `paid` | none/pending/paid/failed/refunded | 是 | 支付状态 |
| purchase_time | datetime | 否 | null | 购买时间 | 是 | 恢复购买 |
| validity_description | string | 否 | `更长期保存感` | 保存承诺表达 | 否 | 法务确认后调整 |

## 4. Photo

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| photo_id | string/uuid | 是 | `photo_001` | 图片ID | 是 | 图片资产主键 |
| pet_id | string/uuid | 是 | `pet_001` | 所属宠物 | 是 | 多宠支持 |
| user_id | string/uuid | 是 | `usr_001` | 上传用户 | 是 | 权限审计 |
| type | enum | 是 | `album` | main/album/share_preview/future_ai | 是 | AI图预留 |
| url | string | 是 | `https://cdn/...` | 原图或高清图URL | 是 | CDN |
| thumbnail_url | string | 是 | `https://cdn/...thumb` | 缩略图URL | 是 | 列表/H5 |
| upload_status | enum | 是 | `success` | pending/success/failed/rejected | 是 | 上传重试 |
| is_main | boolean | 是 | false | 是否主照片 | 是 | 主图替换 |
| sort_order | integer | 否 | 1 | 相册排序 | 否 | 拖拽排序预留 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 上传时间 | 是 | 排序 |

## 5. Story

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| story_id | string/uuid | 是 | `story_001` | 故事ID | 是 | 多段故事 |
| pet_id | string/uuid | 是 | `pet_001` | 所属宠物 | 是 | 多宠 |
| content | text | 是 | `第一次见到TA...` | TA的故事正文 | 是 | 时间线 |
| visibility | enum | 是 | `public_link` | private/public_link | 是 | H5展示控制 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 版本 |
| updated_at | datetime | 是 | `2026-06-14T10:30:00+08:00` | 更新时间 | 是 | 版本 |

## 6. Letter

信件默认私密，不在 H5 展示。

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| letter_id | string/uuid | 是 | `letter_001` | 信件ID | 是 | 主键 |
| pet_id | string/uuid | 是 | `pet_001` | 所属宠物 | 是 | 多宠 |
| user_id | string/uuid | 是 | `usr_001` | 作者 | 是 | 权限 |
| title | string | 否 | `今天想对TA说...` | 标题 | 是 | 搜索 |
| content | text | 是 | `今天又想你了` | 正文 | 是 | 主要内容 |
| visibility | enum | 是 | `private` | V1固定private | 是 | 未来公开/导出 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 排序 |
| updated_at | datetime | 是 | `2026-06-14T10:30:00+08:00` | 更新时间 | 否 | 编辑 |

## 7. Hug

访客无需登录，但需要去重。

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| hug_id | string/uuid | 是 | `hug_001` | 抱抱ID | 是 | 主键 |
| pet_id | string/uuid | 是 | `pet_001` | 所属宠物 | 是 | 多宠 |
| share_id | string/uuid | 是 | `share_001` | 分享链接ID | 是 | 来源追踪 |
| visitor_fingerprint | string | 是 | `fp_xxx` | 匿名访客指纹 | 是 | 去重 |
| visitor_name | string | 否 | `匿名访客` | 展示名 | 是 | 未来实名 |
| source | string | 是 | `h5_share_page` | 来源 | 是 | 埋点 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 抱抱时间 | 是 | 列表 |

## 8. Share

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| share_id | string/uuid | 是 | `share_001` | 分享ID | 是 | H5入口 |
| pet_id | string/uuid | 是 | `pet_001` | 对应宠物 | 是 | 多宠 |
| owner_user_id | string/uuid | 是 | `usr_001` | 主人 | 是 | 权限 |
| share_url | string | 是 | `https://.../s/share_001` | H5链接 | 是 | 短链 |
| visibility | enum | 是 | `link` | private/link | 是 | H5可见性 |
| hug_enabled | boolean | 是 | true | 是否允许抱抱 | 是 | H5动作 |
| status | enum | 是 | `active` | active/disabled/deleted | 是 | 失效 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 审计 |

## 9. Permission

可以作为 Share 字段，也可拆独立表。V1建议先在 Share / Pet 上保存。

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| pet_id | string/uuid | 是 | `pet_001` | 关联宠物 | 是 | 多宠 |
| visibility | enum | 是 | `link` | private/link | 是 | H5访问 |
| hug_enabled | boolean | 是 | true | 抱抱开关 | 是 | 互动开关 |
| updated_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 更新时间 | 是 | 审计 |

## 10. Purchase

| 字段名 | 类型 | 必填 | 示例 | 说明 | V1必须 | 未来扩展 |
| --- | --- | --- | --- | --- | --- | --- |
| purchase_id | string/uuid | 是 | `pur_001` | 购买记录ID | 是 | 主键 |
| user_id | string/uuid | 是 | `usr_001` | 购买用户 | 是 | 账号级权益 |
| product_id | string | 是 | `full_memorial_once_299` | 商品ID | 是 | App Store产品 |
| amount | decimal | 是 | 29.9 | 支付金额 | 是 | 对账 |
| currency | string | 是 | `CNY` | 币种 | 是 | 多币种 |
| status | enum | 是 | `success` | pending/success/failed/cancelled/refunded | 是 | 支付状态 |
| platform_transaction_id | string | 否 | `apple_txn_xxx` | 平台交易号 | 是 | 恢复购买 |
| created_at | datetime | 是 | `2026-06-14T10:00:00+08:00` | 创建时间 | 是 | 对账 |

## 11. Future Reminder预留

V1不做提醒，但日期结构应支持未来扩展。

| 字段名 | 类型 | 说明 |
| --- | --- | --- |
| reminder_id | string/uuid | 提醒ID |
| user_id | string/uuid | 用户 |
| pet_id | string/uuid | 宠物 |
| reminder_type | enum | birthday/adoption/passed_away/custom |
| date_precision | enum | year/month/day |
| timezone | string | 时区 |
| enabled | boolean | 是否启用 |

## 12. Future Notification预留

V1不申请系统Push权限，但可保留事件模型。

| 字段名 | 类型 | 说明 |
| --- | --- | --- |
| event_id | string/uuid | 事件ID |
| user_id | string/uuid | 用户 |
| pet_id | string/uuid | 宠物 |
| event_type | enum | new_hug/system_notice/future_reminder |
| payload | json | 事件内容 |
| is_read | boolean | App内轻提示已读 |
| created_at | datetime | 创建时间 |

## 13. Future Multi-pet预留

V1 UI只支持一只宠物，但所有内容表必须带 `pet_id`。未来多宠可增加：

- Pet list；
- current_pet_id；
- 多宠权益策略；
- 多宠分享管理；
- 多宠相册、故事、信件和抱抱隔离。

