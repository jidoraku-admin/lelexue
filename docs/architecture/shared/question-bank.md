# 共享题库 question-bank（接口草案 v0.1）

> 负责：共通对话（#23）。状态：草案，待五个学科确认题型需求。

## 1. 目标

- 五个学科共用题目的存储、入库流程、版本化与检索能力。
- 题目按学科编码隔离，同一题型模型可表达多个学科的题。
- 英语当前的单词题库是本地 JSON（`apps/english/assets/data/unit1..3.json`），迁移路径在第 6 节说明。

## 2. 核心模型（草案）

```text
Item {
  itemId: string            // 全局唯一
  subject: SubjectCode      // english | math | chinese | physics | chemistry
  unitRef: string           // 学科内的单元或章节编码（由学科定义）
  type: string              // 题型编码，由学科注册（如 word_match、fill_blank、calc）
  stem: Content             // 题干，可包含文本、音频、图片引用
  options?: Content[]       // 选项（选择类题型）
  answer: Answer            // 标准答案的结构化形式
  skills: string[]          // 知识点或技能标签，由学科定义
  difficulty: number        // 1–5，学科自定，共享层只存取值
  version: int              // 题目版本，修改即递增
  status: draft | reviewed | published | retired
  source: { origin: string, license?: string }  // 来源，用于版权与内容审计
}
```

要点：

- `type` 由学科注册校验规则，共享层只负责存储与检索，不解释题目含义。
- `Content` 是统一结构（文本、语音资源 ID、图片资源 ID），学科不直接保存 URL。
- 版本化：已发布题目的修改产生新版本，旧版本保留，学习记录引用 `itemId + version`。

## 3. 接口草案

```text
QB.register(subject, typeSpec) -> void                 // 学科注册题型
QB.importBatch(subject, items[], reviewRef) -> ImportResult
QB.publish(itemIds[]) -> void
QB.retire(itemId, reason) -> void
QB.get(itemId, version?) -> Item
QB.search(subject, filter, page) -> Page<Item>         // 按单元、知识点、题型、难度
QB.pickForSession(subject, userId, rule) -> Item[]     // 出题规则，结果由学科游戏逻辑使用
```

说明：

- `pickForSession` 只返回候选，不记录作答。作答事件由学科上报。
- 题目内容进入学生端前必须处于 `published` 状态。

## 4. 入库流程（草案）

1. 学科对话起草题目 JSON，提交数据文件到 `docs/data/`（按学科目录，见 `docs/ownership.md`）。
2. 校验：题型已注册、必填字段齐全、音频与图片资源存在。
3. 审核：学科产品设计师确认内容；涉及教材词表与句型的，需与人教版目录一致（见 0006 第二节）。
4. 发布：状态改为 `published`，记录版本与审核人。

## 5. 与内容服务的关系

- 题库负责"单题"，内容服务（content，待排期）负责"内容包"（一个单元的题目、资源与版本清单）。
- 草案阶段，题库先提供单题接口，内容包的组装放到内容服务中设计。

## 6. 英语迁移（待英语对话确认）

- 现有 JSON 字段映射到 `Item`：单词与释义映射为 `stem` 与 `answer`，音频文件名映射为资源 ID。
- 迁移期间，英语保留本地 JSON 作为离线包，共享题库只作为发布来源。是否离线可用，由英语对话与技术总监决定。

## 7. 待确认（在 #23 提出）

1. 各学科题型清单，是否能注册到同一个 `type` 体系。
2. 是否需要题目的"教材对应"字段（人教版单元与册次），以便目录一致性检查。
3. 版权与来源字段的最小要求，待法务确认。
