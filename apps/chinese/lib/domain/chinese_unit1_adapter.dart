// 语文第 1 单元首切片：学科适配层。
//
// 把 docs/data/chinese-unit1.json 的内容映射为共通玩法框架（game kit）的配置。
// 框架不认识学科：这里只负责题目来源、字与题的映射、以及学科规则。
// 计分与记录由调用方通过 onAnswer 回调处理。

import 'package:shared/game_kit/game_kit.dart';

/// 第 1 单元首切片的数据。解析自 chinese-unit1.json。
class ChineseUnit1Data {
  const ChineseUnit1Data({
    required this.matchPairs,
    required this.cardStart,
    required this.cardHand,
    required this.fallingTargets,
    required this.fallingDistractors,
    required this.fallingQuestion,
  });

  final List<({String id, String char, String pinyin})> matchPairs;
  final ({String id, String char, String radical}) cardStart;
  final List<({String id, String char, String radical})> cardHand;
  final List<({String id, String char, String radical})> fallingTargets;
  final List<({String id, String char, String radical})> fallingDistractors;
  final String fallingQuestion;

  /// 从解析后的 JSON（Map）构造。字段缺失或类型不符时抛出 FormatException。
  factory ChineseUnit1Data.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(Object? v, String name) {
      if (v is! List) throw FormatException('$name 必须是列表');
      return v.cast<Map<String, dynamic>>();
    }

    String str(Map<String, dynamic> m, String key) {
      final v = m[key];
      if (v is! String || v.isEmpty) throw FormatException('缺少字段 $key');
      return v;
    }

    final match = json['stepA_match'] as Map<String, dynamic>;
    final card = json['stepB_cardplay'] as Map<String, dynamic>;
    final falling = json['stepC_falling'] as Map<String, dynamic>;

    ({String id, String char, String radical}) rad(Map<String, dynamic> m) =>
        (id: str(m, 'id'), char: str(m, 'char'), radical: str(m, 'radical'));

    return ChineseUnit1Data(
      matchPairs: list(match['pairs'], 'pairs')
          .map((m) => (id: str(m, 'id'), char: str(m, 'char'), pinyin: str(m, 'pinyin')))
          .toList(),
      cardStart: rad(card['start'] as Map<String, dynamic>),
      cardHand: list(card['hand'], 'hand').map(rad).toList(),
      fallingTargets: list(falling['targets'], 'targets').map(rad).toList(),
      fallingDistractors: list(falling['distractors'], 'distractors').map(rad).toList(),
      fallingQuestion: str(falling, 'question'),
    );
  }
}

/// 字与拼音配对（框架：配对）。每对两段文本共用同一个 id。
MatchConfig buildMatchConfig(ChineseUnit1Data data, AnswerReporter onAnswer) {
  final pairs = data.matchPairs.map((p) {
    return (
      GameItem(id: p.id, prompt: p.char),
      GameItem(id: p.id, prompt: p.pinyin),
    );
  }).toList();
  return MatchConfig(onAnswer: onAnswer, pairs: pairs);
}

/// 词语接龙（框架：出牌）。学科规则：同偏旁的字可以接龙。
CardPlayConfig buildCardPlayConfig(ChineseUnit1Data data, AnswerReporter onAnswer) {
  GameCard toCard(({String id, String char, String radical}) c) => GameCard(
        item: GameItem(id: c.id, prompt: c.char),
        attribute: c.radical,
      );
  return CardPlayConfig(
    onAnswer: onAnswer,
    startCard: toCard(data.cardStart),
    hand: data.cardHand.map(toCard).toList(),
  );
}

/// 限时选择（框架：下落选择）。学科规则：选出偏旁与题干一致的字。
FallingChoiceConfig buildFallingConfig(ChineseUnit1Data data, AnswerReporter onAnswer) {
  GameItem toItem(({String id, String char, String radical}) c) =>
      GameItem(id: c.id, prompt: c.char, hint: c.radical);
  return FallingChoiceConfig(
    onAnswer: onAnswer,
    targets: data.fallingTargets.map(toItem).toList(),
    distractors: data.fallingDistractors.map(toItem).toList(),
  );
}
