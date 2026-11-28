import 'package:material_ui/material_ui.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';
import 'package:shared/game_kit/game_kit.dart';

import 'data/unit1_loader.dart';
import 'domain/chinese_unit1_adapter.dart';
import 'ui/match_page.dart';

/// hub 调用的语文入口（契约 #141 第 2 节）。
///
/// 只接收 [userId] 与 [subject]，返回时调用 [onExit]，由 hub 回到入口页。
/// 当前只开放 §6B 第一步「字义与词义」的字音配对；[userId] 留待计分接入。
/// [loader] 与 [onAnswer] 仅供测试注入。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
  Future<ChineseUnit1Data> Function()? loader,
  AnswerReporter? onAnswer,
}) {
  return ChineseEntry(
    onExit: onExit,
    loader: loader ?? loadUnit1Data,
    onAnswer: onAnswer ?? (_) {},
  );
}

class ChineseEntry extends StatefulWidget {
  const ChineseEntry({
    super.key,
    required this.onExit,
    required this.loader,
    required this.onAnswer,
  });

  final VoidCallback onExit;
  final Future<ChineseUnit1Data> Function() loader;
  final AnswerReporter onAnswer;

  @override
  State<ChineseEntry> createState() => _ChineseEntryState();
}

class _ChineseEntryState extends State<ChineseEntry> {
  late final Future<ChineseUnit1Data> _data = widget.loader();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 由本入口接管返回：先通知 hub，再由 hub 移除本路由。
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('乐乐学·语文'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: widget.onExit,
          ),
        ),
        body: FutureBuilder<ChineseUnit1Data>(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('题目加载失败，请稍后再试'));
            }
            final data = snap.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('三年级上册 · 第 1 单元'),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const ValueKey('step-match'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MatchPage(
                        config: buildMatchConfig(data, widget.onAnswer),
                      ),
                    ),
                  ),
                  child: const Text('第一步 字义与词义：字音配对'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
