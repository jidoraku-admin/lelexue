import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/twenty_questions.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/word_uno.dart';

void main() {
  final words = [
    Word(en: 'hello', zh: '你好', page: 1),
    Word(en: 'hi', zh: '嗨', page: 1),
    Word(en: 'bye', zh: '再见', page: 1),
    Word(en: 'good night', zh: '晚安', page: 1),
  ];

  group('20 个问题', () {
    test('每个可用问题都能把候选词分开', () {
      final g = TwentyQuestions(words: words, secretIndex: 0);
      for (final q in g.availableQuestions()) {
        final yes = words.where(q.test).length;
        expect(yes > 0 && yes < words.length, isTrue, reason: q.text);
      }
    });

    test('问题缩小候选词，直到只剩一个就算猜中', () {
      final g = TwentyQuestions(words: words, secretIndex: 3); // good night
      final lengthQ = YesNoQuestion('超过 4 个字母吗？', (w) => w.en.length > 4);
      expect(g.ask(lengthQ), isTrue);
      expect(g.remainingCandidates, lessThan(words.length));
      final spaceQ = YesNoQuestion('是词组吗？', (w) => w.en.contains(' '));
      expect(g.ask(spaceQ), isTrue);
      expect(g.solved, isTrue);
      expect(g.isOver, isTrue);
    });

    test('猜错不结束，猜中即胜利，超过 20 次提问后结束', () {
      final g = TwentyQuestions(words: words, secretIndex: 0, maxQuestions: 2);
      expect(g.guess(words[1]), isFalse);
      expect(g.candidatesContain(words[1]), isFalse, reason: '猜错的词应被排除');
      expect(g.isOver, isFalse);
      expect(g.guess(words[0]), isTrue);
      expect(g.isWon, isTrue);
    });

    test('默认上限为 20 次', () {
      expect(TwentyQuestions.defaultMax, 20);
    });
  });

  group('单词 UNO', () {
    test('牌数正确：每个词两张加两张万能牌，手牌加摸牌堆加顶牌等于总数', () {
      final g = WordUno.fromWords(words, pairs: 4, seed: 1);
      expect(g.hand.length + g.drawPile.length + 1, 10);
      final noWild = WordUno.fromWords(words, pairs: 4, wilds: 0, seed: 1);
      expect(noWild.hand.length + noWild.drawPile.length + 1, 8);
    });

    test('万能牌任何时候都能出，但必须选颜色；选色后顶牌变成该颜色', () {
      final g = WordUno.fromWords(words, pairs: 4, seed: 4);
      // 手里放一张万能牌，保证可测
      g.hand.add(UnoCard.wild);
      final wild = g.hand.last;
      expect(g.canPlay(wild), isTrue);
      expect(g.play(wild), isFalse, reason: '没选颜色不能出');
      expect(g.play(wild, chosenColor: 2), isTrue);
      expect(g.top.color, 2);
    });

    test('开局顶牌不是万能牌', () {
      for (var seed = 0; seed < 50; seed++) {
        final g = WordUno.fromWords(words, pairs: 4, seed: seed);
        expect(g.top.isWild, isFalse, reason: 'seed $seed');
      }
    });

    test('只能出与顶牌同色或互为一对的牌，出牌后顶牌更新', () {
      final g = WordUno.fromWords(words, pairs: 4, seed: 2);
      final playable = g.hand.where(g.canPlay).toList();
      for (final c in g.hand) {
        final ok = c.color == g.top.color || c.pairId == g.top.pairId;
        expect(g.canPlay(c), ok);
      }
      if (playable.isNotEmpty) {
        final card = playable.first;
        expect(g.play(card), isTrue);
        expect(g.top, card);
      }
    });

    test('不能出的牌不能出；摸牌可以补充手牌；手牌出完即胜利', () {
      final g = WordUno.fromWords(words, pairs: 2, seed: 3);
      final blocked = g.hand.where((c) => !g.canPlay(c)).toList();
      if (blocked.isNotEmpty) {
        expect(g.play(blocked.first), isFalse);
      }
      final before = g.hand.length;
      if (g.drawPile.isNotEmpty) {
        expect(g.draw(), isTrue);
        expect(g.hand.length, before + 1);
      }
      // 把手牌全部出完（可能需要摸牌），直到胜利或卡住。
      var guard = 0;
      while (!g.isWon && !g.isStuck && guard++ < 100) {
        _playOneTurn(g);
      }
      expect(g.isWon || g.isStuck, isTrue);
    });

    test('按规则一直出，所有牌局都能出完（不会卡死）', () {
      for (var seed = 0; seed < 100; seed++) {
        final g = WordUno.fromWords(words, pairs: 4, seed: seed);
        var guard = 0;
        while (!g.isWon && guard++ < 5000) {
          if (!_playOneTurn(g)) break;
        }
        expect(g.isWon, isTrue, reason: 'seed $seed 没有出完');
      }
    });
  });
}

/// 一个回合：能出普通牌就出；只有万能牌就出万能牌（选手牌最多的颜色）；否则摸牌。返回是否还能继续。
bool _playOneTurn(WordUno g) {
  final normal = g.hand.where((c) => !c.isWild && g.canPlay(c)).toList();
  if (normal.isNotEmpty) {
    return g.play(normal.first);
  }
  final wild = g.hand.where((c) => c.isWild).toList();
  if (wild.isNotEmpty) {
    return g.play(wild.first, chosenColor: g.bestColorForHand());
  }
  return g.draw();
}
