import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/level_attempt.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';

void main() {
  final source = File('assets/data/unit1.json').readAsStringSync();

  test('Unit 1 covers all words in word levels', () {
    final unit = const UnitLoader().parse(source);
    final wordLevels = unit.levels.where((l) => l.stage == Stage.word);
    final covered = wordLevels.expand((l) => l.words).map((w) => w.en).toList();
    final boss = unit.levels.firstWhere((l) => l.stage == Stage.boss);
    expect(covered.length, boss.words.length);
    expect(covered.toSet().length, covered.length, reason: '认词关不应重复');
  });

  test('level order is word → sentence → use → boss', () {
    final unit = const UnitLoader().parse(source);
    final stages = unit.levels.map((l) => l.stage).toList();
    expect(stages.last, Stage.boss);
    expect(stages.indexOf(Stage.sentence) < stages.indexOf(Stage.use), isTrue);
    expect(stages.indexOf(Stage.word) < stages.indexOf(Stage.sentence), isTrue);
  });

  test('validation flag is carried through', () {
    final unit = const UnitLoader().parse(source);
    expect(unit.validation, isNotEmpty);
    expect(unit.isValidated, unit.validation == 'passed');
  });

  test('failure allows immediate retry without penalty', () {
    final attempt = LevelAttempt(isBoss: false)..recordFailure();
    expect(attempt.canRetry, isTrue);
    expect(attempt.failures, 1);
    attempt.recordPass();
    expect(attempt.canRetry, isFalse);
  });

  test('boss failure requires remediation before retry', () {
    final attempt = LevelAttempt(isBoss: true)..recordFailure();
    expect(attempt.needsRemediation, isTrue);
    expect(attempt.canRetry, isFalse);
    attempt.completeRemediation();
    expect(attempt.canRetry, isTrue);
  });
}
