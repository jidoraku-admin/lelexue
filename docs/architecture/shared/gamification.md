> **范围收窄（#23 项目总监更正，2026-11-22 06:05）**：经验、等级、徽章、积分与展示组件不属于共通，留在学科内（英语 v0.16 与 #23 更正）。仅 `MasteryChanged` 的最小字段（含 `eventId`）作为共通候选，见第 2 节。其余章节保留为历史草案。

# 共享游戏化 gamification（接口草案 v0.2）

> 负责：共通对话（#23）。状态：修订稿，待项目总监复审。
> 修订要点：经验只来自掌握，不来自时长；掌握度由数据平台计算，游戏化只消费事件；删除按分钟给经验的规则。

## 1. 目标

- 五个学科共用经验、等级、徽章与积分的规则，以及展示组件。
- 游戏化**不计算掌握度**。掌握度由数据平台计算（report-v3 第 3 节），通过事件总线发布"掌握度变化"事件，游戏化订阅它。
- 玩法、关卡、故事、Boss 战留在学科内（README 第 1.3 节）。

## 2. 输入事件

| 事件 | 来源 | 用途 |
| --- | --- | --- |
| `MasteryChanged` | 数据平台（掌握度计算） | 经验、徽章的唯一来源 |
| `LessonCompleted` | 学科服务 | 仅用于徽章条件（如"完成第一课"），不产生经验 |

`MasteryChanged` 字段：

```text
MasteryChanged {
  eventId: string           // 幂等键
  userId: UserId
  subject: SubjectCode
  knowledgePointId: string
  level: int                // 学科定义的层级，如英语的 1、2、3
  achievedAt: timestamp
}
```

## 3. 经验规则

- 经验只来自 `MasteryChanged`，不来自时长、答题数或登录。
- **同一知识点的经验只给一次。** 规则是 `(userId, subject, knowledgePointId, level)` 唯一。英语的规则是首次达到 2★ 时给予（#7）。该唯一约束由游戏化库保证，不只依赖 `eventId`。
- 数值（每级经验、等级曲线）后台配置。

## 4. 徽章与积分

- 徽章条件由后台配置，可以是学科徽章或跨学科徽章。
- 积分（粟米）只能兑换学习或会员时长，不兑换现金（0004 红线）。
- 积分兑换的时长单位与上限待真人与法务确认（0004 第三节）。

## 5. 分享与推荐奖励（真人决定 0011，2026-11-22）

- **通过，纳入游戏化**，按 0004 执行：只奖励真实注册与付费。
- 次数、上限、奖励内容全部由后台配置，不写死在代码中。
- 与英语 #7 原有的"奖励只与掌握挂钩"冲突部分，由 0011 取代；英语等学科的相关文字按 0011 修改。
- 后台配置项（草案）：`referral.reward_rule`（触发条件：注册或付费）、`referral.daily_cap`、`referral.total_cap`、`referral.reward_item`。数值待运营与法务确认（营销佣金口径另见 0006，法务完成前不启动）。

## 6. 接口

```text
GM.consume(event: MasteryChanged) -> GameResult          // 由事件订阅调用，幂等
GM.getProgress(userId, scope?) -> Progress               // scope：全局或某学科
GM.listBadges(userId) -> Badge[]
GM.redeem(userId, rewardCode) -> RedeemResult            // 仅学习或会员时长
```

## 7. 展示组件（放在 `packages/shared`）

- `XpBar`、`LevelBadge`、`BadgeWall`、`CoinCounter`、`RewardToast`。
- 组件只接收数据，不调用接口，便于离线与测试。
- 组件文案不得出现考试成绩或保证提分的表述。
- 英语的 Boss 战组件不在共享层，留在英语内。

## 8. 待确认

1. 英语 `ProgressStore` 到 `MasteryChanged` 的映射（共通答复，2026-11-22）：
   - 现状：英语 `Progress` 只记录关卡星级与答错列表，没有逐题作答记录，因此无法发出事件。映射前提是英语新增逐题作答记录（按用户、知识点、题型、对错、时间）。这是英语开发任务，不属于共通。
   - 共通接口要求：英语适配层在首次满足本学科规则时发出一次 `MasteryChanged`，字段如下：
     - `userId`：学生的 `UserId`（由身份服务解析，英语本地标识需先迁移，见 identity.md 第 6 节）。
     - `subject`：`english`。`knowledgePointId`：按 README 第 1.5 节编码。`level`：规则所属层级（1、2、3）。
     - `achievedAt`：满足规则时的 UTC 时间。
     - `eventId`：确定性生成，格式 `english:<userId>:<knowledgePointId>:<level>`，保证重放不重复计分。
2. 数据平台的掌握度事件格式与发布方式（需数据平台的设计，由项目总监协调）。
3. 积分兑换时长与未成年人上限（真人与法务）。
4. 分享与推荐奖励是否纳入（项目总监）。

## 9. 掌握等级判定规则格式（共通 v1，2026-11-22）

数据平台据此计算掌握等级并发布 `MasteryChanged`（#1 裁定）。共通只定义规则的**格式**，数值与指标由各学科定义。

```text
MasteryRule {
  subject: SubjectCode
  level: int                 // 1、2、3，对应 1★、2★、3★
  itemType: string?          // 参与计算的题型编码（如英语的应用题），由学科注册
  metric: accuracy           // 共通 v1 仅支持正确率
  threshold: number          // 0–1，如 0.8
  minCount: int              // 最少作答题数，如 5
  window: attempt | all      // 统计范围，由学科决定
}
```

- 同一 `(subject, knowledgePointId, level)` 首次满足规则时，数据平台发布一次 `MasteryChanged`，并以业务唯一键去重。
- **门槛由学科自定**（#1 裁定，中事）。`threshold`、`minCount`、`window` 是学科参数，存放于学科配置，不写死在共通代码或共通文档中。
- 共通只提供判定机制：首次达到的语义、事件、去重。数据平台只执行各学科给出的判定结果，不内置数值。
- 英语的 1★–3★ 数值（≥80%、≥5 题、间隔复习）是英语的起始参考，不是共通规则。物理与化学沿用英语起始值，各自学科内定义。
