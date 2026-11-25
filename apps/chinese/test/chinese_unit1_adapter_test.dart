import 'dart:convert';
import 'dart:io';

import 'package:lelexue_chinese/domain/chinese_unit1_adapter.dart';
import 'package:shared/game_kit/game_kit.dart';
import 'package:test/test.dart';

ChineseUnit1Data loadData() {
  // 测试从仓库根目录的 docs/data 读取同一份数据，保证适配层与数据文件一致。
  final file = File('../../docs/data/chinese-unit1.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ChineseUnit1Data.fromJson(json);
}

void main() {
  group('数据', () {
    test('可以从 docs/data/chinese-unit1.json 解析', () {
      final data = loadData();
      expect(data.matchPairs, isNotEmpty);
      expect(data.cardHand, isNotEmpty);
      expect(data.fallingTargets, isNotEmpty);
      expect(data.fallingDistractors, isNotEmpty);
    });

    test('每个字都标有课次，且出现在真人确认的该课生字表中', () {
      final unit = jsonDecode(
        File('../../docs/data/chinese-g3a-unit1-chars.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final confirmed = <int, Set<String>>{
        for (final l in (unit['lessons'] as List).cast<Map<String, dynamic>>())
          l['lesson'] as int: {
            ...(l['chars'] as List).cast<String>(),
            ...((l['gridChars'] as List?) ?? const []).cast<String>(),
          },
      };
      final raw = jsonDecode(
        File('../../docs/data/chinese-unit1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final items = <Map<String, dynamic>>[
        ...(raw['stepA_match']['pairs'] as List).cast<Map<String, dynamic>>(),
        raw['stepB_cardplay']['start'] as Map<String, dynamic>,
        ...(raw['stepB_cardplay']['hand'] as List).cast<Map<String, dynamic>>(),
        ...(raw['stepC_falling']['targets'] as List)
            .cast<Map<String, dynamic>>(),
        ...(raw['stepC_falling']['distractors'] as List)
            .cast<Map<String, dynamic>>(),
      ];
      for (final m in items) {
        final lesson = m['lesson'];
        expect(lesson, isA<int>(), reason: '${m['id']} 缺少课次');
        expect(confirmed[lesson], contains(m['char']),
            reason: '${m['char']} 不在第 $lesson 课生字表中');
      }
      // 首切片覆盖第 1 单元全部三课。
      expect(items.map((m) => m['lesson']).toSet(), {1, 2, 3});
    });

    test('缺少步骤时解析失败（不静默通过）', () {
      expect(
        () => ChineseUnit1Data.fromJson({
          'stepA_match': {'pairs': []}
        }),
        throwsA(anything),
      );
    });
  });

  group('配对（框架：配对）', () {
    test('每对两段文本共用同一个 id', () {
      final cfg = buildMatchConfig(loadData(), (_) {});
      expect(cfg.kind, GameMechanicKind.match);
      for (final (a, b) in cfg.pairs) {
        expect(a.id, b.id);
        expect(a.prompt, isNot(b.prompt));
      }
    });
  });

  group('出牌（框架：出牌）', () {
    test('起始牌与手牌的偏旁属性有值，且手牌不含起始牌', () {
      final data = loadData();
      final cfg = buildCardPlayConfig(data, (_) {});
      expect(cfg.kind, GameMechanicKind.cardPlay);
      expect(cfg.startCard.attribute, isNotEmpty);
      expect(
          cfg.hand.where((c) => c.item.id == cfg.startCard.item.id), isEmpty);
    });
  });

  group('下落选择（框架：下落选择）', () {
    test('目标都带有题干偏旁，干扰项都不带', () {
      final data = loadData();
      final cfg = buildFallingConfig(data, (_) {});
      expect(cfg.kind, GameMechanicKind.fallingChoice);
      final radical = data.fallingTargets.first.radical;
      for (final t in data.fallingTargets) {
        expect(t.radical, radical);
      }
      for (final d in data.fallingDistractors) {
        expect(d.radical, isNot(radical));
      }
    });
  });
}
