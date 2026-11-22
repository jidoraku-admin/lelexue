import 'dart:math';

import 'unit.dart';

/// 下落类小游戏（青蛙吃虫、打飞机）的规则：屏幕上会下落单词，玩家要点中提示的那个。
/// 点中目标得分并换下一个目标；点错扣命；目标掉到底部也扣命。
class FallingRound {
  FallingRound({
    required this.words,
    required this.goal,
    this.lives = 3,
    int seed = 0,
  }) : assert(words.isNotEmpty),
       _random = Random(seed) {
    _pickTarget();
  }

  final List<Word> words;
  final int goal;
  final Random _random;

  late Word target;
  int score = 0;
  int lives;

  bool get isOver => score >= goal || lives <= 0;
  bool get isWon => score >= goal;

  /// 随机取一个非目标的词，用作干扰项。
  Word randomDistractor() {
    final others = words.where((w) => w.en != target.en).toList();
    if (others.isEmpty) return target;
    return others[_random.nextInt(others.length)];
  }

  /// 点中一个单词。返回是否点中了目标。
  bool hit(Word word) {
    if (isOver) return false;
    if (word.en == target.en) {
      score++;
      if (!isOver) _pickTarget();
      return true;
    }
    lives--;
    return false;
  }

  /// 目标掉到底部没有被点中。
  void targetEscaped() {
    if (isOver) return;
    lives--;
    if (!isOver) _pickTarget();
  }

  void _pickTarget() {
    target = words[_random.nextInt(words.length)];
  }
}
