import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/level_run.dart';
import 'package:lelexue_english/domain/progress.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';

final _kpPattern = RegExp(r'^english\.g3\.v1\.u01\.k00[1-6]$');

Question _q(String id, {String? kp, int answer = 0}) => Question(
  id: id,
  prompt: 'p',
  options: const ['a', 'b'],
  answer: answer,
  explanation: 'e',
  knowledgePointId: kp,
);

Level _level(String id, List<Question> qs) => Level(
  id: id,
  stage: Stage.sentence,
  title: id,
  questions: qs,
  passRate: 0.6,
);

void main() {
  final unit = const UnitLoader().parse(
    File('assets/data/unit1.json').readAsStringSync(),
  );

  test('第 1 单元句型题与运用题都标注了合法的知识点编码', () {
    final tagged = [
      ...unit.levels.where((l) => l.stage == Stage.sentence),
      ...unit.levels.where((l) => l.stage == Stage.use),
    ].expand((l) => l.questions);
    expect(tagged, isNotEmpty);
    for (final q in tagged) {
      expect(q.knowledgePointId, isNotNull, reason: q.id);
      expect(_kpPattern.hasMatch(q.knowledgePointId!), isTrue, reason: q.id);
    }
    final covered = tagged.map((q) => q.knowledgePointId).toSet();
    expect(covered.length, 6, reason: '六个知识点都应有题目');
  });

  test('认词题未标注知识点', () {
    final words = unit.levels
        .where((l) => l.stage == Stage.word)
        .expand((l) => l.questions);
    expect(words.every((q) => q.knowledgePointId == null), isTrue);
  });

  test('LevelRun 只记录每题的首次作答', () {
    final q1 = _q('q1', kp: 'english.g3.v1.u01.k001', answer: 0);
    final q2 = _q('q2', kp: 'english.g3.v1.u01.k002', answer: 0);
    final run = LevelRun(_level('L', [q1, q2]));

    run.answer(1); // q1 首次错误
    run.answer(0); // q1 改对，不再记录
    run.next();
    run.answer(0); // q2 首次正确
    run.next();

    expect(run.firstAnswers.length, 2);
    expect(run.firstAnswers[0].question.id, 'q1');
    expect(run.firstAnswers[0].correct, isFalse);
    expect(run.firstAnswers[1].question.id, 'q2');
    expect(run.firstAnswers[1].correct, isTrue);
  });

  test('recordAttempts 跳过未标注知识点的题目', () {
    final run = LevelRun(
      _level('L', [_q('tagged', kp: 'english.g3.v1.u01.k003'), _q('plain')]),
    );
    run.answer(0);
    run.next();
    run.answer(0);
    run.next();

    final progress = Progress();
    progress.recordAttempts('L', run.firstAnswers, DateTime.utc(2026, 11, 22));
    expect(progress.attempts.length, 1);
    expect(progress.attempts.single.questionId, 'tagged');
    expect(progress.attempts.single.knowledgePointId, 'english.g3.v1.u01.k003');
    expect(progress.attempts.single.correct, isTrue);
  });

  test('进度 JSON 往返保留逐题记录，旧数据读取为空列表', () {
    final progress = Progress();
    progress.recordAttempts('sentence-1', [
      FirstAnswer(
        question: _q('x', kp: 'english.g3.v1.u01.k004'),
        correct: false,
      ),
    ], DateTime.utc(2026, 11, 22, 12));
    final restored = Progress.fromJson(progress.toJson());
    expect(restored.attempts.length, 1);
    expect(restored.attempts.single.correct, isFalse);
    expect(restored.attempts.single.answeredAt, DateTime.utc(2026, 11, 22, 12));

    final legacy = Progress.fromJson({
      'stars': {'sentence-1': 2},
      'remediation': <String>[],
      'missed': <String>[],
    });
    expect(legacy.attempts, isEmpty);
    expect(legacy.isPassed('sentence-1'), isTrue);
  });
}
