import 'dart:math';

import 'match_game.dart' show shortMeaning;
import 'unit.dart';

/// 一张牌：英文词或它的中文义。同一个词的英文与中文互为一对。
class UnoCard {
  const UnoCard({
    required this.pairId,
    required this.text,
    required this.isEnglish,
    required this.color,
  });

  final int pairId;
  final String text;
  final bool isEnglish;
  final int color; // 0..3，同色的牌可以互相接
}

/// 单词 UNO（单人清牌）：顶牌是一张英文或中文。手里的牌若与顶牌同色，或是它的对应一半，就能出。
/// 出不了就摸牌。手牌全部出完即胜利。
class WordUno {
  WordUno._(this.hand, this.drawPile, this.top);

  final List<UnoCard> hand;
  final List<UnoCard> drawPile;
  UnoCard top;
  int draws = 0;

  static const int colorCount = 4;

  /// 用词表前 [pairs] 个词建牌。每个词两张（英文、中文），颜色按词序轮换。
  factory WordUno.fromWords(List<Word> words, {int pairs = 6, int seed = 0}) {
    final chosen = words.take(pairs).toList();
    final deck = <UnoCard>[];
    for (var i = 0; i < chosen.length; i++) {
      final color = i % colorCount;
      deck.add(
        UnoCard(pairId: i, text: chosen[i].en, isEnglish: true, color: color),
      );
      deck.add(
        UnoCard(
          pairId: i,
          text: shortMeaning(chosen[i].zh),
          isEnglish: false,
          color: color,
        ),
      );
    }
    deck.shuffle(_Rng(seed));
    final top = deck.removeLast();
    // 手牌：一半，其余放在摸牌堆。
    final handSize = deck.length ~/ 2;
    final hand = deck.sublist(0, handSize);
    final drawPile = deck.sublist(handSize);
    return WordUno._(hand, drawPile, top);
  }

  bool get isWon => hand.isEmpty;
  bool get isStuck => !hand.any(canPlay) && drawPile.isEmpty;

  bool canPlay(UnoCard card) =>
      card.color == top.color || card.pairId == top.pairId;

  /// 出牌。返回是否成功（不能出的牌返回 false）。
  bool play(UnoCard card) {
    if (!hand.contains(card) || !canPlay(card)) {
      return false;
    }
    hand.remove(card);
    top = card;
    return true;
  }

  /// 摸一张牌。摸牌堆空了返回 false。
  bool draw() {
    if (drawPile.isEmpty) {
      return false;
    }
    hand.add(drawPile.removeLast());
    draws++;
    return true;
  }
}

/// 小型可复现随机数，保证同一个种子出同一副牌（便于测试）。
class _Rng implements Random {
  _Rng(this._seed);
  int _seed;

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1 << 20) / (1 << 20);
}
