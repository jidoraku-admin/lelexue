import 'unit.dart';

/// 学习进度（本地保存）。
class Progress {
  Progress({Map<String, int>? stars, List<String>? remediation})
      : stars = stars ?? {},
        remediation = remediation ?? [];

  /// 关卡 id → 历史最高星级（0 表示未通过）。
  final Map<String, int> stars;

  /// Boss 失败后待补救的题目 id。非空时出现补救关，且 Boss 暂不可挑战。
  final List<String> remediation;

  static const remediationId = 'remediation-1';

  bool isPassed(String levelId) => (stars[levelId] ?? 0) > 0;

  void record(String levelId, int starCount) {
    final best = stars[levelId] ?? 0;
    if (starCount > best) stars[levelId] = starCount;
  }

  /// 按顺序生成当前路径：基础关卡，Boss 前可能插入补救关。
  List<Level> path(Unit unit) {
    final result = <Level>[];
    for (final level in unit.levels) {
      if (level.isBoss && remediation.isNotEmpty) {
        final index = unit.questionIndex;
        result.add(Level(
          id: remediationId,
          stage: Stage.remediation,
          title: '补救关',
          questions: [for (final id in remediation) if (index[id] != null) index[id]!],
          passRate: 1.0,
        ));
      }
      result.add(level);
    }
    return result;
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
      };

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        stars: (json['stars'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)),
        remediation: (json['remediation'] as List?)?.cast<String>(),
      );
}
