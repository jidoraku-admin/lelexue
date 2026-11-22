import 'unit.dart';

/// 20 个问题（英语版）：系统想好一个单词，玩家只能问「是/否」问题，缩小范围后猜出单词。
/// 每个问题的答案由规则自动算出，不需要为每个单词单独写问题。
class TwentyQuestions {
  TwentyQuestions({
    required List<Word> words,
    this.maxQuestions = 20,
    int secretIndex = 0,
  }) : _candidates = List<Word>.of(words),
       _secret = words[secretIndex % words.length];

  static const int defaultMax = 20;

  final int maxQuestions;
  final Word _secret;
  List<Word> _candidates;
  int asked = 0;
  bool solved = false;

  int get remainingCandidates => _candidates.length;
  bool get isOver => solved || asked >= maxQuestions;
  bool get isWon => solved;

  /// 可以问的问题：每个问题都能把候选词分成两部分（否则问了也没用）。
  List<YesNoQuestion> availableQuestions() {
    final out = <YesNoQuestion>[];
    for (final c in _lettersInCandidates()) {
      out.add(
        YesNoQuestion('包含字母 $c 吗？', (w) => w.en.toLowerCase().contains(c)),
      );
    }
    out.add(YesNoQuestion('超过 4 个字母吗？', (w) => w.en.length > 4));
    out.add(YesNoQuestion('是词组（有空格）吗？', (w) => w.en.contains(' ')));
    out.add(
      YesNoQuestion(
        '首字母在 a 到 m 之间吗？',
        (w) => w.en.toLowerCase().compareTo('n') < 0,
      ),
    );
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
    if (_candidates.length == 1 && _candidates.first.en == _secret.en) {
      solved = true;
    }
    return answer;
  }

  /// 直接猜单词。猜中即胜利，猜错算一次提问。
  bool guess(Word word) {
    if (isOver) {
      throw StateError('游戏已结束');
    }
    asked++;
    if (word.en == _secret.en) {
      solved = true;
      return true;
    }
    return false;
  }

  /// 这个词是否仍是候选（没被排除）。
  bool candidatesContain(Word w) => _candidates.any((c) => c.en == w.en);

  /// 只在游戏结束时揭示答案。
  Word reveal() => _secret;

  bool _splits(YesNoQuestion q) {
    final yes = _candidates.where(q.test).length;
    return yes > 0 && yes < _candidates.length;
  }

  Iterable<String> _lettersInCandidates() {
    final letters = <String>{};
    for (final w in _candidates) {
      for (final ch in w.en.toLowerCase().split('')) {
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
  final bool Function(Word) test;
}
