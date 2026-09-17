# Pawlight Localization

> **这一份不是“理想文案提案”，而是当前代码中真实存在的中英文文案映射。**

最终提交时必须从以下真实实现重新核对：

```text
iOS:
ios/MemorialApp/Sources/Common/Utils/Strings.swift

H5:
实际页面文案与 lang 逻辑
```

不要把尚未上线的文案写进本文件。

文档建议按真实页面整理：

## App Navigation

| 中文实际文案English actual stringCode Key / Location |          |          |
| ---------------------------------------------- | -------- | -------- |
| 首页                                             | Home     | [真实 key] |
| 回忆                                             | Memories | [真实 key] |
| 我的                                             | Me       | [真实 key] |

## Privacy Settings

例如当前真实文案：

| 中文English |                    |
| --------- | ------------------ |
| 权限设置      | Privacy Settings   |
| 谁可以看见TA   | Who can see them?  |
| 通过链接可见    | Visible via link   |
| 仅自己可见     | Only me            |
| 允许访客抱抱TA  | Allow visitor hugs |

## H5 Share

当前代码已存在的真实映射包括：

| 中文English      |                                    |
| -------------- | ---------------------------------- |
| TA的故事          | Their Story                        |
| 照片回忆           | Photo Memories                     |
| 谢谢你来看TA        | Thank you for visiting             |
| 分享给也记得TA的人     | Share with those who remember them |
| 链接已复制          | Link copied                        |
| 这颗星球暂时只给主人自己可见 | This memorial is private for now   |
| 页面暂时没有加载出来     | Couldn't load the page             |
| 重新加载           | Reload                             |
| 主人暂时没有开放抱抱     | Hugs aren't open right now         |
| 已经轻轻抱抱过TA      | You've sent a hug                  |
| 轻轻抱抱TA ♡       | Send a hug ♡                       |

## Account

必须核对并明确区分：

| 中文English |                |
| --------- | -------------- |
| 退出登录      | Sign out       |
| 删除账号      | Delete account |

禁止再次出现：

```text
删除账号 → Sign out
```

## AI Scene

这一节只填写**当前代码中实际已经使用的字符串**：

```text
输入 Scene
Generating Image
Candidate Pick
Generating Video
Failed
Restore Original
...
```

每条必须附实际 String Key 或代码位置。

## Implementation

记录真实实现，例如：

```text
iOS string source
LanguageStore
default language
UserDefaults key
H5 lang parameter
H5 default language
App display name
```

### Maintenance Rule

本文件只记录 Production Code 已存在的 Copy。

如果需要提出未来文案优化，单独开 Product Issue，不在 Reference 中提前改写事实。
