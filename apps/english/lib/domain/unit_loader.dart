import 'dart:convert';

import 'unit.dart';

/// 把 assets/data/unit1.json 解析为单元地图（v0.16 §2.2）。
///
/// 认词关按每 [wordsPerLevel] 个词分段，覆盖本单元全部词汇；
/// 句型关与运用关使用同一组句型；Boss 综合全部内容。
class UnitLoader {
  const UnitLoader({this.wordsPerLevel = 8});

  final int wordsPerLevel;

  Unit parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final words = (json['words'] as List)
        .map((e) => Word.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final sentences = (json['sentences'] as List).cast<String>();

    final levels = <Level>[];
    for (var i = 0; i < words.length; i += wordsPerLevel) {
      final end = (i + wordsPerLevel < words.length) ? i + wordsPerLevel : words.length;
      levels.add(Level(
        id: 'word-${levels.length + 1}',
        stage: Stage.word,
        title: '认词关 ${levels.length + 1}',
        words: words.sublist(i, end),
      ));
    }
    levels.add(Level(id: 'sentence-1', stage: Stage.sentence, title: '句型关', sentences: sentences));
    levels.add(Level(id: 'use-1', stage: Stage.use, title: '运用关', sentences: sentences));
    levels.add(Level(id: 'boss-1', stage: Stage.boss, title: '单元 Boss', words: words, sentences: sentences));

    return Unit(
      code: json['unit'] as String,
      title: json['title'] as String,
      levels: levels,
      validation: json['validation'] as String,
    );
  }
}
