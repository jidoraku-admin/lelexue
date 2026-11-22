import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/falling_round.dart';
import 'package:lelexue_english/domain/unit.dart';

void main() {
  final words = [
    Word(en: 'hello', zh: '你好', page: 1),
    Word(en: 'hi', zh: '嗨', page: 1),
    Word(en: 'bye', zh: '再见', page: 1),
  ];

  test('点中目标得分并换目标，点错扣命', () {
    final r = FallingRound(words: words, goal: 3, seed: 2);
    final first = r.target;
    final wrong = words.firstWhere((w) => w.en != first.en);
    expect(r.hit(wrong), isFalse);
    expect(r.lives, 2);
    expect(r.hit(first), isTrue);
    expect(r.score, 1);
    expect(r.lives, 2);
  });

  test('目标掉落扣命，分数达到目标即胜利，命为零即失败', () {
    final r = FallingRound(words: words, goal: 1, seed: 4);
    r.targetEscaped();
    expect(r.lives, 2);
    expect(r.hit(r.target), isTrue);
    expect(r.isOver, isTrue);
    expect(r.isWon, isTrue);

    final lose = FallingRound(words: words, goal: 10, lives: 1, seed: 4);
    lose.targetEscaped();
    expect(lose.isOver, isTrue);
    expect(lose.isWon, isFalse);
  });

  test('干扰项不是目标', () {
    final r = FallingRound(words: words, goal: 5, seed: 9);
    for (var i = 0; i < 10; i++) {
      expect(r.randomDistractor().en, isNot(r.target.en));
    }
  });

  test('分数与连击：连续命中加分更多，失误清零连击', () {
    final r = FallingRound(words: words, goal: 10, seed: 3);
    expect(r.hit(r.target), isTrue);
    expect(r.points, 10);
    expect(r.hit(r.target), isTrue);
    expect(r.streak, 2);
    expect(r.points, 10 + 15);
    r.hit(words.firstWhere((w) => w.en != r.target.en));
    expect(r.streak, 0);
    expect(r.bestStreak, 2);
  });

  test('速度等级从慢到快，下落更快、出现更密', () {
    expect(FallingSpeed.slow.step < FallingSpeed.normal.step, isTrue);
    expect(FallingSpeed.normal.step < FallingSpeed.fast.step, isTrue);
    expect(FallingSpeed.slow.spawnEvery > FallingSpeed.fast.spawnEvery, isTrue);
  });
}
