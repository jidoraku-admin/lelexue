// 数学掌握度规则声明（学科自定，#3 F5）。
//
// 依据：#3 项目总监 2026-11-26 批次审核——1★ 门槛与英语、物理一致：
// 正确率 ≥80% 且不少于 5 次作答。发布由数据平台按本声明执行（#92），
// 数学只生成草稿，不生成 eventId，也不直接发布 MasteryChanged。
// 经验发放（grantsExperience）属于 F7，F7 定稿前一律为 false。

class MasteryRuleDecl {
  const MasteryRuleDecl({
    required this.level,
    required this.minAccuracy,
    required this.minAttempts,
    required this.grantsExperience,
  });

  final int level;
  final double minAccuracy;
  final int minAttempts;
  final bool grantsExperience;

  bool isMetBy({required int attempts, required int correct}) =>
      attempts >= minAttempts &&
      attempts > 0 &&
      correct / attempts >= minAccuracy;
}

/// 数学 1★ 规则。
const MasteryRuleDecl mathLevel1Rule = MasteryRuleDecl(
  level: 1,
  minAccuracy: 0.8,
  minAttempts: 5,
  grantsExperience: false,
);

/// 数学声明的全部规则（目前只有 1★）。
const List<MasteryRuleDecl> mathMasteryRules = [mathLevel1Rule];
