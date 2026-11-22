import 'unit.dart';

/// 英语掌握规则（学科自定，#7 阶段二）。
///
/// 共通只定义规则格式（gamification §9），数值由英语决定：
/// 2★ 以应用题为准，正确率不低于 80%，且统计题数不少于 5。
/// 统计范围为该知识点的全部应用题作答（window = all）。
/// 1★ 与 3★ 暂不发布（#7 裁定：共通没有对应标准，英语另行提出后再定）。
class MasteryRule {
  const MasteryRule({
    required this.level,
    required this.itemType,
    required this.threshold,
    required this.minCount,
  });

  /// 掌握层级（2 表示 2★）。
  final int level;

  /// 参与统计的题型（英语的应用题为 Stage.use）。
  final Stage itemType;

  /// 正确率门槛，0–1。
  final double threshold;

  /// 最少作答题数。
  final int minCount;
}

const englishMasteryRules = <MasteryRule>[
  MasteryRule(level: 2, itemType: Stage.use, threshold: 0.8, minCount: 5),
];
