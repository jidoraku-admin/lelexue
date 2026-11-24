import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';

import 'ui/unit_list_page.dart';

/// 统一入口（apps/hub）调用的英语入口（契约第 2 节）。
/// 独立运行的 main.dart 保留。
/// P1 阶段返回英语单元列表页；[userId] 与 [subject] 暂未使用，留待后续接入。
/// 返回（系统返回键或页面返回按钮）时调用 [onExit]，由 hub 回到入口页（契约第 4 节）。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
}) {
  return _HubEntry(onExit: onExit);
}

class _HubEntry extends StatelessWidget {
  const _HubEntry({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 由本入口接管返回：先通知 hub，再由 hub 移除本路由。
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onExit();
      },
      child: const UnitListPage(),
    );
  }
}
