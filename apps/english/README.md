# lelexue_english（英语）

Flutter 应用。按仓库决定 0014，线上预览（Cloudflare Pages）已停用，统一查看通过部署机本地构建的 Web 版完成。

## 本地运行与验证

```bash
cd apps/english
flutter pub get
flutter analyze
flutter test          # 全量测试，PR 中附完整输出
flutter run -d chrome # 本地调试 Web 版
```

- 身份服务相关的功能，需先按 `services/identity/LOCAL.md` 在本地启动身份服务。
- 不开放局域网端口，学生数据只在本机。

## 发布

- Web 版由部署机按 `scripts/web/build_web.sh` 构建，产物为 `dist/web`。
- 源代码以 GitHub 仓库为准。
