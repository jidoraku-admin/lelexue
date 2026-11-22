import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/progress.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';
import 'package:lelexue_english/domain/unit_summary.dart';

void main() {
  final Unit unit = const UnitLoader().parse(
    File('assets/data/unit1.json').readAsStringSync(),
  );

  test('新单元：没有星星，没有学会的词，未通关', () {
    final s = UnitSummary.of(unit, Progress());
    expect(s.starsEarned, 0);
    expect(s.wordsLearned, 0);
    expect(s.complete, isFalse);
    expect(s.wordsTotal, unit.words.length);
    expect(s.starsTotal, unit.levels.length * 3);
  });

  test('认词关通过后，学会的词数等于已通过认词关的题数', () {
    final firstWord = unit.levels.firstWhere((l) => l.stage == Stage.word);
    final p = Progress()..record(firstWord.id, 2);
    final s = UnitSummary.of(unit, p);
    expect(s.wordsLearned, firstWord.questions.length);
    expect(s.starsEarned, 2);
    expect(s.complete, isFalse);
  });

  test('Boss 通过即为单元通关', () {
    final boss = unit.levels.firstWhere((l) => l.isBoss);
    final p = Progress()..record(boss.id, 3);
    expect(UnitSummary.of(unit, p).complete, isTrue);
  });

  test('错题本剩余数量如实反映', () {
    final p = Progress()..addMissed(['a-1', 'a-2']);
    expect(UnitSummary.of(unit, p).missedLeft, 2);
  });
}
