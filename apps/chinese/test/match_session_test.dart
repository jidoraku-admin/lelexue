import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chinese/domain/chinese_unit1_adapter.dart';
import 'package:lelexue_chinese/domain/match_session.dart';
import 'package:shared/game_kit/game_kit.dart';

ChineseUnit1Data loadData() => ChineseUnit1Data.fromJson(
      jsonDecode(File('assets/data/chinese-unit1.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  late List<GameAnswer> answers;
  late DateTime now;
  late MatchSession session;

  setUp(() {
    answers = [];
    now = DateTime(2026, 11, 28, 9);
    final config = buildMatchConfig(loadData(), answers.add);
    // 右侧倒序展示，保证位置与左侧不同。
    final n = config.pairs.length;
    session = MatchSession(
      config,
      clock: () => now,
      rightOrder: List<int>.generate(n, (i) => n - 1 - i),
    );
  });

  int rightIndexOf(String id) =>
      session.rightItems.indexWhere((it) => it.id == id);

  test('左侧是字、右侧是拼音，两侧条数一致', () {
    expect(session.leftItems.map((e) => e.prompt), contains('坡'));
    expect(session.rightItems.map((e) => e.prompt), contains('pō'));
    expect(session.leftItems.length, session.rightItems.length);
  });

  test('只选一侧时不判定、不上报', () {
    expect(session.tap(MatchSide.left, 0), MatchOutcome.selected);
    expect(answers, isEmpty);
    expect(session.selectedLeft, 0);
  });

  test('配对正确：上报正确与用时，该对锁定', () {
    final id = session.leftItems[0].id;
    session.tap(MatchSide.left, 0);
    now = now.add(const Duration(milliseconds: 1500));
    expect(session.tap(MatchSide.right, rightIndexOf(id)), MatchOutcome.correct);
    expect(answers.single.itemId, id);
    expect(answers.single.correct, isTrue);
    expect(answers.single.durationMs, 1500);
    expect(session.isMatched(id), isTrue);
    expect(session.selectedLeft, isNull);
    // 已配对的项再点无效，也不再上报。
    expect(session.tap(MatchSide.left, 0), MatchOutcome.selected);
    expect(session.selectedLeft, isNull);
    expect(answers, hasLength(1));
  });

  test('配对错误：上报错误，清空选择，不锁定', () {
    final id = session.leftItems[0].id;
    final wrong = session.rightItems.indexWhere((it) => it.id != id);
    session.tap(MatchSide.right, wrong);
    expect(session.tap(MatchSide.left, 0), MatchOutcome.wrong);
    expect(answers.single.correct, isFalse);
    expect(answers.single.itemId, id);
    expect(session.isMatched(id), isFalse);
    expect(session.selectedLeft, isNull);
    expect(session.selectedRight, isNull);
  });

  test('全部配对后完成', () {
    for (var i = 0; i < session.leftItems.length; i++) {
      final id = session.leftItems[i].id;
      session.tap(MatchSide.left, i);
      session.tap(MatchSide.right, rightIndexOf(id));
    }
    expect(session.isComplete, isTrue);
    expect(answers.every((a) => a.correct), isTrue);
  });

  test('rightOrder 不是排列时报错', () {
    final config = buildMatchConfig(loadData(), (_) {});
    expect(() => MatchSession(config, rightOrder: [0, 0, 1, 2, 3, 4]),
        throwsArgumentError);
  });

  test('内容：每个字的拼音带声调且各不相同', () {
    final data = loadData();
    final tone = RegExp('[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]');
    for (final p in data.matchPairs) {
      expect(p.pinyin, matches(tone), reason: '${p.char} 拼音缺少声调');
    }
    expect(data.matchPairs.map((p) => p.pinyin).toSet().length,
        data.matchPairs.length);
    expect(data.matchPairs.map((p) => p.id).toSet().length,
        data.matchPairs.length);
  });
}
