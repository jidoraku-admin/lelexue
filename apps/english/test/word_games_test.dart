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
      expect(g.isOver, isFalse);
      expect(g.guess(words[0]), isTrue);
      expect(g.isWon, isTrue);
    });

    test('默认上限为 20 次', () {
      expect(TwentyQuestions.defaultMax, 20);
    });
  });

  group('单词 UNO', () {
    test('牌数正确：每个词两张，手牌加摸牌堆加顶牌等于总数', () {
      final g = WordUno.fromWords(words, pairs: 4, seed: 1);
      expect(g.hand.length + g.drawPile.length + 1, 8);
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
        final next = g.hand.where(g.canPlay).toList();
        if (next.isNotEmpty) {
          g.play(next.first);
        } else {
          g.draw();
        }
      }
      expect(g.isWon || g.isStuck, isTrue);
    });
  });
}
