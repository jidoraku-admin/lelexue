// 第 1 单元「观察物体」的作答界面（学科内实现，#3）。
// 两种玩法共用一个界面：显示题干与选项，作答后给出对错反馈。
import 'package:material_ui/material_ui.dart';

import '../mastery/mastery_tracker.dart';
import 'judge.dart';

class Unit01Page extends StatefulWidget {
  const Unit01Page({
    super.key,
    required this.items,
    this.tracker,
    this.onMasteryDrafts,
  });

  final List<Unit01Item> items;

  /// 掌握度记录（#3 F5）；不传时界面内部新建一个。
  final MasteryTracker? tracker;

  /// 有知识点新达到 1★ 时回调，草稿交数据平台发布（#92）。
  final void Function(List<MasteryDraft> drafts)? onMasteryDrafts;

  @override
  State<Unit01Page> createState() => _Unit01PageState();
}

class _Unit01PageState extends State<Unit01Page> {
  int _index = 0;
  String? _feedback;
  late final MasteryTracker _tracker = widget.tracker ?? MasteryTracker();

  void _answer(Unit01Item item, String choice) {
    final correct = judgeChoice(item, choice);
    _tracker.record(item.id, correct);
    final drafts = _tracker.takeNewDrafts();
    if (drafts.isNotEmpty) widget.onMasteryDrafts?.call(drafts);
    setState(() {
      _feedback = correct ? '对啦！你已经会从不同的地方看啦。' : '别着急，换个角度再看一次。';
    });
  }

  void _next() {
    setState(() {
      _index++;
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.items.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('这一单元你学会了从不同位置观察，下一站再见！'),
            const SizedBox(height: 8),
            Text(
              '本轮答对 ${_tracker.totalCorrect} / ${_tracker.totalAttempts} 题',
              key: const Key('summary'),
            ),
          ],
        ),
      );
    }
    final item = widget.items[_index];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('视视：我是视视！同一个东西，换个地方看，样子可能不一样哦。', key: Key('guide-opening')),
          const SizedBox(height: 12),
          Text(item.prompt, key: const Key('prompt'), style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          for (final option in item.options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                key: Key('option-$option'),
                onPressed: _feedback == null ? () => _answer(item, option) : null,
                child: Text(option),
              ),
            ),
          const SizedBox(height: 16),
          if (_feedback != null) ...[
            Text(_feedback!, key: const Key('feedback')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _next, child: const Text('下一题')),
          ],
        ],
      ),
    );
  }
}
