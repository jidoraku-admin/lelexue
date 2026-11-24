import 'package:shared/core/core.dart';

/// 化学学科内计分（依据 docs/product/chemistry.md 第 2 节与 docs/product/chemistry-3star-draft.md）。
///
/// 规则：
/// - 1★ 识别、2★ 应用：正确率 ≥80% 且不少于 5 题。
/// - 3★ 迁移：同时满足
///   (a) 新语境作答正确率 ≥80% 且不少于 5 题；
///   (b) 间隔复习通过一次：2★ 达到后，间隔 [reviewInterval] 之后答对一道复习题。
///   间隔时长是学科参数，由配置传入，不写死在代码中。
/// - 同一 (knowledgePointId, level) 只在首次达到门槛时产生一条掌握草稿（经验只给一次）。
/// - 本类不发布事件，eventId 由发件箱在发布时生成（幂等键）。
class ChemistryScoring {
  ChemistryScoring({required this.userId, required this.reviewInterval});

  /// 掌握判定的最少题数。
  static const int minAttempts = 5;

  /// 掌握判定的正确率门槛，用整数比较避免浮点误差：correct * 5 >= attempts * 4 即 ≥80%。
  static const int accuracyNumerator = 4;
  static const int accuracyDenominator = 5;

  final UserId userId;

  /// 间隔复习的最短间隔（学科参数，由后台配置传入）。
  final Duration reviewInterval;

  final Map<_Key, _Tally> _tallies = {};
  final Set<_Key> _mastered = {};
  final List<MasteryDraft> _pending = [];

  /// 每个知识点 2★ 达到的时间（UTC），用于安排间隔复习。
  final Map<String, DateTime> _twoStarAt = {};

  /// 已通过间隔复习的知识点。
  final Set<String> _reviewPassed = {};

  /// 记录一次作答。返回本次是否使该 (知识点, 等级) 首次达到掌握门槛。
  ///
  /// 3★ 只接受新语境作答（[newContext] 为 true），否则抛出 ArgumentError。
  bool recordAnswer({
    required String knowledgePointId,
    required int level,
    required bool correct,
    required DateTime answeredAt,
    bool newContext = false,
  }) {
    _validate(knowledgePointId, level);
    if (level == 3 && !newContext) {
      throw ArgumentError.value(newContext, 'newContext', '3★ 只统计新语境作答');
    }
    final key = _Key(knowledgePointId, level);
    if (_mastered.contains(key)) return false;

    final tally = _tallies.putIfAbsent(key, _Tally.new);
    tally.add(correct);

    if (level == 3) {
      return _tryMaster3(knowledgePointId, answeredAt);
    }

    if (_meetsThreshold(tally)) {
      _mastered.add(key);
      _pending.add(MasteryDraft(
        userId: userId,
        subject: SubjectCode.chemistry,
        knowledgePointId: knowledgePointId,
        level: level,
        achievedAt: answeredAt.toUtc(),
      ));
      if (level == 2) _twoStarAt[knowledgePointId] = answeredAt.toUtc();
      return true;
    }
    return false;
  }

  /// 记录一次间隔复习题的作答。
  ///
  /// 只有以下情况计为通过一次：2★ 已达到、距 2★ 达到不少于 [reviewInterval]、且答对。
  /// 过早作答或答错不计，之后可再次安排复习。返回本次是否使 3★ 首次达到门槛。
  bool recordReview({
    required String knowledgePointId,
    required bool correct,
    required DateTime answeredAt,
  }) {
    _validate(knowledgePointId, 1);
    final twoStar = _twoStarAt[knowledgePointId];
    if (twoStar == null) return false;
    if (_reviewPassed.contains(knowledgePointId)) return false;
    final utc = answeredAt.toUtc();
    if (utc.difference(twoStar) < reviewInterval) return false;
    if (!correct) return false;
    _reviewPassed.add(knowledgePointId);
    return _tryMaster3(knowledgePointId, utc);
  }

  /// 取出待发布的掌握草稿，取出后清空。发布方（数据平台，#92）负责分配 eventId 并投递。
  List<MasteryDraft> drainPendingMastery() {
    final out = List<MasteryDraft>.unmodifiable(_pending);
    _pending.clear();
    return out;
  }

  bool _tryMaster3(String knowledgePointId, DateTime at) {
    final key = _Key(knowledgePointId, 3);
    if (_mastered.contains(key)) return false;
    if (!_reviewPassed.contains(knowledgePointId)) return false;
    final tally = _tallies[key];
    if (tally == null || !_meetsThreshold(tally)) return false;
    _mastered.add(key);
    _pending.add(MasteryDraft(
      userId: userId,
      subject: SubjectCode.chemistry,
      knowledgePointId: knowledgePointId,
      level: 3,
      achievedAt: at.toUtc(),
    ));
    return true;
  }

  static bool _meetsThreshold(_Tally t) =>
      t.attempts >= minAttempts && t.correct * accuracyDenominator >= t.attempts * accuracyNumerator;

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
