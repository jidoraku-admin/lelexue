import 'package:material_ui/material_ui.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';

import 'ui/unit_list_page.dart';

/// 统一入口（apps/hub）调用的英语入口（契约第 2 节）。
/// 独立运行的 main.dart 保留。
/// P1 阶段仅返回英语单元列表页；[userId] 与 [subject] 暂未使用，留待后续接入。
/// 返回按钮由 hub 的 Navigator 处理，[onExit] 暂不在本入口内调用。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
}) {
  return const UnitListPage();
}
