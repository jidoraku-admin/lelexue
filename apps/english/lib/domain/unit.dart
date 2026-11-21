/// 英语单元的领域模型（v0.16 §2.2 单元结构）。
library;

enum Stage { word, sentence, use, boss, review }

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

class Level {
  const Level({
    required this.id,
    required this.stage,
    required this.title,
    this.words = const [],
    this.sentences = const [],
  });

  final String id;
  final Stage stage;
  final String title;
  final List<Word> words;
  final List<String> sentences;
}

class Unit {
  const Unit({
    required this.code,
    required this.title,
    required this.levels,
    required this.validation,
  });

  final String code;
  final String title;
  final List<Level> levels;

  /// 数据校验结果，来自导出脚本。未通过时界面需标注待核对。
  final String validation;

  bool get isValidated => validation == 'passed';
}
