import 'package:flutter/foundation.dart';
import 'package:shared/core/user_id.dart';

/// P0：身份服务登录接口尚未就绪（契约第 3 节）。
/// 仅在开发构建中从 `--dart-define=HUB_DEV_USER_ID=...` 读取测试 UserId。
/// 生产构建（kReleaseMode）一律返回 null，即未登录。
UserId? currentDevUserId() {
  if (kReleaseMode) return null;
  const raw = String.fromEnvironment('HUB_DEV_USER_ID');
  if (raw.isEmpty) return null;
  return UserId(raw);
}
