import 'game_item.dart';

/// 20 个问题：系统想好一个单词，玩家只能问「是/否」问题，缩小范围后猜出单词。
/// 每个问题的答案由规则自动算出，不需要为每个单词单独写问题。
class TwentyQuestions {
  TwentyQuestions({
    required List<GameItem> items,
    this.maxQuestions = 20,
    int secretIndex = 0,
  }) : _candidates = List<GameItem>.of(items),
       _secret = items[secretIndex % items.length];

  static const int defaultMax = 20;

  final int maxQuestions;
  final GameItem _secret;
  List<GameItem> _candidates;
  int asked = 0;
  bool solved = false;

  int get remainingCandidates => _candidates.length;
  bool get isOver => solved || asked >= maxQuestions;
  bool get isWon => solved;

  /// 可以问的问题：每个问题都能把候选词分成两部分（否则问了也没用）。
  List<YesNoQuestion> availableQuestions() {
    // 先放按词长、词组、首字母的问题，再放字母问题，保证问题种类多样。
    final out = <YesNoQuestion>[
      YesNoQuestion('超过 4 个字母吗？', (w) => w.text.length > 4),
      YesNoQuestion('是词组（有空格）吗？', (w) => w.text.contains(' ')),
      YesNoQuestion(
        '首字母在 a 到 m 之间吗？',
        (w) => w.text.toLowerCase().compareTo('n') < 0,
      ),
    ];
    for (final c in _lettersInCandidates()) {
      out.add(
        YesNoQuestion('包含字母 $c 吗？', (w) => w.text.toLowerCase().contains(c)),
      );
    }
    return out.where((q) => _splits(q)).toList();
  }

  /// 提问。返回答案；候选词只剩一个时，问题自动转为猜测。
  bool ask(YesNoQuestion q) {
    if (isOver) {
      throw StateError('游戏已结束');
    }
    asked++;
    final answer = q.test(_secret);
    _candidates = _candidates.where((w) => q.test(w) == answer).toList();
    if (_candidates.length == 1 && _candidates.first.id == _secret.id) {
      solved = true;
    }
    return answer;
  }

  /// 直接猜单词。猜中即胜利；猜错算一次提问，并把这个词排除掉。
  bool guess(GameItem word) {
    if (isOver) {
      throw StateError('游戏已结束');
    }
    asked++;
    if (word.id == _secret.id) {
      solved = true;
      return true;
    }
    _candidates = _candidates.where((c) => c.id != word.id).toList();
    return false;
  }

  /// 这个词是否仍是候选（没被排除）。
  bool candidatesContain(GameItem w) => _candidates.any((c) => c.id == w.id);

  /// 只在游戏结束时揭示答案。
  GameItem reveal() => _secret;

  bool _splits(YesNoQuestion q) {
    final yes = _candidates.where(q.test).length;
    return yes > 0 && yes < _candidates.length;
  }

  Iterable<String> _lettersInCandidates() {
    final letters = <String>{};
    for (final w in _candidates) {
      for (final ch in w.text.toLowerCase().split('')) {
        if (RegExp(r'[a-z]').hasMatch(ch)) {
          letters.add(ch);
        }
      }
    }
    final sorted = letters.toList()..sort();
    return sorted;
  }
}

/// 一个是/否问题。
class YesNoQuestion {
  const YesNoQuestion(this.text, this.test);

  final String text;
  final bool Function(GameItem) test;
}
