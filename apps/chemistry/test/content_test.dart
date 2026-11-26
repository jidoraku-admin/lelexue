import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/content/chemistry_content.dart';

final _kpPattern = RegExp(r'^chemistry\.g\d+\.v\d+\.u\d+\.k\d{3}$');

void main() {
  for (final entry in {'E1': e1Questions, 'E2': e2Questions, 'E3': e3Questions}.entries) {
    test('${entry.key} 题目结构合法', () {
      expect(entry.value, isNotEmpty);
      for (final q in entry.value) {
        expect(_kpPattern.hasMatch(q.knowledgePointId), isTrue, reason: q.id);
        expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
        expect(q.answerIndex, inInclusiveRange(0, q.options.length - 1), reason: q.id);
        expect(q.options.toSet().length, q.options.length, reason: '选项不得重复 ${q.id}');
        expect(q.explanation.trim(), isNotEmpty, reason: q.id);
        expect(q.level, 1, reason: '本切片只含 1★ 识别 ${q.id}');
      }
    });
  }

  test('题目 id 全局唯一', () {
    final ids = [...e1Questions, ...e2Questions, ...e3Questions].map((q) => q.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
