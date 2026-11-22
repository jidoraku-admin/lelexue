// 物理学科适配层的掌握度草稿。
//
// 按共通 v1 与 #5（2026-11-22 21:54 JST 修改）：
// - 物理只产生草稿，不生成 eventId，也不直接发布 MasteryChanged。
// - eventId 由数据平台在发布时生成（gamification.md 第 2 节）。
// - 1★ 已由项目总监于 #5 审核通过（2026-11-22 14:11 UTC）；规则在 mastery_rules.dart 声明。
import 'package:shared/core/core.dart';

/// 物理 1★ 规则数值与 mastery_rules.dart 保持一致。
const double level1MinAccuracy = 0.8;
const int level1MinAttempts = 5;

class MasteryDraft {
  const MasteryDraft({
    required this.knowledgePointId,
    required this.level,
    required this.attempts,
    required this.correct,
  });

  /// 固定为 physics；与 SubjectCode 一致。
  final SubjectCode subject = SubjectCode.physics;
  final String knowledgePointId;

  /// 1、2、3，对应 1★、2★、3★。
  final int level;
  final int attempts;
  final int correct;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// 是否满足本学科 1★ 规则。
  bool get meetsLevel1Rule =>
      attempts >= level1MinAttempts && accuracy >= level1MinAccuracy;
}

/// 按作答记录生成 1★ 草稿。[results] 每题为 true（正确）或 false（错误）。
MasteryDraft buildLevel1Draft({
  required String knowledgePointId,
  required List<bool> results,
}) {
  if (!_isValidKnowledgePointId(knowledgePointId)) {
    throw ArgumentError.value(
        knowledgePointId, 'knowledgePointId', 'must follow <subject>.g<grade>.v<volume>.u<unit>.k<seq>');
  }
  return MasteryDraft(
    knowledgePointId: knowledgePointId,
    level: 1,
    attempts: results.length,
    correct: results.where((r) => r).length,
  );
}

final RegExp _kpPattern =
    RegExp(r'^physics\.g(\d{1,2})\.v[12]\.u\d{2}\.k\d{3}$');

bool _isValidKnowledgePointId(String id) {
  final m = _kpPattern.firstMatch(id);
  if (m == null) return false;
  final grade = int.parse(m.group(1)!);
  return grade >= 1 && grade <= 12;
}
