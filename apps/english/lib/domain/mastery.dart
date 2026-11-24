import 'mastery_rules.dart';
import 'progress.dart';

/// 一条已达到掌握规则的结果。
///
/// 只含学科侧可确定的字段（subject、知识点、层级、时间）。
/// userId 与 eventId 不在此生成：eventId 由数据平台发布时生成（gamification §8.1），
/// userId 待英语本地标识迁移到 UserId 后再补（identity.md §6）。
class MasteryAchievement {
  const MasteryAchievement({
    required this.knowledgePointId,
    required this.level,
    required this.achievedAt,
  });

  static const subject = 'english';

  final String knowledgePointId;
  final int level;

  /// UTC 时间。
  final DateTime achievedAt;

  /// 同一知识点、同一层级只达到一次的键。
  String get key => '$knowledgePointId#$level';

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'knowledgePointId': knowledgePointId,
    'level': level,
    'achievedAt': achievedAt.toUtc().toIso8601String(),
  };

  factory MasteryAchievement.fromJson(Map<String, dynamic> json) =>
      MasteryAchievement(
        knowledgePointId: json['knowledgePointId'] as String,
        level: json['level'] as int,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
      );
}

/// 纯函数：根据逐题记录和规则，找出本次新达到的结果（跳过已达到的）。
List<MasteryAchievement> evaluateMastery({
  required List<QuestionAttempt> attempts,
  required List<MasteryRule> rules,
  required Set<String> alreadyMastered,
  required DateTime now,
}) {
  final result = <MasteryAchievement>[];
  final seen = <String>{};
  for (final rule in rules) {
    final byKp = <String, List<QuestionAttempt>>{};
    for (final a in attempts) {
      if (a.itemType != rule.itemType.name) continue;
      byKp.putIfAbsent(a.knowledgePointId, () => []).add(a);
    }
    for (final entry in byKp.entries) {
      final list = entry.value;
      if (list.length < rule.minCount) continue;
      final correct = list.where((a) => a.correct).length;
      if (correct / list.length < rule.threshold) continue;
      final achievement = MasteryAchievement(
        knowledgePointId: entry.key,
        level: rule.level,
        achievedAt: now.toUtc(),
      );
      if (alreadyMastered.contains(achievement.key)) continue;
      if (!seen.add(achievement.key)) continue;
      result.add(achievement);
    }
  }
  return result;
}

/// 组装发送给数据平台的 MasteryChanged 业务字段。
///
/// 不含 eventId：由数据平台生成（gamification §8.1）。
/// 调用方必须提供已取得的 userId；没有 userId 时不应调用本函数。
Map<String, Object?> masteryChangedPayload(
  MasteryAchievement a, {
  required String userId,
}) {
  if (userId.trim().isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'must not be empty');
  }
  return {
    'userId': userId,
    'subject': MasteryAchievement.subject,
    'knowledgePointId': a.knowledgePointId,
    'level': a.level,
    'achievedAt': a.achievedAt.toUtc().toIso8601String(),
  };
}
