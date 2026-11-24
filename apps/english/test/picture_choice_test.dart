import 'dart:io';

import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';
import 'package:lelexue_english/ui/word_icon.dart';

void main() {
  final source = File('assets/data/unit1.json').readAsStringSync();
  final unit = const UnitLoader().parse(source);
  final wordQs = unit.levels
      .where((l) => l.stage == Stage.word)
      .expand((l) => l.questions)
      .toList();

  test('只有中→英的单词题带图片（看图选词），英→中题不带', () {
    for (final q in wordQs) {
      final reverse = q.id.startsWith('wz-');
      if (reverse) {
        expect(q.picture, isNotNull, reason: q.id);
        // 看图选词的选项是英文词，答案即图片对应的词。
        expect(q.options[q.answer], q.picture, reason: q.id);
      } else {
        expect(q.picture, isNull, reason: q.id);
      }
    }
  });

  test('占位图标不算专门图标；已有专门图标的词才看图选词', () {
    expect(hasDedicatedIcon('cat'), isTrue);
    expect(hasDedicatedIcon('CAT'), isTrue);
    expect(hasDedicatedIcon('zzz-unknown'), isFalse);
    expect(wordIcon('cat'), Icons.pets);
  });
}
