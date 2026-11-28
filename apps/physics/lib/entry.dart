import 'package:material_ui/material_ui.dart';
import 'package:shared/core/core.dart';

import 'main.dart' show FirstSlicePage;
import 'p2_speed_page.dart';

/// hub 调用的学科入口（hub 契约第 2 节）。
///
/// 只接收 [userId] 与 [subject]，返回时调用 [onExit]，由 hub 回到入口页。
/// 独立运行的 main.dart 保留，不受影响。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
}) {
  return _PhysicsEntry(userId: userId, onExit: onExit);
}

class _PhysicsEntry extends StatelessWidget {
  const _PhysicsEntry({required this.userId, required this.onExit});

  // 掌握度事件接入前暂不使用；保留以符合契约。
  final UserId userId;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乐乐学·物理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onExit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FirstSlicePage()),
            ),
            child: const Text('P1 赛道测速：刻度尺读数'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const P2SpeedPage()),
            ),
            child: const Text('P2 测量小车的平均速度'),
          ),
        ],
      ),
    );
  }
}
