import 'dart:convert';

import 'unit.dart';
import 'unit_loader.dart';

/// 覆盖率审计（v0.16 §6.3）：单元的每个词汇、每个句型都要映射到至少一个关卡，
/// 没有映射的项目视为缺陷。
///
/// 映射规则：
/// - 词汇：某个关卡里有以该词出题的认词题（题目 id 为 `w-<词>` 或 `wz-<词>`）。
/// - 句型：句型按「 / 」拆成若干写法，`___` 表示任意填空内容；某个关卡里有题目的
///   题面或正确选项包含其中一种写法即算映射（忽略大小写与标点）。
class CoverageReport {
  const CoverageReport({
    required this.unit,
    required this.uncoveredWords,
    required this.uncoveredSentences,
  });

  final String unit;
  final List<String> uncoveredWords;
  final List<String> uncoveredSentences;

  bool get isComplete => uncoveredWords.isEmpty && uncoveredSentences.isEmpty;

  @override
  String toString() => isComplete
      ? '$unit：词汇与句型全部覆盖'
      : '$unit 未覆盖：词汇 $uncoveredWords；句型 $uncoveredSentences';
}

class CoverageAudit {
  const CoverageAudit({this.loader = const UnitLoader()});

  final UnitLoader loader;

  /// 审计一个单元数据文件（assets/data/unitN.json 的内容）。
  CoverageReport run(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final sentences = (json['sentences'] as List? ?? const []).cast<String>();
    return audit(loader.parse(source), sentences);
  }

  CoverageReport audit(Unit unit, List<String> sentences) {
    final questions = [for (final l in unit.levels) ...l.questions];
    final ids = {for (final q in questions) q.id};
    final texts = [
      for (final q in questions) ...[
        _normalize(q.prompt),
        _normalize(q.options[q.answer]),
      ],
    ];

    final uncoveredWords = [
      for (final w in unit.words)
        if (!ids.contains('w-${w.en}') && !ids.contains('wz-${w.en}')) w.en,
    ];
    final uncoveredSentences = [
      for (final s in sentences)
        if (!_variants(s).any((re) => texts.any(re.hasMatch))) s,
    ];
    return CoverageReport(
      unit: unit.code,
      uncoveredWords: uncoveredWords,
      uncoveredSentences: uncoveredSentences,
    );
  }

  static List<RegExp> _variants(String pattern) => [
    for (final v in pattern.split('/'))
      if (_normalize(v).isNotEmpty)
        RegExp(
          '\\b${_normalize(v).split('___').map((p) => RegExp.escape(p.trim())).join(r'\s*.+?\s*')}\\b',
        ),
  ];

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'[.,!?;:]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
