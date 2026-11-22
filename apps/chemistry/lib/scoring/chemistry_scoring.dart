import 'package:shared/core/core.dart';

/// 化学学科内计分（#20 实现方案第 4 节，依据 docs/product/chemistry.md 第 2 节掌握门槛）。
///
/// 规则：
/// - 1★ 识别、2★ 应用：正确率 ≥80% 且不少于 5 题。
/// - 同一 (knowledgePointId, level) 只在首次达到门槛时产生一条掌握草稿（经验只给一次）。
/// - 3★ 迁移的判定依赖间隔复习，尚未设计，本骨架不实现（调用会抛出 UnsupportedError）。
/// - 本类不发布事件，eventId 由发件箱在发布时生成（幂等键）。
class ChemistryScoring {
  ChemistryScoring({required this.userId});

  /// 掌握判定的最少题数。
  static const int minAttempts = 5;

  /// 掌握判定的正确率门槛，用整数比较避免浮点误差：correct * 5 >= attempts * 4 即 ≥80%。
  static const int accuracyNumerator = 4;
  static const int accuracyDenominator = 5;

  final UserId userId;

  final Map<_Key, _Tally> _tallies = {};
  final Set<_Key> _mastered = {};
  final List<MasteryDraft> _pending = [];

  /// 记录一次作答。返回本次是否使该 (知识点, 等级) 首次达到掌握门槛。
  bool recordAnswer({
    required String knowledgePointId,
    required int level,
    required bool correct,
    required DateTime answeredAt,
  }) {
    _validate(knowledgePointId, level);
    if (level == 3) {
      throw UnsupportedError('3★ 迁移的判定尚未设计（依赖间隔复习），本骨架不支持。');
    }
    final key = _Key(knowledgePointId, level);
    if (_mastered.contains(key)) return false;

    final tally = _tallies.putIfAbsent(key, _Tally.new);
    tally.add(correct);

    if (tally.attempts >= minAttempts &&
        tally.correct * accuracyDenominator >= tally.attempts * accuracyNumerator) {
      _mastered.add(key);
      _pending.add(MasteryDraft(
        userId: userId,
        subject: SubjectCode.chemistry,
        knowledgePointId: knowledgePointId,
        level: level,
        achievedAt: answeredAt.toUtc(),
      ));
      return true;
    }
    return false;
  }

  /// 取出待发布的掌握草稿，取出后清空。发布方（数据平台，#92）负责分配 eventId 并投递。
  List<MasteryDraft> drainPendingMastery() {
    final out = List<MasteryDraft>.unmodifiable(_pending);
    _pending.clear();
    return out;
  }

  static void _validate(String knowledgePointId, int level) {
    if (!_knowledgePointIdPattern.hasMatch(knowledgePointId)) {
      throw ArgumentError.value(
        knowledgePointId,
        'knowledgePointId',
        '须符合 chemistry.g<grade>.v<volume>.u<unit>.k<seq> 格式',
      );
    }
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'must be at least 1');
    }
  }

  static final RegExp _knowledgePointIdPattern =
      RegExp(r'^chemistry\.g\d+\.v\d+\.u\d+\.k\d{3}$');
}

/// 掌握草稿：与 MasteryChanged v1 对应，缺 eventId（由发件箱生成）。
class MasteryDraft {
  const MasteryDraft({
    required this.userId,
    required this.subject,
    required this.knowledgePointId,
    required this.level,
    required this.achievedAt,
  });

  final UserId userId;
  final SubjectCode subject;
  final String knowledgePointId;
  final int level;

  /// UTC 时间。
  final DateTime achievedAt;
}

class _Key {
  const _Key(this.knowledgePointId, this.level);

  final String knowledgePointId;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is _Key && other.knowledgePointId == knowledgePointId && other.level == level;

  @override
  int get hashCode => Object.hash(knowledgePointId, level);
}

class _Tally {
  int attempts = 0;
  int correct = 0;

  void add(bool isCorrect) {
    attempts++;
    if (isCorrect) correct++;
  }
}
