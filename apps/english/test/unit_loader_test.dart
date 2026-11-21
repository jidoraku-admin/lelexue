import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/level_run.dart';
import 'package:lelexue_english/domain/progress.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';

void main() {
  final source = File('assets/data/unit1.json').readAsStringSync();
  final unit = const UnitLoader().parse(source);

  test('认词关覆盖全部词汇且不重复', () {
    final words = unit.levels
        .where((l) => l.stage == Stage.word)
        .expand((l) => l.questions)
        .map((q) => q.prompt)
        .toList();
    expect(words.length, unit.words.length);
    expect(words.toSet().length, words.length);
  });

  test('关卡顺序：认词 → 句型 → 运用 → Boss', () {
    final stages = unit.levels.map((l) => l.stage).toList();
    expect(stages.last, Stage.boss);
    expect(stages.indexOf(Stage.word) < stages.indexOf(Stage.sentence), isTrue);
    expect(stages.indexOf(Stage.sentence) < stages.indexOf(Stage.use), isTrue);
  });

  test('每题选项数正确且答案下标有效', () {
    for (final level in unit.levels) {
      for (final q in level.questions) {
        expect(q.options.length, 4, reason: q.id);
        expect(q.answer, inInclusiveRange(0, 3), reason: q.id);
        expect(q.options.toSet().length, q.options.length, reason: '选项不应重复：${q.id}');
      }
    }
  });

  test('Boss 题目均来自其他关卡', () {
    final index = unit.questionIndex;
    final boss = unit.levels.firstWhere((l) => l.isBoss);
    for (final q in boss.questions) {
      expect(index[q.id], same(q));
    }
  });

  test('答错可立即再答，首次正确才计分', () {
    final level = unit.levels.firstWhere((l) => l.stage == Stage.sentence);
    final run = LevelRun(level);
    final wrong = (run.current.answer + 1) % 4;
    expect(run.answer(wrong), isFalse);
    expect(run.feedback, run.current.explanation);
    expect(run.answer(run.current.answer), isTrue);
    expect(run.firstTryCorrect, 0, reason: '先错后对不计首次正确');
    run.next();
    expect(run.index, 1);
  });

  test('未作答正确不能进入下一题', () {
    final run = LevelRun(unit.levels.first);
    run.next();
    expect(run.index, 0);
  });

  test('通过与星级', () {
    final level = unit.levels.firstWhere((l) => l.isBoss);
    final run = LevelRun(level);
    for (var i = 0; i < level.questions.length; i++) {
      run.answer(run.current.answer);
      run.next();
    }
    expect(run.finished, isTrue);
    expect(run.stars, 3);
    expect(run.passed, isTrue);
  });

  test('Boss 失败后生成补救关，补救通过后清除', () {
    final progress = Progress();
    final boss = unit.levels.firstWhere((l) => l.isBoss);
    final path0 = progress.path(unit);
    expect(path0.any((l) => l.id == Progress.remediationId), isFalse);

    progress.remediation.addAll([boss.questions[0].id, boss.questions[1].id]);
    final path = progress.path(unit);
    final bossIndex = path.indexWhere((l) => l.isBoss);
    expect(path[bossIndex - 1].id, Progress.remediationId);
    expect(progress.isUnlocked(path, bossIndex), isFalse, reason: 'Boss 在补救前不可挑战');

    progress.record(Progress.remediationId, 1);
    progress.remediation.clear();
    expect(progress.path(unit).any((l) => l.id == Progress.remediationId), isFalse);
  });

  test('进度 JSON 往返一致', () {
    final progress = Progress()..record('word-1', 2)..remediation.add('w-hello');
    final restored = Progress.fromJson(progress.toJson());
    expect(restored.stars, {'word-1': 2});
    expect(restored.remediation, ['w-hello']);
  });

  test('关卡需前一关通过才能解锁', () {
    final progress = Progress();
    final path = progress.path(unit);
    expect(progress.isUnlocked(path, 0), isTrue);
    expect(progress.isUnlocked(path, 1), isFalse);
    progress.record(path[0].id, 1);
    expect(progress.isUnlocked(path, 1), isTrue);
  });
}
