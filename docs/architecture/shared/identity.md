# 共享身份 identity（接口草案 v0.1）

> 负责：共通对话（#23）。状态：草案，待学科对话与技术总监确认。

## 1. 目标

- 一个用户在五个学科间只有一个身份，学习进度仍按学科分开存储。
- 支持母子账号结构：母账号是付费与管理主体（家庭、班级或培训机构），子账号是学习主体，不单独付费（见 0004 第一节）。
- 客户端覆盖 Flutter（Android、iOS、Web）与微信小程序入口。

## 2. 核心概念

| 概念 | 说明 |
| --- | --- |
| `UserId` | 全局唯一、不可复用的用户 ID，学科数据只引用它，不保存个人资料 |
| `Profile` | 基础资料：昵称、头像、学段（学段覆盖范围由真人确认，接口只保留字段） |
| `Seat` | 席位。母账号按席位计价；子账号占用一个席位 |
| `Link` | 母子关系：`parentUserId` 与 `childUserId`，一个子账号同一时间只属于一个母账号 |
| `SubjectCode` | 学科编码：`english`、`math`、`chinese`、`physics`、`chemistry`，用于标识学科数据归属 |

## 3. 接口草案（逻辑接口，不限定传输协议）

```text
Identity.login(credential) -> Session
Identity.refresh(session) -> Session
Identity.logout(session) -> void
Identity.getProfile(userId) -> Profile
Identity.updateProfile(userId, patch) -> Profile
Identity.createChild(parentUserId, profile) -> UserId      // 占用一个席位
Identity.linkChild(parentUserId, childUserId) -> Link       // 需要子账号确认或监护同意（待法务）
Identity.unlink(parentUserId, childUserId) -> void
Identity.listSeats(parentUserId) -> SeatSummary            // 已用、可用、到期
Identity.resolveSubject(userId, subjectCode) -> SubjectRef // 学科侧用它找到自己的数据分区
```

说明：

- 学科服务只调用 `resolveSubject` 与 `getProfile`，不直接读取身份库。
- 微信小程序登录通过同一个 `login` 接口，凭证类型不同（`credential.type`）。

## 4. 未成年人与监护（待法务复核）

- 子账号的监护同意、数据最小化收集、推送规则由法务与产品一并确认（见 0004 第三节第 4 条、0006 第三节 3.3）。
- 草案只预留 `Consent` 记录与 `guardianStatus` 字段，不实现自动判定。
- 未经复核，`linkChild` 对未成年人的路径保持关闭。

## 5. 数据与存储

- 身份库只保存账号、资料、席位与母子关系。
- 不保存学习进度、答题、掌握度；这些归各学科服务。
- 个人信息字段最小化，具体清单在法务复核后确定。

## 6. 待确认（在 #23 提出）

1. 学段字段的取值（待真人确认学段覆盖范围）。
2. 班级与培训机构是否需要单独的组织对象，还是先用母账号表示。
3. 席位到期与续费事件由谁触发、通知哪些服务。
4. 英语现有 `ProgressStore` 的本地用户标识，迁移到 `UserId` 的方式。
