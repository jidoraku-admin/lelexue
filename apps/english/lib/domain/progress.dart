import 'unit.dart';

/// 学习进度（纯领域规则，不依赖存储）。
class Progress {
  Progress({Map<String, int>? stars, List<String>? remediation, List<String>? missed})
      : stars = stars ?? {},
        remediation = remediation ?? [],
        missed = missed ?? [];

  /// 关卡 id → 历史最高星级（0 表示未通过）。
  final Map<String, int> stars;

  /// Boss 失败后待补救的题目 id。非空时出现补救关，且 Boss 暂不可挑战。
  final List<String> remediation;

  /// 学过程中答错、尚未复习通过的题目 id，供复习关使用（v0.16 §2.2）。
  final List<String> missed;

  static const remediationId = 'remediation-1';
  static const reviewId = 'review-1';
  static const maxMissed = 30;

  bool isPassed(String levelId) => (stars[levelId] ?? 0) > 0;

  void record(String levelId, int starCount) {
    final best = stars[levelId] ?? 0;
    if (starCount > best) stars[levelId] = starCount;
  }

  /// 记录一次挑战中答错的题目（去重，超出上限时丢弃最早的）。
  void addMissed(Iterable<String> ids) {
    for (final id in ids) {
      if (!missed.contains(id)) missed.add(id);
    }
    while (missed.length > maxMissed) {
      missed.removeAt(0);
    }
  }

  /// 复习关中答对的题目从错题本移除。
  void clearMissed(Iterable<String> ids) => missed.removeWhere(ids.contains);

  /// 按顺序生成当前路径：基础关卡，Boss 前可能插入补救关，Boss 后是复习关。
  List<Level> path(Unit unit) {
    final index = unit.questionIndex;
    final result = <Level>[];
    for (final level in unit.levels) {
      if (level.isBoss && remediation.isNotEmpty) {
        result.add(Level(
          id: remediationId,
          stage: Stage.remediation,
          title: '补救关',
          questions: [for (final id in remediation) if (index[id] != null) index[id]!],
          passRate: 1.0,
        ));
      }
      result.add(level);
      if (level.isBoss) {
        result.add(Level(
          id: reviewId,
          stage: Stage.review,
          title: '复习关',
          questions: _reviewQuestions(unit),
          passRate: 0.6,
        ));
      }
    }
    return result;
  }

  /// 复习题：优先取错题；没有错题时，按间隔抽取单元词汇保持记忆。
  List<Question> _reviewQuestions(Unit unit) {
    final index = unit.questionIndex;
    final fromMissed = [for (final id in missed) if (index[id] != null) index[id]!];
    if (fromMissed.isNotEmpty) return fromMissed;
    final words = unit.levels.where((l) => l.stage == Stage.word).expand((l) => l.questions).toList();
    if (words.isEmpty) return const [];
    final step = words.length / 6;
    return [for (var k = 0; k < 6 && (k * step).floor() < words.length; k++) words[(k * step).floor()]];
  }

  /// 关卡是否可挑战：第一关总是可以；其余需要前一关通过。
  bool isUnlocked(List<Level> path, int position) {
    if (position == 0) return true;
    final prev = path[position - 1];
    if (!isPassed(prev.id)) return false;
    final level = path[position];
    if (level.isBoss && remediation.isNotEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        'remediation': remediation,
        'missed': missed,
      };

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        stars: (json['stars'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)),
        remediation: (json['remediation'] as List?)?.cast<String>(),
        missed: (json['missed'] as List?)?.cast<String>(),
      );
}
