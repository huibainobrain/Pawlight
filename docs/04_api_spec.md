# 04 API Spec

本文件为真实开发接口清单草案。接口路径仅供研发对齐，实际可按团队网关、鉴权和版本规范调整。默认返回结构：

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

错误结构：

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "PHOTO_LIMIT_REACHED",
    "message": "免费档最多可保存9张照片"
  }
}
```

## 1. 账号模块

### 1.1 登录 / 账号绑定

| 项 | 内容 |
| --- | --- |
| method | POST |
| path | `/api/v1/auth/login` |
| 权限 | 无 |

Request:

```json
{
  "provider": "apple",
  "identity_token": "apple_identity_token",
  "authorization_code": "apple_authorization_code"
}
```

Response:

```json
{
  "user": {
    "user_id": "usr_001",
    "login_status": "logged_in",
    "nickname": "我的账号"
  },
  "access_token": "jwt_or_session_token"
}
```

错误状态：

- `AUTH_INVALID_TOKEN`
- `AUTH_PROVIDER_UNAVAILABLE`
- `AUTH_CANCELLED`

备注：V1优先 iOS Apple 登录。其他账号绑定能力可作为补充。

### 1.2 获取当前用户

| 项 | 内容 |
| --- | --- |
| method | GET |
| path | `/api/v1/me` |
| 权限 | 登录 |

Response:

```json
{
  "user": {
    "user_id": "usr_001",
    "login_status": "logged_in",
    "nickname": "我的账号"
  },
  "entitlement": {
    "entitlement_type": "free",
    "photo_limit": 9,
    "mailbox_enabled": false
  }
}
```

错误状态：`UNAUTHORIZED`, `USER_DELETED`

### 1.3 注销账号

| 项 | 内容 |
| --- | --- |
| method | POST |
| path | `/api/v1/me/delete` |
| 权限 | 登录 |

Request:

```json
{
  "confirm": true
}
```

Response:

```json
{
  "delete_status": "scheduled",
  "effective_at": "2026-06-14T10:00:00+08:00"
}
```

错误状态：`CONFIRM_REQUIRED`, `UNAUTHORIZED`

备注：注销后的宠物、H5、分享链接、图片和信件处理策略需法务确认。

## 2. 宠物模块

### 2.1 创建宠物

| 项 | 内容 |
| --- | --- |
| method | POST |
| path | `/api/v1/pets` |
| 权限 | 登录 |

Request:

```json
{
  "name": "棉花",
  "type": "cat",
  "main_photo_id": "photo_main_001",
  "selected_tier": "free"
}
```

Response:

```json
{
  "pet": {
    "pet_id": "pet_001",
    "name": "棉花",
    "type": "cat",
    "main_photo_id": "photo_main_001"
  },
  "entitlement": {
    "entitlement_type": "free",
    "photo_limit": 9
  }
}
```

错误状态：

- `PET_ALREADY_EXISTS`
- `MAIN_PHOTO_REQUIRED`
- `NAME_REQUIRED`
- `TIER_REQUIRED`

备注：V1每个账号只允许一只宠物。

### 2.2 获取当前宠物

| 项 | 内容 |
| --- | --- |
| method | GET |
| path | `/api/v1/pets/current` |
| 权限 | 登录 |

Response:

```json
{
  "pet": {
    "pet_id": "pet_001",
    "name": "棉花",
    "type": "cat",
    "main_photo": {
      "photo_id": "photo_main_001",
      "url": "https://cdn.example.com/main.jpg"
    },
    "memorial_sentence": "愿你在有风和阳光的地方，继续慢慢散步。"
  }
}
```

错误状态：`PET_NOT_FOUND`

### 2.3 更新宠物资料

| 项 | 内容 |
| --- | --- |
| method | PATCH |
| path | `/api/v1/pets/{pet_id}` |
| 权限 | 登录且为主人 |

Request:

```json
{
  "name": "小白",
  "type": "dog",
  "met_or_adoption_date": {
    "precision": "year",
    "value": "2016"
  },
  "birth_date": {
    "precision": "unknown",
    "value": null
  },
  "passed_away_date": {
    "precision": "month",
    "value": "2025-11"
  }
}
```

Response:

```json
{
  "pet": {
    "pet_id": "pet_001",
    "name": "小白",
    "type": "dog"
  }
}
```

错误状态：`PET_NOT_FOUND`, `FORBIDDEN`, `INVALID_DATE_PRECISION`

### 2.4 更新主照片

| 项 | 内容 |
| --- | --- |
| method | PATCH |
| path | `/api/v1/pets/{pet_id}/main-photo` |
| 权限 | 登录且为主人 |

Request:

```json
{
  "photo_id": "photo_main_002"
}
```

Response:

```json
{
  "main_photo": {
    "photo_id": "photo_main_002",
    "url": "https://cdn.example.com/main2.jpg"
  }
}
```

错误状态：`PHOTO_NOT_FOUND`, `PHOTO_UPLOAD_NOT_COMPLETE`

### 2.5 删除或隐藏宠物

| 项 | 内容 |
| --- | --- |
| method | POST |
| path | `/api/v1/pets/{pet_id}/hide` |
| 权限 | 登录且为主人 |

Request:

```json
{
  "reason": "owner_action"
}
```

Response:

```json
{
  "status": "hidden"
}
```

备注：V1是否提供删除宠物入口待确认。若实现，H5应展示不可访问状态。

## 3. 内容模块

### 3.1 保存纪念语

| method | path | 权限 |
| --- | --- | --- |
| PATCH | `/api/v1/pets/{pet_id}/memorial-sentence` | 登录且为主人 |

Request:

```json
{
  "memorial_sentence": "愿你在有风和阳光的地方，继续慢慢散步。"
}
```

Response:

```json
{
  "memorial_sentence": "愿你在有风和阳光的地方，继续慢慢散步。"
}
```

错误状态：`FORBIDDEN`, `PET_NOT_FOUND`, `CONTENT_TOO_LONG`

### 3.2 保存TA的故事

| method | path | 权限 |
| --- | --- | --- |
| PUT | `/api/v1/pets/{pet_id}/story` | 登录且为主人 |

Request:

```json
{
  "content": "第一次见到TA的时候..."
}
```

Response:

```json
{
  "story": {
    "story_id": "story_001",
    "pet_id": "pet_001",
    "content": "第一次见到TA的时候...",
    "updated_at": "2026-06-14T10:00:00+08:00"
  }
}
```

错误状态：`CONTENT_EMPTY`, `CONTENT_TOO_LONG`, `FORBIDDEN`

### 3.3 获取TA的故事

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/story` | 登录且为主人 |

Response:

```json
{
  "story": {
    "story_id": "story_001",
    "content": "第一次见到TA的时候..."
  }
}
```

错误状态：`STORY_NOT_FOUND`

### 3.4 上传相册照片

建议使用两步：申请上传凭证 + 完成确认。

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/pets/{pet_id}/photos/upload-token` | 登录且为主人 |

Request:

```json
{
  "file_name": "memory.jpg",
  "mime_type": "image/jpeg",
  "purpose": "album"
}
```

Response:

```json
{
  "upload_url": "https://upload.example.com/...",
  "photo_id": "photo_001",
  "max_size_bytes": 10485760
}
```

错误状态：`PHOTO_LIMIT_REACHED`, `UNSUPPORTED_FILE_TYPE`, `VIDEO_NOT_SUPPORTED`

完成确认：

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/photos/{photo_id}/complete` | 登录 |

Request:

```json
{
  "upload_status": "success"
}
```

Response:

```json
{
  "photo": {
    "photo_id": "photo_001",
    "type": "album",
    "thumbnail_url": "https://cdn.example.com/thumb.jpg"
  }
}
```

### 3.5 获取相册列表

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/photos` | 登录且为主人 |

Response:

```json
{
  "photos": [
    {
      "photo_id": "photo_001",
      "type": "album",
      "thumbnail_url": "https://cdn.example.com/thumb.jpg",
      "is_main": false
    }
  ],
  "quota": {
    "used": 1,
    "limit": 9
  }
}
```

### 3.6 删除照片

| method | path | 权限 |
| --- | --- | --- |
| DELETE | `/api/v1/photos/{photo_id}` | 登录且为主人 |

Response:

```json
{
  "deleted": true
}
```

错误状态：`PHOTO_NOT_FOUND`, `CANNOT_DELETE_MAIN_PHOTO`

备注：V1是否做删除照片待确认，可作为P1/P2。

### 3.7 保存信件

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/pets/{pet_id}/letters` | 登录且为主人，且付费 |

Request:

```json
{
  "title": "今天想对TA说……",
  "content": "今天又想起你了。"
}
```

Response:

```json
{
  "letter": {
    "letter_id": "letter_001",
    "title": "今天想对TA说……",
    "content": "今天又想起你了。",
    "visibility": "private",
    "created_at": "2026-06-14T10:00:00+08:00"
  }
}
```

错误状态：`MAILBOX_LOCKED`, `CONTENT_EMPTY`, `FORBIDDEN`

### 3.8 获取信件列表

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/letters` | 登录且为主人，且付费 |

Response:

```json
{
  "letters": [
    {
      "letter_id": "letter_001",
      "title": "今天想对TA说……",
      "content_preview": "今天又想起你了。",
      "created_at": "2026-06-14T10:00:00+08:00"
    }
  ]
}
```

## 4. 权益模块

### 4.1 获取当前权益

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/entitlement` | 登录 |

Response:

```json
{
  "entitlement_type": "free",
  "photo_limit": 9,
  "mailbox_enabled": false,
  "purchase_status": "none"
}
```

### 4.2 发起购买

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/purchases` | 登录 |

Request:

```json
{
  "product_id": "full_memorial_once_299",
  "platform": "ios"
}
```

Response:

```json
{
  "purchase_id": "pur_001",
  "platform_product_id": "ios_full_memorial_once_299",
  "status": "pending"
}
```

### 4.3 查询购买结果

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/purchases/{purchase_id}` | 登录 |

Response:

```json
{
  "purchase_id": "pur_001",
  "status": "success",
  "entitlement_type": "paid"
}
```

### 4.4 恢复购买

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/purchases/restore` | 登录 |

Request:

```json
{
  "platform": "ios",
  "receipt_or_transaction_id": "apple_transaction_id"
}
```

Response:

```json
{
  "restored": true,
  "entitlement_type": "paid"
}
```

错误状态：`NO_RESTORABLE_PURCHASE`

### 4.5 校验照片额度

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/photo-quota` | 登录且为主人 |

Response:

```json
{
  "used": 8,
  "limit": 9,
  "can_upload": true
}
```

### 4.6 校验天堂信箱权限

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/mailbox-permission` | 登录且为主人 |

Response:

```json
{
  "mailbox_enabled": false,
  "reason": "FREE_TIER"
}
```

## 5. 分享/H5模块

### 5.1 生成分享链接

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/pets/{pet_id}/share` | 登录且为主人 |

Request:

```json
{
  "visibility": "link",
  "hug_enabled": true
}
```

Response:

```json
{
  "share": {
    "share_id": "share_001",
    "share_url": "https://h5.example.com/s/share_001",
    "visibility": "link",
    "hug_enabled": true
  }
}
```

错误状态：`PET_NOT_FOUND`, `VISIBILITY_CONFIRM_REQUIRED`

### 5.2 获取H5公开内容

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/h5/shares/{share_id}` | 无登录 |

Response:

```json
{
  "accessible": true,
  "pet": {
    "name": "棉花",
    "type": "cat",
    "main_photo_url": "https://cdn.example.com/main.jpg",
    "memorial_sentence": "愿你在有风和阳光的地方..."
  },
  "story": {
    "content": "第一次见到TA的时候..."
  },
  "photos": [],
  "hug_enabled": true
}
```

错误状态：

- `H5_INACCESSIBLE`
- `SHARE_NOT_FOUND`
- `PET_DELETED`

### 5.3 校验H5访问权限

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/h5/shares/{share_id}/permission` | 无登录 |

Response:

```json
{
  "accessible": true,
  "visibility": "link",
  "hug_enabled": true
}
```

### 5.4 获取H5照片公开列表

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/h5/shares/{share_id}/photos` | 无登录 |

Response:

```json
{
  "photos": [
    {
      "photo_id": "photo_001",
      "thumbnail_url": "https://cdn.example.com/thumb.jpg"
    }
  ]
}
```

### 5.5 获取H5抱抱状态

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/h5/shares/{share_id}/hug-status` | 无登录 |

Request Query:

```text
visitor_fingerprint=fp_xxx
```

Response:

```json
{
  "hug_enabled": true,
  "has_hugged": false
}
```

## 6. 抱抱模块

### 6.1 创建抱抱记录

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/h5/shares/{share_id}/hugs` | 无登录 |

Request:

```json
{
  "visitor_fingerprint": "fp_xxx",
  "source": "h5_share_page"
}
```

Response:

```json
{
  "hug": {
    "hug_id": "hug_001",
    "pet_id": "pet_001",
    "visitor_name": "匿名访客",
    "created_at": "2026-06-14T10:00:00+08:00"
  },
  "has_hugged": true
}
```

错误状态：`HUG_DISABLED`, `ALREADY_HUGGED`, `H5_INACCESSIBLE`

### 6.2 查询抱抱记录

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/pets/{pet_id}/hugs` | 登录且为主人 |

Response:

```json
{
  "total": 3,
  "hugs": [
    {
      "hug_id": "hug_001",
      "visitor_name": "匿名访客",
      "source": "H5分享页",
      "created_at": "2026-06-14T10:00:00+08:00"
    }
  ]
}
```

### 6.3 访客去重

| method | path | 权限 |
| --- | --- | --- |
| POST | `/api/v1/h5/visitor-fingerprint` | 无登录 |

Request:

```json
{
  "share_id": "share_001",
  "client_hint": {
    "user_agent_hash": "hash",
    "local_visitor_id": "uuid"
  }
}
```

Response:

```json
{
  "visitor_fingerprint": "fp_xxx"
}
```

备注：可先用本地匿名ID + 服务端短期限制，避免过重风控。

### 6.4 查询是否已抱抱

| method | path | 权限 |
| --- | --- | --- |
| GET | `/api/v1/h5/shares/{share_id}/hugs/me` | 无登录 |

Response:

```json
{
  "has_hugged": true
}
```

