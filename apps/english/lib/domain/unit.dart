/// 英语单元的领域模型（v0.16 §2.2 单元结构）。
library;

enum Stage { word, sentence, use, boss, remediation, review }

class Word {
  const Word({required this.en, required this.zh, required this.page});

  final String en;
  final String zh;
  final int page;

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    en: json['en'] as String,
    zh: json['zh'] as String,
    page: json['page'] as int,
  );
}

/// 一道题。answer 为正确选项的下标。
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.knowledgePointId,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;

  /// 所属知识点编码（格式 english.g<年级>.v<册>.u<单元>.k<序号>）。
  /// 未标注的题目（如认词题）为 null，不参与掌握记录。
  final String? knowledgePointId;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    prompt: json['prompt'] as String,
    options: (json['options'] as List).cast<String>(),
    answer: json['answer'] as int,
    explanation: json['explanation'] as String,
    knowledgePointId: json['knowledgePointId'] as String?,
  );
}

class Level {
  const Level({
    required this.id,
    required this.stage,
    required this.title,
    required this.questions,
    required this.passRate,
  });

  final String id;
  final Stage stage;
  final String title;
  final List<Question> questions;

  /// 首次作答正确率达到该值即通过（数值为占位，后台可配，属小事）。
  final double passRate;

  bool get isBoss => stage == Stage.boss;
}

/// 单元中的角色（由数据决定，界面不写死）。
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.kind,
    required this.asset,
    required this.line,
  });

  final String id;
  final String name;
  final String kind;

  /// 角色图片资源路径（SVG）。
  final String asset;

  /// 角色的台词，用于地图与提示。
  final String line;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: json['kind'] as String,
    asset: json['asset'] as String,
    line: json['line'] as String,
  );
}

class Unit {
  const Unit({
    required this.code,
    required this.title,
    required this.scenario,
    required this.characters,
    required this.words,
    required this.levels,
    required this.validation,
  });

  final String code;
  final String title;
  final String scenario;
  final List<Character> characters;
  final List<Word> words;

  /// 不含补救关的基础关卡（认词、句型、运用、Boss）。
  final List<Level> levels;

  /// 数据校验结果，来自导出脚本。未通过时界面需标注待核对。
  final String validation;

  bool get isValidated => validation == 'passed';

  Map<String, Question> get questionIndex => {
    for (final l in levels)
      for (final q in l.questions) q.id: q,
  };
}
