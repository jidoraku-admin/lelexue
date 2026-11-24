// 第 1 单元「观察物体」的判题（学科适配层，#3）。
// 不依赖共通 game kit（0010 第 6 条：框架验证前其他学科不采用），不计分。

/// 一道题（与 docs/data/math-g3-unit01-items.json 的字段对应）。
class Unit01Item {
  const Unit01Item({
    required this.id,
    required this.game,
    required this.prompt,
    required this.answer,
    required this.distractors,
  });

  final String id;
  final String game;
  final String prompt;
  final String answer;
  final List<String> distractors;

  /// 选项 = 答案 + 干扰项。
  List<String> get options => [answer, ...distractors];
}

/// 判断作答是否正确：所选必须是该题选项之一，且与答案一致。
bool judgeChoice(Unit01Item item, String choice) {
  if (!item.options.contains(choice)) return false;
  return choice == item.answer;
}

/// knowledgePointId 格式校验（共通 README §1.5）：`math.gN.vV.uUU.kSSS`。
final RegExp knowledgePointPattern =
    RegExp(r'^math\.g\d{1,2}\.v[12]\.u\d{2}\.k\d{3}$');

bool isValidKnowledgePointId(String id) => knowledgePointPattern.hasMatch(id);
