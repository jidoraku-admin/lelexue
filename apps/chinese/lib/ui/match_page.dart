// §6B「字义与词义」：字与拼音配对界面。
//
// 左列为本单元生字，右列为打乱后的拼音。先点一个字、再点一个拼音（顺序不限），
// 配对正确则两项锁定变绿，错误则提示后清空选择。全部配对后显示完成与重玩。

import 'package:material_ui/material_ui.dart';
import 'package:shared/game_kit/game_kit.dart';

import '../domain/match_session.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({
    super.key,
    required this.config,
    this.rightOrder,
    this.onExit,
  });

  final MatchConfig config;

  /// 测试时固定右列顺序；为空时随机打乱。
  final List<int>? rightOrder;

  /// 由入口注入的返回动作；为空时只显示内容，不显示返回按钮。
  final VoidCallback? onExit;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  late MatchSession _session = _newSession();
  String _feedback = '先点一个字，再点它的拼音';

  MatchSession _newSession() =>
      MatchSession(widget.config, rightOrder: widget.rightOrder);

  void _tap(MatchSide side, int index) {
    setState(() {
      switch (_session.tap(side, index)) {
        case MatchOutcome.correct:
          _feedback = _session.isComplete ? '全部配对完成！' : '对了！';
        case MatchOutcome.wrong:
          _feedback = '再想想，读一读这个字';
        case MatchOutcome.selected:
          break;
      }
    });
  }

  void _restart() {
    setState(() {
      _session = _newSession();
      _feedback = '先点一个字，再点它的拼音';
    });
  }

  Widget _tile(MatchSide side, int index, GameItem item, bool selected) {
    final matched = _session.isMatched(item.id);
    final scheme = Theme.of(context).colorScheme;
    final color = matched
        ? Colors.green.shade100
        : selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final key = '${side.name}-${item.id}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey(key),
          borderRadius: BorderRadius.circular(12),
          onTap: matched ? null : () => _tap(side, index),
          child: SizedBox(
            height: 64,
            child: Center(
              child: Text(
                item.prompt,
                style: TextStyle(
                  fontSize: side == MatchSide.left ? 32 : 24,
                  color: matched ? Colors.green.shade800 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = _session.leftItems;
    final right = _session.rightItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('字义与词义 · 字音配对'),
        leading: widget.onExit == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '返回',
                onPressed: widget.onExit,
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '已配对 ${_session.matchedCount} / ${left.length}',
                key: const ValueKey('progress'),
              ),
              const SizedBox(height: 4),
              Text(_feedback, key: const ValueKey('feedback')),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [
                          for (var i = 0; i < left.length; i++)
                            _tile(MatchSide.left, i, left[i],
                                _session.selectedLeft == i),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(children: [
                          for (var i = 0; i < right.length; i++)
                            _tile(MatchSide.right, i, right[i],
                                _session.selectedRight == i),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              if (_session.isComplete)
                FilledButton(
                  key: const ValueKey('restart'),
                  onPressed: _restart,
                  child: const Text('再玩一次'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
