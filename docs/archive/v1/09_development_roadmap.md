> **Historical V1 document**
>
> This file records Pawlight's V1 product/design state and is kept for historical reference.
> It does not describe the current implementation.

# 09 Development Roadmap

## P0 必须先做

| 项目 | 对应页面 | 对应接口 | 依赖项 | 验收标准 |
| --- | --- | --- | --- | --- |
| 账号 | login, mine | `/auth/login`, `/me` | Apple登录配置 | 可登录、获取当前用户 |
| 单宠创建 | onboardingStart, petInfo, createSuccess | `POST /pets`, `GET /pets/current` | 账号、主照片 | 一个账号只可创建一只宠物 |
| 主照片 | mainPhoto, home, memory, h5 | upload-token, complete, main-photo | 图片存储 | 主图上传后全链路展示 |
| 首页 | home | `/pets/current`, `/entitlement`, `/hugs` | 宠物、权益、抱抱 | 未入驻/已入驻状态正确 |
| 回忆主页 | memory | pet/story/photos/hugs APIs | 宠物、内容接口 | 模块结构与原型一致 |
| H5访问 | h5 | `/h5/shares/{share_id}` | 分享、权限 | link可访问，private不可访问 |
| 分享 | share modal | `POST /pets/{pet_id}/share` | 权限设置 | 可生成share_url |
| 抱抱 | h5Success, h5Repeat | `POST /h5/shares/{share_id}/hugs` | H5权限、去重 | 可抱抱、重复显示已抱抱 |
| 抱抱记录 | hugs | `GET /pets/{pet_id}/hugs` | 抱抱写入 | 主人可看到最新抱抱 |
| 权限 | privacy | share/permission API | 分享表 | 三种H5状态正确 |
| 免费/付费基础权益判断 | entitlement, mailboxLocked, album | `/entitlement` | 账号 | 免费/付费能力边界正确 |

## P1 接着做

| 项目 | 对应页面 | 对应接口 | 依赖项 | 验收标准 |
| --- | --- | --- | --- | --- |
| 相册额度 | album, add photo modal | photo quota, upload APIs | 权益、图片存储 | 免费9张、付费50张，后端拦截 |
| 故事编辑 | storyEdit, memory, h5 | story APIs | 宠物 | 保存后App/H5同步 |
| 天堂信箱 | mailboxLocked, mailbox, letterEdit | letter APIs, mailbox permission | 权益 | 免费锁定，付费可写信 |
| 购买/恢复购买 | tierSelect, entitlement, purchases | purchase APIs | iOS IAP | 成功开通，失败保留创建内容 |
| 我的Tab完整设置 | mine, petProfile, privacy, support | me/pet/permission APIs | 账号、宠物 | 不承载纪念主体内容 |
| H5不可访问态 | h5 inaccessible | permission API | 分享权限 | 私密/删除/异常统一温和展示 |

## P2 后续可做

| 项目 | 对应页面 | 对应接口 | 依赖项 | 验收标准 |
| --- | --- | --- | --- | --- |
| 视觉精修 | 全局 | 无 | P0页面稳定 | 不改变功能边界 |
| 分享图 | share modal | share image generation | 主照片、纪念语 | 可保存分享图 |
| 更完整H5呈现 | h5 | public content APIs | 故事/照片稳定 | 访客查看体验更完整 |
| 多宠预留 | mine, future pet list | pet list APIs | 数据结构支持 | V1仅显示未开放 |
| 提醒和Push预留 | 无V1页面 | reminder/notification future APIs | 日期字段 | 不进入V1用户体验 |
| 后续AI能力预留 | future tier | future APIs | 产品确认 | 不暗示AI回复或复活 |

## 建议开发顺序

1. 数据表与基础API；
2. 账号与单宠创建；
3. 图片上传与主图展示；
4. 首页 + 回忆主页；
5. 分享/H5权限；
6. 抱抱与抱抱记录；
7. 权益判断；
8. 相册、故事、信箱；
9. 支付与恢复购买；
10. 我的Tab与支撑页。

