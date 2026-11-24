// 物理掌握度规则声明（学科自定）。
//
// 依据：#5 项目总监 2026-11-22 14:11 UTC 审核通过——1★ 发布；
// 发布由数据平台按各学科声明的规则执行，物理在本文件声明 1★。
// 经验只在首次达到 2★ 时发放（与英语一致），1★ 不发放经验。

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
}

/// 物理声明的规则。起始值沿用英语，学科自定，可修改（#16 v0.11）。
const List<MasteryRuleDecl> physicsMasteryRules = [
  MasteryRuleDecl(level: 1, minAccuracy: 0.8, minAttempts: 5, grantsExperience: false),
  MasteryRuleDecl(level: 2, minAccuracy: 0.8, minAttempts: 5, grantsExperience: true),
];
