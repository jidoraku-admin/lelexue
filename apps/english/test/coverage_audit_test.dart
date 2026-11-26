import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/coverage_audit.dart';

/// v0.16 §6.3 覆盖率审计：Unit 1–3 的每个词汇、句型都要映射到至少一个关卡。
void main() {
  const audit = CoverageAudit();
  final index = jsonDecode(
    File('assets/data/index.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final files = [
    for (final u in index['units'] as List) (u as Map)['file'] as String,
  ];

  test('索引包含 Unit 1–3', () {
    expect(files, containsAll(['unit1.json', 'unit2.json', 'unit3.json']));
  });

  for (final file in files) {
    test('$file 词汇与句型全部映射到关卡', () {
      final source = File('assets/data/$file').readAsStringSync();
      final json = jsonDecode(source) as Map<String, dynamic>;
      expect(json['words'] as List, isNotEmpty, reason: '$file 缺少词汇');
      expect(json['sentences'] as List, isNotEmpty, reason: '$file 缺少句型');

      final report = audit.run(source);
      // 打印审计结果，未覆盖项会列在失败原因里。
      // ignore: avoid_print
      print(report);
      expect(report.uncoveredWords, isEmpty, reason: report.toString());
      expect(report.uncoveredSentences, isEmpty, reason: report.toString());
    });
  }

  test('删掉句型题后，审计列出未覆盖的句型', () {
    final json = jsonDecode(
      File('assets/data/unit2.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    json['sentenceQuestions'] = (json['sentenceQuestions'] as List)
        .where((q) => (q as Map)['id'] != 's2-have')
        .toList();
    final report = audit.run(jsonEncode(json));
    expect(report.isComplete, isFalse);
    expect(report.uncoveredSentences, ['I have a ___.']);
    expect(report.uncoveredWords, isEmpty);
  });

  test('新增没有题目的句型或词汇，审计列出该项', () {
    final json = jsonDecode(
      File('assets/data/unit1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (json['sentences'] as List).add('How are you?');
    final report = audit.run(jsonEncode(json));
    expect(report.uncoveredSentences, ['How are you?']);
  });

  test('填空 ___ 可匹配任意内容，忽略大小写与标点', () {
    final json = jsonDecode(
      File('assets/data/unit1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    json['sentences'] = ["I'M ___!"];
    expect(audit.run(jsonEncode(json)).isComplete, isTrue);
  });
}
