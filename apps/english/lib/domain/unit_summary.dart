import 'progress.dart';
import 'unit.dart';

/// 单元总结（纯领域规则）：星星、学会的词、错题本剩余，以及单元是否通关。
/// 通关 = 单元 Boss 通过。
class UnitSummary {
  const UnitSummary({
    required this.starsEarned,
    required this.starsTotal,
    required this.wordsLearned,
    required this.wordsTotal,
    required this.missedLeft,
    required this.complete,
  });

  final int starsEarned;
  final int starsTotal;
  final int wordsLearned;
  final int wordsTotal;
  final int missedLeft;
  final bool complete;

  factory UnitSummary.of(Unit unit, Progress progress) {
    var earned = 0;
    for (final level in unit.levels) {
      earned += progress.stars[level.id] ?? 0;
    }
    var learned = 0;
    var total = 0;
    for (final level in unit.levels.where((l) => l.stage == Stage.word)) {
      total += level.questions.length;
      if (progress.isPassed(level.id)) {
        learned += level.questions.length;
      }
    }
    final complete = unit.levels
        .where((l) => l.isBoss)
        .any((l) => progress.isPassed(l.id));
    return UnitSummary(
      starsEarned: earned,
      starsTotal: unit.levels.length * 3,
      wordsLearned: learned,
      wordsTotal: total,
      missedLeft: progress.missed.length,
      complete: complete,
    );
  }
}
