import 'dart:convert';

import 'unit.dart';

/// 把单元数据文件（assets/data/unitN.json）组装为单元。所有单元共用这一份代码。
///
/// 认词关每 [wordsPerLevel] 个词一关，干扰项取自同单元其他词，且不与正确释义重复；
/// 句型关与运用关使用 [unit1SentenceQuestions]、[unit1UseQuestions]；
/// Boss 从全部题目中等距抽取 [bossSize] 题。
class UnitLoader {
  const UnitLoader({this.wordsPerLevel = 8, this.bossSize = 12});

  final int wordsPerLevel;
  final int bossSize;

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

  /// 第 [index] 个词的选择题：给英文，选中文释义。
  Question _wordQuestion(List<Word> words, int index) {
    final target = words[index];
    final distractors = <String>[];
    for (var step = 1; distractors.length < 3 && step < words.length; step++) {
      final zh = words[(index + step) % words.length].zh;
      if (zh != target.zh && !distractors.contains(zh)) distractors.add(zh);
    }
    final options = [...distractors];
    final answerIndex = index % 4;
    options.insert(answerIndex, target.zh);
    return Question(
      id: 'w-${target.en}',
      prompt: target.en,
      options: options,
      answer: answerIndex,
      explanation: '${target.en} 的意思是「${target.zh}」（课本第 ${target.page} 页）。',
    );
  }
}
