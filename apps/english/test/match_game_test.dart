import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/english_game_adapter.dart';
import 'package:lelexue_english/domain/match_game.dart';
import 'package:lelexue_english/domain/unit.dart';

void main() {
  final words = [
    Word(en: 'hello', zh: '喂；你好', page: 4),
    Word(en: 'hi', zh: '嗨；你好（hello 的非正式用语）', page: 4),
    Word(en: 'I', zh: '我', page: 4),
    Word(en: 'am', zh: '（用于第一人称代词 I 后）是', page: 4),
  ];

  test('每个词生成一对卡，共 8 张', () {
    final g = MatchGame.fromItems(wordsToItems(words), scoreForStreak: pointsForStreak, pairs: 4);
    expect(g.cards.length, 8);
    for (var i = 0; i < 4; i++) {
      final pair = g.cards.where((c) => c.pairId == i).toList();
      expect(pair.length, 2);
      expect(pair.where((c) => c.isEnglish).length, 1);
    }
  });

  test('释义去掉括号和备选义项', () {
    expect(shortMeaning('喂；你好'), '喂');
    expect(shortMeaning('嗨；你好（hello 的非正式用语）'), '嗨');
    expect(shortMeaning('（用于第一人称代词 I 后）是'), '是');
    expect(shortMeaning('我'), '我');
  });

  test('配对成功与不匹配的流程', () {
    final g = MatchGame.fromItems(wordsToItems(words), scoreForStreak: pointsForStreak, pairs: 2, seed: 1);
    final en = g.cards.indexWhere((c) => c.pairId == 0 && c.isEnglish);
    final zh = g.cards.indexWhere((c) => c.pairId == 0 && !c.isEnglish);
    final other = g.cards.indexWhere((c) => c.pairId == 1 && c.isEnglish);

    expect(g.flip(en), FlipOutcome.firstOpen);
    expect(g.flip(en), FlipOutcome.ignored, reason: '同一张牌不能重复翻');
    expect(g.flip(other), FlipOutcome.mismatch);
    expect(g.hasPendingMismatch, isTrue);
    expect(g.flip(zh), FlipOutcome.ignored, reason: '不匹配未翻回前不能继续翻');
    g.hideMismatch();
    expect(g.cards[en].faceUp, isFalse);
    expect(g.cards[other].faceUp, isFalse);

    expect(g.flip(en), FlipOutcome.firstOpen);
    expect(g.flip(zh), FlipOutcome.matched);
    expect(g.cards[en].matched, isTrue);
    expect(g.cards[zh].matched, isTrue);
    expect(g.moves, 2);
  });

  test('全部配对后完成', () {
    final g = MatchGame.fromItems(wordsToItems(words), scoreForStreak: pointsForStreak, pairs: 2, seed: 3);
    for (var id = 0; id < 2; id++) {
      final en = g.cards.indexWhere((c) => c.pairId == id && c.isEnglish);
      final zh = g.cards.indexWhere((c) => c.pairId == id && !c.isEnglish);
      g.flip(en);
      g.flip(zh);
    }
    expect(g.isComplete, isTrue);
  });

  test('连对计数：配对成功累加，配错清零，记录最高连对', () {
    final g = MatchGame.fromItems(wordsToItems(words), scoreForStreak: pointsForStreak, pairs: 4, seed: 5);
    void pair(int id) {
      final en = g.cards.indexWhere((c) => c.pairId == id && c.isEnglish);
      final zh = g.cards.indexWhere((c) => c.pairId == id && !c.isEnglish);
      g.flip(en);
      g.flip(zh);
    }

    pair(0);
    pair(1);
    expect(g.streak, 2);
    // 第 2 对的英文与第 3 对的中文，不是同一对，所以不匹配。
    final en = g.cards.indexWhere((c) => c.pairId == 2 && c.isEnglish);
    final wrong = g.cards.indexWhere((c) => c.pairId == 3 && !c.isEnglish);
    g.flip(en);
    expect(g.flip(wrong), FlipOutcome.mismatch);
    expect(g.streak, 0);
    expect(g.bestStreak, 2);
  });
}
