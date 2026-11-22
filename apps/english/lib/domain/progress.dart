import 'level_run.dart';
import 'mastery.dart';
import 'mastery_rules.dart';
import 'unit.dart';

/// 一次逐题作答记录（首次作答），带知识点编码，供掌握记录使用。
class QuestionAttempt {
  const QuestionAttempt({
    required this.questionId,
    required this.knowledgePointId,
    required this.levelId,
    required this.correct,
    required this.answeredAt,
    this.itemType,
  });

  final String questionId;
  final String knowledgePointId;
  final String levelId;
  final bool correct;
  final DateTime answeredAt;

  /// 题型（Stage 名称，如 use）。旧记录没有该字段，为 null。
  final String? itemType;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'knowledgePointId': knowledgePointId,
    'levelId': levelId,
    'correct': correct,
    'answeredAt': answeredAt.toUtc().toIso8601String(),
    if (itemType != null) 'itemType': itemType,
  };

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) =>
      QuestionAttempt(
        questionId: json['questionId'] as String,
        knowledgePointId: json['knowledgePointId'] as String,
        levelId: json['levelId'] as String,
        correct: json['correct'] as bool,
        answeredAt: DateTime.parse(json['answeredAt'] as String),
        itemType: json['itemType'] as String?,
      );
}

/// 学习进度（纯领域规则，不依赖存储）。
class Progress {
  Progress({
    Map<String, int>? stars,
    List<String>? remediation,
    List<String>? missed,
    List<QuestionAttempt>? attempts,
    List<MasteryAchievement>? pendingAchievements,
    List<String>? mastered,
  }) : stars = stars ?? {},
       remediation = remediation ?? [],
       missed = missed ?? [],
       attempts = attempts ?? [],
       pendingAchievements = pendingAchievements ?? [],
       mastered = mastered ?? [];

  /// 关卡 id → 历史最高星级（0 表示未通过）。
  final Map<String, int> stars;

  /// Boss 失败后待补救的题目 id。非空时出现补救关，且 Boss 暂不可挑战。
  final List<String> remediation;

  /// 学过程中答错、尚未复习通过的题目 id，供复习关使用（v0.16 §2.2）。
  final List<String> missed;

  /// 带知识点编码的逐题首次作答记录（按时间追加）。
  final List<QuestionAttempt> attempts;

  /// 已首次达到的掌握规则，键为 `knowledgePointId#level`。
  final List<String> mastered;

  /// 已达到但尚未交给数据平台的掌握结果（本地待发布队列，不含 userId 与 eventId）。
  final List<MasteryAchievement> pendingAchievements;

  static const remediationId = 'remediation-1';
  static const reviewId = 'review-1';
  static const maxMissed = 30;

  bool isPassed(String levelId) => (stars[levelId] ?? 0) > 0;

  void record(String levelId, int starCount) {
    final best = stars[levelId] ?? 0;
    if (starCount > best) stars[levelId] = starCount;
  }

  /// 记录一关的首次作答；未标注知识点的题目不记录。
  void recordAttempts(
    String levelId,
    Iterable<FirstAnswer> answers,
    DateTime answeredAt,
  ) {
    for (final a in answers) {
      final kp = a.question.knowledgePointId;
      if (kp == null) continue;
      attempts.add(
        QuestionAttempt(
          questionId: a.question.id,
          knowledgePointId: kp,
          levelId: levelId,
          correct: a.correct,
          answeredAt: answeredAt,
          itemType: a.stage.name,
        ),
      );
    }
  }

  /// 按英语掌握规则判定，新达到的结果加入待发布队列；已达到的不重复加入。
  void applyMastery(
    DateTime now, {
    List<MasteryRule> rules = englishMasteryRules,
  }) {
    final found = evaluateMastery(
      attempts: attempts,
      rules: rules,
      alreadyMastered: mastered.toSet(),
      now: now,
    );
    for (final m in found) {
      mastered.add(m.key);
      pendingAchievements.add(m);
    }
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
        result.add(
          Level(
            id: remediationId,
            stage: Stage.remediation,
            title: '补救关',
            questions: [
              for (final id in remediation)
                if (index[id] != null) index[id]!,
            ],
            passRate: 1.0,
          ),
        );
      }
      result.add(level);
      if (level.isBoss) {
        result.add(
          Level(
            id: reviewId,
            stage: Stage.review,
            title: '复习关',
            questions: _reviewQuestions(unit),
            passRate: 0.6,
          ),
        );
      }
    }
    return result;
  }

  /// 复习题：优先取错题；没有错题时，按间隔抽取单元词汇保持记忆。
  List<Question> _reviewQuestions(Unit unit) {
    final index = unit.questionIndex;
    final fromMissed = [
      for (final id in missed)
        if (index[id] != null) index[id]!,
    ];
    if (fromMissed.isNotEmpty) return fromMissed;
    final words = unit.levels
        .where((l) => l.stage == Stage.word)
        .expand((l) => l.questions)
        .toList();
    if (words.isEmpty) return const [];
    final step = words.length / 6;
    return [
      for (var k = 0; k < 6 && (k * step).floor() < words.length; k++)
        words[(k * step).floor()],
    ];
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
    'attempts': [for (final a in attempts) a.toJson()],
    'mastered': mastered,
    'pendingAchievements': [for (final m in pendingAchievements) m.toJson()],
  };

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    stars: (json['stars'] as Map?)?.map(
      (k, v) => MapEntry(k as String, v as int),
    ),
    remediation: (json['remediation'] as List?)?.cast<String>(),
    missed: (json['missed'] as List?)?.cast<String>(),
    attempts: [
      for (final a in (json['attempts'] as List?) ?? const [])
        QuestionAttempt.fromJson(a as Map<String, dynamic>),
    ],
    mastered: (json['mastered'] as List?)?.cast<String>(),
    pendingAchievements: [
      for (final m in (json['pendingAchievements'] as List?) ?? const [])
        MasteryAchievement.fromJson(m as Map<String, dynamic>),
    ],
  );
}
