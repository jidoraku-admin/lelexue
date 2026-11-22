# 共享 AI 网关 ai-gateway（接口草案 v0.1）

> 负责：共通对话（#23）。状态：草案。模型选型与私有化部署方案以 `docs/architecture/report-v3.md` 为准，待真人与技术总监确认。

## 1. 目标

- 所有学科通过同一入口调用大模型，统一做鉴权、限流、审计、降级。
- **学生数据只由私有化部署的模型处理**（项目说明，report-v3 D6）。网关不提供任何外部模型的通道用于学生数据。
- 支持 RAG（检索增强），知识源按学科隔离。

## 2. 分层

```text
学科服务 ──> AI 网关 ──> 模型适配层 ──> 私有化模型（学生数据）
                 │
                 ├── 鉴权与配额（按 UserId、SubjectCode）
                 ├── 数据分级与脱敏
                 ├── RAG（按学科的索引）
                 └── 审计与降级
```

## 3. 接口草案

```text
AI.complete(request: CompletionRequest) -> CompletionResult
AI.embed(subject, texts[]) -> Vector[]
AI.retrieve(subject, query, filter) -> Chunk[]          // RAG 检索
AI.reportFeedback(callId, rating, reason?) -> void      // 用于质量回溯，不含个人信息
```

```text
CompletionRequest {
  subject: SubjectCode        // 必填，用于隔离与审计
  userId?: UserId             // 学生调用时必填；内容生成类可为空
  purpose: string             // 用途编码，如 hint、explain、story_gen
  dataClass: student | public // 学生数据必须标为 student
  prompt: ...
  limits: { maxTokens, timeoutMs }
}
```

## 4. 数据分级规则（草案）

| dataClass | 允许的模型 | 说明 |
| --- | --- | --- |
| `student` | 仅私有化模型 | 含学生输入、作答、身份信息的请求；网关拒绝路由到任何外部模型 |
| `public` | 私有化模型（默认）；外部模型需单独批准 | 如纯内容生成，不含个人数据 |

- 网关在入口校验：`dataClass=student` 且 `userId` 为空以外的个人字段，必须脱敏后才能进入模型；脱敏规则待法务复核。
- 日志只记录调用元数据（学科、用途、耗时、token 数），不记录原始学生输入。

## 5. 限流与降级

- 按 `UserId` 与 `SubjectCode` 配额，配额数值由后台配置。
- 模型不可用时降级：返回预置提示或跳过 AI 功能，学科游戏不得因模型故障而阻塞。
- 超时统一返回 `DEGRADED`，学科对话决定前端表现。

## 6. 未成年人与 AI 内容策略（大事，待真人确认）

- AI 内容策略（生成内容的范围、是否向学生开放自由对话）属于大事，由真人确认。草案不实现自由对话接口。
- 未成年人相关的使用时长与消费限制，待法务复核后接入配额。

## 7. 待确认（在 #23 提出）

1. 私有化模型的具体型号与部署位置，由技术总监与真人确认后写入 report-v3。
2. RAG 索引的更新频率与数据来源，由各学科提供。
3. 脱敏规则的最小集合，待法务复核。
