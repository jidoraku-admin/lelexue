> **范围收窄（#23 项目总监更正，2026-11-22 06:05）**：本文件的内容不再属于共通。题目数据模型与题库内容留在各学科库，英语与化学已各自确认。本文件保留为历史草案，供学科参考，不作为共通接口。

# 共享题库契约 question-bank（接口草案 v0.2）

> 负责：共通对话（#23）。状态：修订稿，待项目总监复审。
> 修订要点：题目内容不集中存储，存在各学科库；共享层只提供契约、校验与审核流程。

## 1. 边界

- **共享层提供**：题目模型定义、字段校验、审核状态机、版本规则、检索接口的契约。
- **学科库提供**：题目内容的实际存储、学科的题型注册、学科的出题规则实现。
- 五个学科各自实现同一套契约（适配器），因此题目内容不进入共享库。

## 2. 题目模型

```text
Item {
  itemId: string               // 学科内唯一，组合键为 (subject, itemId)
  subject: SubjectCode         // english | math | chinese | physics | chemistry
  stage: primary | junior | senior      // 学段（README 第 1.2 节）
  grade: int                   // 1–12
  volume: int                  // 册次，1 为上册，2 为下册
  unitRef: string              // 单元编码，由学科定义，与人教版目录一致
  knowledgePoints: string[]    // 知识点标签，由学科定义
  type: string                 // 题型编码，由学科注册
  level: int?                  // 认知层级，由学科定义含义（如英语 1★、2★、3★）
  difficulty: int              // 1–5，学科自定
  stem: Content                // 题干：文本、音频资源 ID、图片资源 ID
  options: Content[]?          // 选择类题型的选项
  answer: Answer               // 结构化标准答案
  version: int                 // 修改已发布题目时递增
  status: draft | pending_review | published | retired
  origin: { generator: string, reviewedBy?: string }   // 生成与审核来源
}
```

要点：

- `level` 的含义由学科定义，共享层只存取值，不解释。这替代了原草案的 `skills` 字段，英语的 1★–3★ 写入 `level`。
- `Content` 使用统一结构。学科不直接保存 URL，只保存资源 ID。
- 已发布题目的修改产生新版本。学习记录应引用 `(subject, itemId, version)`。

## 3. 审核状态机

```text
draft → pending_review → published → retired
                 │
                 └→ draft（打回）
```

- **真人审核是上线的必经步骤。** 题目进入 `published` 前必须有真人审核记录（#7，项目说明）。
- 免审的题型或批次需真人确认，并记录在学科的 `docs/data/` 中。草案中没有默认免审规则。
- 抽检比例与阈值由学科配置。英语的参考值为每周 5% 抽检，错误率超过 2% 暂停批次（#7）。
- 查重规则由学科实现。英语的参考规则为连续 8 个词与任一来源相同，或选项相同即打回（#7）。

## 4. 契约接口（由各学科实现）

```text
QB.validate(item) -> ValidationResult                     // 字段、题型、资源存在性
QB.submitForReview(subject, itemIds[]) -> void
QB.recordHumanReview(subject, itemId, reviewer, result) -> void
QB.publish(subject, itemId) -> void                       // 仅 status=pending_review 且有真人审核记录
QB.retire(subject, itemId, reason) -> void
QB.get(subject, itemId, version?) -> Item
QB.search(subject, filter, page) -> Page<Item>            // filter: stage、grade、volume、unitRef、knowledgePoint、type、level
QB.pickForSession(subject, rule) -> ItemRef[]             // 只按规则出题
```

说明：

- `pickForSession` 只接收规则（学段、单元、知识点、难度、层级），返回候选引用。它不接收 `userId`，不读取学习记录。学习状态的过滤（如排除已答题目）由学科服务在调用后完成。
- 作答事件由学科上报，题库不记录作答。
- 学生端只能获取 `published` 状态的题目。

## 5. 与内容服务的关系

- 题库负责单题契约。内容服务（content，待排期）负责内容包（单元的题目、资源与版本清单）。
- 内容包的组装放到内容服务中设计，本草案不展开。

## 6. 英语迁移（待英语对话确认）

- 现有 JSON 字段映射：单词与释义映射为 `stem` 与 `answer`，音频文件名映射为资源 ID，单元映射为 `unitRef`。
- 英语保留本地 JSON 作为离线包。题目权威来源是英语库，共享层只提供契约。

## 7. 待确认

1. 各学科题型是否都能注册到同一个 `type` 体系（学科对话确认）。
2. 版权与来源字段的最小要求（法务）。
