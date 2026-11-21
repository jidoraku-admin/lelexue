import 'dart:convert';

import 'unit.dart';

/// 把单元数据文件（assets/data/unitN.json）组装为单元。所有单元共用这一份代码。
///
/// 认词关每 [wordsPerLevel] 个词一关，干扰项取自同单元其他词，且不与正确释义重复；
/// 句型关与运用关使用 [unit1SentenceQuestions]、[unit1UseQuestions]；
/// Boss 从全部题目中等距抽取 [bossSize] 题。
class UnitLoader {
  const UnitLoader({this.wordsPerLevel = 8, this.bossSize = 12, this.reviewSize = 8});

  final int wordsPerLevel;
  final int bossSize;
  final int reviewSize;

  Unit parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final words = (json['words'] as List)
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final sentenceQuestions = (json['sentenceQuestions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final useQuestions = (json['useQuestions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final levels = <Level>[];
    final wordQuestions = <Question>[];
    for (var i = 0; i < words.length; i += wordsPerLevel) {
      final end = (i + wordsPerLevel < words.length) ? i + wordsPerLevel : words.length;
      final qs = [
        for (var j = i; j < end; j++) _wordQuestion(words, j),
      ];
      wordQuestions.addAll(qs);
      levels.add(Level(
        id: 'word-${levels.length + 1}',
        stage: Stage.word,
        title: '认词关 ${levels.length + 1}',
        questions: qs,
        passRate: 0.6,
      ));
    }

    levels.add(Level(
      id: 'sentence-1',
      stage: Stage.sentence,
      title: '句型关',
      questions: sentenceQuestions,
      passRate: 0.6,
    ));
    levels.add(Level(
      id: 'use-1',
      stage: Stage.use,
      title: '运用关',
      questions: useQuestions,
      passRate: 0.6,
    ));

    final all = [...wordQuestions, ...sentenceQuestions, ...useQuestions];
    final step = all.length / bossSize;
    final boss = [
      for (var k = 0; k < bossSize; k++) all[(k * step).floor()],
    ];
    levels.add(Level(
      id: 'boss-1',
      stage: Stage.boss,
      title: '单元 Boss',
      questions: boss,
      passRate: 0.8,
    ));

    return Unit(
      code: json['unit'] as String,
      title: json['title'] as String,
      scenario: json['scenario'] as String,
      characters: [
        for (final c in (json['characters'] as List? ?? const []))
          Character.fromJson(c as Map<String, dynamic>),
      ],
      words: words,
      levels: levels,
      validation: json['validation'] as String,
    );
  }

  /// 第 [index] 个词的选择题。偶数题英文→中文，奇数题中文→英文，兼顾认读与记忆。
  /// 干扰项不得与正确答案的释义共享任何词段（如「你好」），否则孩子无法区分。
  Question _wordQuestion(List<Word> words, int index) {
    final target = words[index];
    final forward = index.isEven;
    String value(Word w) => forward ? w.zh : w.en;
    final targetTokens = _tokens(target.zh);
    final candidates = <Word>[
      for (var step = 1; step < words.length; step++) words[(index + step) % words.length],
    ];
    List<String> pick({required bool strict}) {
      final out = <String>[];
      for (final c in candidates) {
        if (out.length == 3) break;
        if (value(c) == value(target) || out.contains(value(c))) continue;
        if (strict && _tokens(c.zh).intersection(targetTokens).isNotEmpty) continue;
        out.add(value(c));
      }
      return out;
    }
    var distractors = pick(strict: true);
    if (distractors.length < 3) distractors = pick(strict: false);
    final answerIndex = index % 4;
    final options = [...distractors]..insert(answerIndex, value(target));
    return Question(
      id: '${forward ? 'w' : 'wz'}-${target.en}',
      prompt: forward ? target.en : target.zh,
      options: options,
      answer: answerIndex,
      explanation: '${target.en} 的意思是「${target.zh}」（课本第 ${target.page} 页）。',
    );
  }

  /// 释义按分隔符切成词段，用于判断两个释义是否含义重叠。
  static Set<String> _tokens(String zh) => zh
      .split(RegExp(r'[；;，,（）()\s]+'))
      .where((t) => t.isNotEmpty)
      .toSet();
}
