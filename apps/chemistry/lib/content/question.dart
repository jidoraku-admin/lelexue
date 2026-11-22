/// 化学学科内题目模型（#20 实现方案第 2 节 content/）。
///
/// 题目由化学学科自行定义，不进入共享框架。原创题干，不复制教材文字。
class Question {
  const Question({
    required this.id,
    required this.knowledgePointId,
    required this.level,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;

  /// 知识点 id，格式见 ChemistryScoring。
  final String knowledgePointId;

  /// 掌握等级（1 = 1★ 识别）。
  final int level;

  final String prompt;
  final List<String> options;
  final int answerIndex;

  /// 作答后显示的原理解释（设计：每次错误给出一条原理解释，不扣分）。
  final String explanation;

  bool isCorrect(int selected) => selected == answerIndex;
}
