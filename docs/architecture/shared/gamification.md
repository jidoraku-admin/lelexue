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

## 5. 奖励的范围（待项目总监裁定）

- 英语 #7 规定奖励只与掌握挂钩，不与邀请、分享、注册、付费、班级人数挂钩。
- 0004 规定分享与推荐奖励只奖励真实注册与付费，次数与上限后台配置。
- 两者冲突。本草案**不实现分享与推荐奖励**，只实现掌握类奖励。是否纳入，由项目总监裁定（中事）。

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

1. 英语 `ProgressStore` 中的掌握记录能否映射到 `MasteryChanged`（英语对话确认）。
2. 数据平台的掌握度事件格式与发布方式（需数据平台的设计，由项目总监协调）。
3. 积分兑换时长与未成年人上限（真人与法务）。
4. 分享与推荐奖励是否纳入（项目总监）。
