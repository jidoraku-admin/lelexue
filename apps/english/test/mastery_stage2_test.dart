import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/level_run.dart';
import 'package:lelexue_english/domain/mastery.dart';
import 'package:lelexue_english/domain/mastery_rules.dart';
import 'package:lelexue_english/domain/progress.dart';
import 'package:lelexue_english/domain/unit.dart';

const _kp = 'english.g3.v1.u01.k001';
final _now = DateTime.utc(2026, 11, 22, 13);

QuestionAttempt _a(
  String kp,
  bool correct, {
  String itemType = 'use',
  String id = 'q',
}) => QuestionAttempt(
  questionId: id,
  knowledgePointId: kp,
  levelId: 'use-1',
  correct: correct,
  answeredAt: _now,
  itemType: itemType,
);

List<QuestionAttempt> _runs(String kp, List<bool> results) => [
  for (final r in results) _a(kp, r),
];

void main() {
  test('应用题 4/5 正确即达到 2★（80% 边界含等号）', () {
    final found = evaluateMastery(
      attempts: _runs(_kp, [true, true, false, true, true]),
      rules: englishMasteryRules,
      alreadyMastered: const {},
      now: _now,
    );
    expect(found.length, 1);
    expect(found.single.knowledgePointId, _kp);
    expect(found.single.level, 2);
    expect(found.single.achievedAt, _now);
  });

  test('正确率低于 80% 不达到', () {
    final found = evaluateMastery(
      attempts: _runs(_kp, [true, true, true, false, false]),
      rules: englishMasteryRules,
      alreadyMastered: const {},
      now: _now,
    );
    expect(found, isEmpty);
  });

  test('题数不足 5 题不达到，即使全对', () {
    final found = evaluateMastery(
      attempts: _runs(_kp, [true, true, true, true]),
      rules: englishMasteryRules,
      alreadyMastered: const {},
      now: _now,
    );
    expect(found, isEmpty);
  });

  test('只统计应用题；句型题与无题型的旧记录不计入', () {
    final attempts = [
      for (var i = 0; i < 5; i++) _a(_kp, true, itemType: 'sentence'),
      for (var i = 0; i < 5; i++)
        QuestionAttempt(
          questionId: 'old',
          knowledgePointId: _kp,
          levelId: 'use-1',
          correct: true,
          answeredAt: _now,
        ),
    ];
    final found = evaluateMastery(
      attempts: attempts,
      rules: englishMasteryRules,
      alreadyMastered: const {},
      now: _now,
    );
    expect(found, isEmpty);
  });

  test('已达到的规则不再产生结果', () {
    final found = evaluateMastery(
      attempts: _runs(_kp, [true, true, true, true, true]),
      rules: englishMasteryRules,
      alreadyMastered: {'$_kp#2'},
      now: _now,
    );
    expect(found, isEmpty);
  });

  test('Progress.applyMastery 只把首次达到的结果放入待发布队列', () {
    final progress = Progress();
    final answers = [
      for (var i = 0; i < 5; i++)
        FirstAnswer(
          question: Question(
            id: 'u$i',
            prompt: 'p',
            options: const ['a', 'b'],
            answer: 0,
            explanation: 'e',
            knowledgePointId: _kp,
          ),
          correct: true,
          stage: Stage.use,
        ),
    ];
    progress.recordAttempts('use-1', answers, _now);
    progress.applyMastery(_now);
    progress.applyMastery(_now.add(const Duration(minutes: 1)));
    expect(progress.pendingAchievements.length, 1);
    expect(progress.mastered, ['$_kp#2']);
  });

  test('MasteryAchievement 不含 userId 与 eventId', () {
    final json = MasteryAchievement(
      knowledgePointId: _kp,
      level: 2,
      achievedAt: _now,
    ).toJson();
    expect(json.containsKey('userId'), isFalse);
    expect(json.containsKey('eventId'), isFalse);
    expect(json['subject'], 'english');
  });

  test('进度 JSON 往返保留待发布队列与已达到记录', () {
    final progress = Progress(
      pendingAchievements: [
        MasteryAchievement(knowledgePointId: _kp, level: 2, achievedAt: _now),
      ],
      mastered: ['$_kp#2'],
    );
    final restored = Progress.fromJson(progress.toJson());
    expect(restored.pendingAchievements.single.key, '$_kp#2');
    expect(restored.mastered, ['$_kp#2']);

    final legacy = Progress.fromJson({'stars': {}, 'missed': <String>[]});
    expect(legacy.pendingAchievements, isEmpty);
    expect(legacy.mastered, isEmpty);
  });
}
