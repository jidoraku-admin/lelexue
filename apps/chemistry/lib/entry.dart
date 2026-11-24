import 'package:material_ui/material_ui.dart';
import 'package:shared/core/core.dart';

import 'config.dart';
import 'scoring/chemistry_scoring.dart';
import 'slices/e1_collect_method/e1_page.dart';
import 'slices/e3_oxygen_test/e3_page.dart';

/// hub 调用的学科入口（契约 #141 第 2 节）。
///
/// 只接收 [userId] 与 [subject]，返回时调用 [onExit]，由 hub 回到入口页。
/// 独立运行的 main.dart 保留，不受影响。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
}) {
  return _ChemistryEntry(userId: userId, onExit: onExit);
}

class _ChemistryEntry extends StatefulWidget {
  const _ChemistryEntry({required this.userId, required this.onExit});

  final UserId userId;
  final VoidCallback onExit;

  @override
  State<_ChemistryEntry> createState() => _ChemistryEntryState();
}

class _ChemistryEntryState extends State<_ChemistryEntry> {
  // 复习间隔由后台配置下发（lib/config.dart）；未配置时 3★ 不启用。
  late final ChemistryScoring _scoring = ChemistryScoring(
    userId: widget.userId,
    reviewInterval: chemistryReviewInterval,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乐乐学·化学'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => E1Page(scoring: _scoring)),
            ),
            child: const Text('E1 氧气的收集'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => E3Page(scoring: _scoring)),
            ),
            child: const Text('E3 氧气的检验'),
          ),
        ],
      ),
    );
  }
}
