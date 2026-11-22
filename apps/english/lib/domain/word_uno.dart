import 'dart:math';

import 'game_item.dart';

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
  final int color; // 0..3，同色的牌可以互相接；万能牌的颜色由出牌时选择

  /// 万能牌：没有词，可以在任何时候出，出的时候选一个颜色。
  bool get isWild => pairId < 0;

  static const UnoCard wild = UnoCard(
    pairId: -1,
    text: '万能',
    isEnglish: false,
    color: -1,
  );
}

/// 单词 UNO（单人清牌）：顶牌是一张英文或中文。手里的牌若与顶牌同色，或是它的对应一半，就能出。
/// 出不了就摸牌。手牌全部出完即胜利。
class WordUno {
  WordUno._(this.hand, this.drawPile, this.top, this._rng);

  final List<UnoCard> hand;
  final List<UnoCard> drawPile;
  final List<UnoCard> discard = []; // 已出过的牌，摸牌堆空了就洗回去
  UnoCard top;
  int draws = 0;
  final _Rng _rng;

  static const int colorCount = 4;

  /// 用题目前 [pairs] 个建牌。每个题目两张（主文本、短释义），颜色按顺序轮换。
  factory WordUno.fromItems(
    List<GameItem> items, {
    int pairs = 6,
    int wilds = 2,
    int seed = 0,
  }) {
    final chosen = items.take(pairs).toList();
    final deck = <UnoCard>[];
    for (var i = 0; i < chosen.length; i++) {
      final color = i % colorCount;
      deck.add(
        UnoCard(pairId: i, text: chosen[i].text, isEnglish: true, color: color),
      );
      deck.add(
        UnoCard(
          pairId: i,
          text: chosen[i].label,
          isEnglish: false,
          color: color,
        ),
      );
    }
    for (var i = 0; i < wilds; i++) {
      deck.add(UnoCard.wild);
    }
    deck.shuffle(_Rng(seed));
    // 开局的顶牌不能是万能牌。
    final topIndex = deck.lastIndexWhere((c) => !c.isWild);
    final top = deck.removeAt(topIndex);
    // 手牌：一半，其余放在摸牌堆。
    final handSize = deck.length ~/ 2;
    final hand = deck.sublist(0, handSize);
    final drawPile = deck.sublist(handSize);
    return WordUno._(hand, drawPile, top, _Rng(seed + 7));
  }

  bool get isWon => hand.isEmpty;

  /// 手里没有能出的牌，而且摸牌堆和弃牌堆都空了，才算真正卡住。
  bool get isStuck => !hand.any(canPlay) && drawPile.isEmpty && discard.isEmpty;

  /// 摸牌堆是否还能摸（摸牌堆空了，弃牌可以洗回来）。
  bool get canDraw => drawPile.isNotEmpty || discard.isNotEmpty;

  bool canPlay(UnoCard card) =>
      card.isWild || card.color == top.color || card.pairId == top.pairId;

  /// 出牌。万能牌必须指定颜色 [chosenColor]。返回是否成功。
  bool play(UnoCard card, {int? chosenColor}) {
    if (!hand.contains(card) || !canPlay(card)) {
      return false;
    }
    if (card.isWild &&
        (chosenColor == null || chosenColor < 0 || chosenColor >= colorCount)) {
      return false;
    }
    hand.remove(card);
    discard.add(top);
    top = card.isWild
        ? UnoCard(pairId: -1, text: '万能', isEnglish: false, color: chosenColor!)
        : card;
    return true;
  }

  /// 手里的牌里，哪种颜色最多（万能牌出时替你选颜色）。
  int bestColorForHand() {
    final counts = List<int>.filled(colorCount, 0);
    for (final c in hand) {
      if (!c.isWild) counts[c.color]++;
    }
    var best = 0;
    for (var i = 1; i < colorCount; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  /// 摸一张牌。摸牌堆空了就先把弃牌洗回摸牌堆；两堆都空了返回 false。
  bool draw() {
    if (drawPile.isEmpty) {
      if (discard.isEmpty) {
        return false;
      }
      drawPile.addAll(discard);
      discard.clear();
      drawPile.shuffle(_rng);
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
