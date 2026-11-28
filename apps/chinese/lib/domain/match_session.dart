// §6B「字义与词义」配对（字与拼音）的作答逻辑。
//
// 与界面分离，便于单测。只判断对错与用时，通过 MatchConfig.onAnswer 上报；
// 计分与记录由调用方处理（0010：框架不计分）。

import 'package:shared/game_kit/game_kit.dart';

/// 配对的一侧：left 为字，right 为拼音。
enum MatchSide { left, right }

/// 一次配对尝试的结果。
enum MatchOutcome { selected, correct, wrong }

class MatchSession {
  MatchSession(this.config, {DateTime Function()? clock, List<int>? rightOrder})
      : _clock = clock ?? DateTime.now,
        rightOrder = rightOrder ??
            (List<int>.generate(config.pairs.length, (i) => i)..shuffle()) {
    if (this.rightOrder.length != config.pairs.length ||
        this.rightOrder.toSet().length != config.pairs.length) {
      throw ArgumentError('rightOrder 必须是 0..${config.pairs.length - 1} 的一个排列');
    }
    _since = _clock();
  }

  final MatchConfig config;
  final DateTime Function() _clock;

  /// 右侧（拼音）的展示顺序：第 i 个位置显示 pairs[rightOrder[i]].$2。
  final List<int> rightOrder;

  late DateTime _since;
  int? _selectedLeft;
  int? _selectedRight;
  final Set<String> _matched = {};

  List<GameItem> get leftItems => [for (final p in config.pairs) p.$1];
  List<GameItem> get rightItems => [for (final i in rightOrder) config.pairs[i].$2];

  int? get selectedLeft => _selectedLeft;
  int? get selectedRight => _selectedRight;
  bool isMatched(String id) => _matched.contains(id);
  int get matchedCount => _matched.length;
  bool get isComplete => _matched.length == config.pairs.length;

  /// 点选某一侧的第 [index] 项。两侧各选一项后判定并上报。
  MatchOutcome tap(MatchSide side, int index) {
    final items = side == MatchSide.left ? leftItems : rightItems;
    if (index < 0 || index >= items.length) {
      throw RangeError.index(index, items, 'index');
    }
    if (_matched.contains(items[index].id)) return MatchOutcome.selected;

    if (side == MatchSide.left) {
      _selectedLeft = index;
    } else {
      _selectedRight = index;
    }
    if (_selectedLeft == null || _selectedRight == null) {
      return MatchOutcome.selected;
    }

    final left = leftItems[_selectedLeft!];
    final right = rightItems[_selectedRight!];
    final now = _clock();
    final correct = left.id == right.id;
    config.onAnswer(GameAnswer(
      itemId: left.id,
      correct: correct,
      durationMs: now.difference(_since).inMilliseconds,
    ));
    _since = now;
    _selectedLeft = null;
    _selectedRight = null;
    if (correct) {
      _matched.add(left.id);
      return MatchOutcome.correct;
    }
    return MatchOutcome.wrong;
  }
}
