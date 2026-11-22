import 'dart:math';

import 'unit.dart';

/// 下落速度等级。step 是每次刷新下落的比例，spawnEvery 是多少次刷新出现一个单词。
enum FallingSpeed {
  slow('慢', 0.006, 48),
  normal('中', 0.011, 36),
  fast('快', 0.018, 26);

  const FallingSpeed(this.label, this.step, this.spawnEvery);

  final String label;
  final double step;
  final int spawnEvery;
}

/// 一次命中的分数：基础 10 分，连击越多加分越多（最多加到 20 分）。
int pointsForStreak(int streak) => 10 + (streak - 1).clamp(0, 4) * 5;

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
  int points = 0;
  int streak = 0;
  int bestStreak = 0;

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
      streak++;
      if (streak > bestStreak) bestStreak = streak;
      points += pointsForStreak(streak);
      if (!isOver) _pickTarget();
      return true;
    }
    lives--;
    streak = 0;
    return false;
  }

  /// 目标掉到底部没有被点中。
  void targetEscaped() {
    if (isOver) return;
    lives--;
    streak = 0;
    if (!isOver) _pickTarget();
  }

  void _pickTarget() {
    target = words[_random.nextInt(words.length)];
  }
}
