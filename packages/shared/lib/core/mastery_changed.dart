import 'subject_code.dart';
import 'user_id.dart';

/// 掌握度变化事件（候选 schema，#23 范围更正）。
///
/// 由数据平台或学科服务发布；共享游戏化只消费它。
/// `level` 的含义由学科定义（如英语的 1★ 识别、2★ 应用、3★ 迁移）。
/// `eventId` 作为幂等键，同一事件重复投递不得重复计分。
class MasteryChanged {
  MasteryChanged({
    required this.eventId,
    required this.userId,
    required this.subject,
    required this.knowledgePointId,
    required this.level,
    required this.achievedAt,
  }) {
    if (eventId.trim().isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'must not be empty');
    }
    if (knowledgePointId.trim().isEmpty) {
      throw ArgumentError.value(knowledgePointId, 'knowledgePointId', 'must not be empty');
    }
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'must be at least 1');
    }
    if (!achievedAt.isUtc) {
      throw ArgumentError.value(achievedAt, 'achievedAt', 'must be UTC');
    }
  }

  final String eventId;
  final UserId userId;
  final SubjectCode subject;
  final String knowledgePointId;
  final int level;
  final DateTime achievedAt;

  /// 同一知识点的经验只给一次的唯一键（gamification §3）。
  (UserId, SubjectCode, String, int) get dedupeKey =>
      (userId, subject, knowledgePointId, level);
}
