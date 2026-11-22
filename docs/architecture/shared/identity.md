# 共享身份 identity（接口草案 v0.2）

> 负责：共通对话（#23）。状态：修订稿，待项目总监复审。
> 身份模型以英语设计为准（#7，2026-11-20 留言第 1、5 条；真人 #23 回复确认）。

## 1. 账号类型

| 类型 | 说明 | 付费 | 席位 |
| --- | --- | --- | --- |
| 家长账号（母账号） | 实名，完成监护身份核验，是付费与管理主体。收费权益挂在家长账号上 | 是 | 每位家长最多 3 名学生（英语设计） |
| 班级或机构账号（母账号） | 真人 2026-11-22 确认纳入：母账号可以是班级或机构，按席位计价 | 是 | 按购买席位，上限后台配置 |
| 学生账号（子账号） | 学习主体，从属于一个母账号，不单独付费 | 否 | 占用一个席位 |

- 学生账号不能独立注册、付费、开启推送（#7 第 1 条）。
- 学生使用字母账号登录：4–16 位小写字母与数字，不含姓名、生日、学校名。口令由家长设置。系统不收集学生手机号。

## 2. 核心对象

| 对象 | 说明 |
| --- | --- |
| `UserId` | 全局唯一、不复用。学科数据只引用它，不保存个人资料 |
| `Profile` | 昵称、头像、`stage`、`grade`、`volume`（见 README 第 1.2 节） |
| `Guardian` | 家长身份核验结果（实名状态、核验时间） |
| `Seat` | 席位：总数、已用、到期时间 |
| `Link` | 母子关系：`parentUserId` 与 `studentUserId`，一个学生同一时间只属于一个母账号 |
| `Entitlement` | 权益：挂在母账号上，包含付费状态与试用期状态，学生继承 |
| `SubjectCode` | `english`、`math`、`chinese`、`physics`、`chemistry` |

## 3. 接口草案（逻辑接口，不限定传输协议）

```text
Identity.registerParent(credential, guardianVerification) -> UserId
Identity.login(credential) -> Session                      // 家长与学生共用入口，凭证类型不同
Identity.refresh(session) -> Session
Identity.logout(session) -> void

Identity.createStudent(parentUserId, profile, loginName) -> UserId   // 占用一个席位，口令由家长设置
Identity.unlink(parentUserId, studentUserId) -> void

Identity.getProfile(userId) -> Profile
Identity.updateProfile(userId, patch) -> Profile           // stage、grade 等字段由此更新

Identity.getEntitlement(parentUserId) -> Entitlement       // 学生继承家长账号的权益
Identity.getSeats(accountUserId) -> SeatSummary            // 家长、班级或机构账号

Identity.resolveSubject(userId, subjectCode) -> SubjectRef // 学科服务用它定位自己的数据分区
```

说明：

- 学科服务只调用 `resolveSubject`、`getProfile`、`getEntitlement`，不直接读取身份库。
- 学生的 `login` 只接受字母账号；家长的 `login` 接受手机号等凭证（具体方式待定）。
- `createStudent` 只能由母账号发起。学生账号不能调用注册或付费接口。

## 4. 未成年人与监护（待法务复核）

- 学生账号需要家长监护身份核验，依赖 `Guardian`。
- 数据最小化：学生账号不收集手机号、学校、联系方式。这些字段不进入任何模型（report-v3 第 6 节）。
- 未经法务复核，未成年人相关接口保持关闭。

## 5. 数据与存储

- 身份库只保存账号、资料、席位、母子关系与权益。
- 不保存学习进度、答题、掌握度；这些归各学科库。

## 6. 登录凭证与待确认（#1 裁定，2026-11-22 14:59）

- **家长登录**：暂定手机号加短信验证码。家长账号属于个人信息，上线前须经法务复核（0006）。
- **复核前的限制**：身份服务只在内网使用，不开放家长登录。未经复核，家长登录接口不对外提供。
- **学生登录**：仍为字母登录名加家长设置的口令，不收集手机号（见第 1 节）。
- **服务间调用**：身份服务的内部接口使用内网服务令牌，见 `ai-gateway.md` 第 8 节。

待确认：

1. 班级与机构的席位上限数值（真人）。
2. 英语本地用户标识到 `UserId` 的迁移方式（英语对话）。
