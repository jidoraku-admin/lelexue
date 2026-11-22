import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_math/unit01/items_loader.dart';

// 测试直接读取仓库中的真实数据文件（测试运行目录为 apps/math）。
const _dataPath = '../../docs/data/math-g3-unit01-items.json';

void main() {
  test('读取仓库中的第 1 单元数据文件', () {
    final items = parseUnit01Items(File(_dataPath).readAsStringSync());
    expect(items.map((i) => i.id), [
      'math.g3.v1.u01.k001',
      'math.g3.v1.u01.k002',
      'math.g3.v1.u01.k003',
    ]);
    expect(items[1].options, ['2', '1', '3']);
  });

  test('缺少 items 或为空时报错', () {
    expect(() => parseUnit01Items('{}'), throwsFormatException);
    expect(() => parseUnit01Items('{"items": []}'), throwsFormatException);
  });

  test('knowledgePointId 不合法时报错', () {
    expect(
      () => parseUnit01Items(_one({'id': 'math.g3.v1.u1.k1'})),
      throwsFormatException,
    );
  });

  test('重复 id 时报错', () {
    final source = jsonEncode({
      'items': [_item(), _item()],
    });
    expect(() => parseUnit01Items(source), throwsFormatException);
  });

  test('未知玩法时报错', () {
    expect(
      () => parseUnit01Items(_one({'game': 'unknown'})),
      throwsFormatException,
    );
  });

  test('干扰项重复或包含答案时报错', () {
    expect(
      () => parseUnit01Items(_one({'distractors': ['1', '1']})),
      throwsFormatException,
    );
    expect(
      () => parseUnit01Items(_one({'distractors': ['2', '3']})),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _item([Map<String, dynamic> overrides = const {}]) => {
      'id': 'math.g3.v1.u01.k001',
      'game': 'observe_choice',
      'prompt': '从左边看，看到几个方块？',
      'answer': '2',
      'distractors': ['1', '3'],
      ...overrides,
    };

String _one(Map<String, dynamic> overrides) =>
    jsonEncode({'items': [_item(overrides)]});
