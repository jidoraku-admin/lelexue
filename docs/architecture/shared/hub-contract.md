# 统一入口 apps/hub 契约（草案 v0.1）

> 负责：共通对话（#23）。依据：项目总监 #23 需求（2026-11-24 04:21 UTC）与 #1 统一入口裁定。
> 状态：草案，待项目总监审核后定稿。定稿前学科不接入。

## 1. 入口页结构

- 路由：`/`（入口页）与 `/subjects/:code`（学科入口，`code` 取 `SubjectCode`）。
- 入口页自上而下：
  1. 登录状态条：显示当前学生昵称；未登录时只显示"登录"按钮（第 3 节）。
  2. 学科列表：固定顺序 英语、数学、语文、物理、化学，每个学科一张卡片，含学科名、学科模块提供的进度摘要（可为空）、"进入"按钮。
- "进入"跳转到 `/subjects/:code`，学科模块自带的返回按钮回到 `/`。
- 平台：Flutter，覆盖 Android、iOS、Web，与各学科一致。

## 2. 学科注册方式

- 静态注册，不用远程配置。hub 维护一张列表 `apps/hub/lib/registry.dart`，每项为 `SubjectModule`：`code`（`SubjectCode`）、`displayName`、`entry`（学科入口 Widget 构造函数）、`progressSummary`（可选，返回进度摘要）。
- `SubjectModule` 的定义放在 `packages/shared`（共享类型，与 P1 基础类型同包）。
- 学科入口形态：现有学科是可独立运行的 Flutter app（各自 `main.dart`）。学科在自己的目录新增一个可被引用的入口函数 `buildSubjectEntry`（`lib/entry.dart`，并由包的 `lib/<subject>.dart` 导出），独立运行的 `main.dart` 保留。hub 以 path 依赖引用该包。目录仍按 `docs/ownership.md`，学科只改自己的目录。
- 学科入口签名（最终以 PR 为准）：

```dart
// 学科模块导出的入口，由 hub 调用
Widget buildSubjectEntry({
  required UserId userId,          // 已登录学生的 UserId，hub 传入
  required SubjectCode subject,    // 本学科代码
  required VoidCallback onExit,    // 学科点击返回时调用，hub 负责回到入口页
});
```

## 3. 身份

- hub 只传给学科两项数据：`UserId` 与 `SubjectCode`。学科不接收学生的其他数据，也不接收 hub 的内部状态。
- 当前身份服务（services/identity）已有母账号、学生、席位、权益接口，但没有登录接口。学生登录（字母登录名加口令，见 identity.md §1）需要新增会话接口，本契约不定义其细节，待共通在 #110 之后另开 PR 设计。
- 在登录接口就绪前，hub 只在开发构建中从配置读取一个测试 `UserId`，生产构建禁止使用。
- 家长登录仍按 identity.md §6，法务复核（0006）前不开放。

## 4. 学科模块的最低要求

- 只依赖 `packages/shared` 与自身目录，不依赖 `apps/hub` 的任何内部类型。
- 只接收 `UserId` 与 `SubjectCode`，不读取其他学科的数据。
- 返回时只调用 `onExit`，不直接修改 hub 的路由栈。
- 进度摘要可以为空，不得阻塞入口页渲染。

## 5. 第一版实现计划

| 阶段 | 内容 | 目标 |
| --- | --- | --- |
| P0 | apps/hub 空壳：入口页、五张学科卡片、`/subjects/:code` 路由、`SubjectModule` 定义；开发构建使用测试 UserId | 11-25 可访问的入口页 |
| P1 | 英语作为第一个接入学科：hub 不改英语游戏逻辑，英语只新增入口导出（`buildSubjectEntry`，按第 2 节） | 11-26 |
| P2 | 数学、语文、物理、化学依次接入 | 11-27 首切片合并前完成 |
| P3 | 登录接口就绪后替换测试 UserId | 等身份服务登录接口 PR |

- 每个阶段以 PR 合并为完成。
- 学科的接入 PR 只改本学科目录，并在本契约定稿后提交。

## 6. 部署目标（定义，待总监审核）

- 平台：Cloudflare Pages，独立项目，项目名 `lelexue-hub`。
- 构建与发布：`main` 分支的构建发布到生产地址 `https://lelexue-hub.pages.dev`；其他分支自动生成预览地址，与现有 `lelexue` 项目的做法一致。
- 正式域名：另定，不在本契约内。
- 创建方式：项目由项目总监或真人在 Cloudflare 中创建并绑定本仓库，共通不自行创建。创建后在 #23 回复地址，若与上面不同以实际地址为准。
- 与学科的关系：学科的 Web 版本仍按各自地址部署，供开发与独立访问；正式用户入口为 hub 地址。学科地址不作为 hub 的依赖。
- 仓库中现有的 Pages 项目 `lelexue` 不改动。

## 7. 发行形态

- 用户只安装一个应用：hub。各学科的内容以 Dart 包的形式打进 hub，用户不需要分别下载学科应用。
- 学科的独立运行（各自的 `main.dart`）只用于开发与调试，不向用户单独发行。
- Web 版本的正式入口为 hub 地址（第 6 节）。学科的 Web 地址仅用于开发，不对用户作为入口。
