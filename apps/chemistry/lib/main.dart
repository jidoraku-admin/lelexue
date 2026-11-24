import 'package:material_ui/material_ui.dart';
import 'package:shared/core/core.dart';

import 'scoring/chemistry_scoring.dart';
import 'slices/e1_collect_method/e1_page.dart';
import 'slices/e3_oxygen_test/e3_page.dart';

void main() {
  runApp(ChemistryApp());
}

/// 乐乐学·化学。首个切片：E1、E3（第二单元「空气和氧气」）。E2 待项目总监决定。
class ChemistryApp extends StatefulWidget {
  ChemistryApp({super.key});

  // 演示用：本地用户与计分。持久化与发布由后续 PR 接入（发件箱 #92）。
  final ChemistryScoring _scoring = ChemistryScoring(userId: UserId('local-dev'), reviewInterval: const Duration(hours: 24));

  @override
  State<ChemistryApp> createState() => _ChemistryAppState();
}

class _ChemistryAppState extends State<ChemistryApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学·化学',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('乐乐学·化学')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => E1Page(scoring: widget._scoring)),
              ),
              child: const Text('E1 氧气的收集'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => E3Page(scoring: widget._scoring)),
              ),
              child: const Text('E3 氧气的检验'),
            ),
          ],
        ),
      ),
    );
  }
}
