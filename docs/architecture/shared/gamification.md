# 共享游戏化 gamification（接口草案 v0.1）

> 负责：共通对话（#23）。状态：草案，待产品设计师（学科）确认规则，待技术总监审核。

## 1. 目标

- 五个学科共用经验、等级、徽章与积分的规则引擎和 Flutter 组件。
- 学科上报"事件"，共享服务按后台配置的规则计算结果。共享服务不读取学科的学习数据。
- 学习像游戏升级一样，但不做结果承诺（见 0002、0006）。

## 2. 核心概念

| 概念 | 说明 |
| --- | --- |
| `Event` | 学科上报的事件，如 `lesson_completed`、`item_answered`、`study_minutes` |
| `XP` | 经验值，按规则累加 |
| `Level` | 等级，由累计 XP 按曲线计算 |
| `Badge` | 徽章，满足条件后授予，可按学科或跨学科 |
| `Coin`（粟米） | 积分。只可兑换学习或会员时长，不兑换现金（0004 红线） |

## 3. 接口草案

```text
GM.report(event: GameEvent) -> GameResult          // 学科调用，幂等
GM.getProgress(userId, scope?) -> Progress         // scope: 全局 或 某学科
GM.listBadges(userId) -> Badge[]
GM.redeem(userId, rewardCode) -> RedeemResult      // 仅学习或会员时长
```

```text
GameEvent {
  eventId: string           // 幂等键，学科生成
  userId: UserId
  subject: SubjectCode
  type: string              // 事件类型，学科注册
  value?: number            // 如答对题数、学习分钟数
  occurredAt: timestamp
}
```

要点：

- `eventId` 必须唯一，重复上报不重复计分。
- 规则（每个事件给多少 XP、徽章条件、积分数值）全部存放在后台配置中，不写死在代码里。
- 分享类奖励的次数与上限同样后台配置（见 0004，2026-11-21 真人确认取消"每个用户只计一次"）。

## 4. 规则示例（仅说明结构，数值待产品设计确认）

```text
rule: lesson_completed
  xp: <configured>
  coin: <configured>
  badge: subject_first_lesson   // 跨学科徽章由全局规则引用

rule: study_minutes
  xp_per_minute: <configured>
  daily_cap: <configured>       // 防止刷时长，未成年人限制待法务确认
```

## 5. Flutter 组件（放在 `packages/shared`）

- `XpBar`、`LevelBadge`、`BadgeWall`、`CoinCounter`、`RewardToast`。
- 组件只接收数据，不调用接口；数据由各学科的页面注入，便于离线与测试。
- 组件文案不得出现考试成绩或保证提分的表述。

## 6. 与学科的分界

- 学科决定"什么时候发生事件"和"事件的玩法"。
- 共享层决定"事件换成什么奖励"。
- 中事（改变学习路径或游戏机制）仍由项目总监决定。

## 7. 待确认（在 #23 提出）

1. 英语的单元完成、单词答对等事件，能否直接映射为 `GameEvent`。
2. 积分兑换的时长单位与上限，待真人与法务确认（0004 第三节）。
3. 未成年人的每日时长与积分上限，待法务复核后启用。
