import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/ui/guess_game_page.dart';
import 'package:lelexue_english/ui/word_uno_page.dart';
import 'package:material_ui/material_ui.dart';

/// 真实异步加载资源，用真实时间推进，再交替泵帧。
Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> settleUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await settle(tester, rounds: 1);
  }
}

const _assetPath = 'assets/data/unit1.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          final file = File(key);
          if (!file.existsSync()) return null;
          return ByteData.sublistView(file.readAsBytesSync());
        });
  });

  // 两个页面放在同一个用例里顺序验证：资源异步加载，分开写会互相干扰（与其他用例的做法一致）。
  testWidgets('20 个问题与单词 UNO 页面可以玩', (tester) async {
    // —— 20 个问题 ——
    await tester.pumpWidget(
      const MaterialApp(home: GuessGamePage(assetPath: _assetPath)),
    );
    await settleUntil(tester, find.textContaining('已问 0/20'));
    expect(find.textContaining('已问 0/20'), findsOneWidget);

    for (var k = 0; k < 25; k++) {
      if (find.text('再来一局').evaluate().isNotEmpty) break;
      // 先确认待问的问题；候选词不多时直接猜（列表里的第一个），否则选第一个问题。
      final confirm = find.text('确定提问');
      final guesses = find.byType(OutlinedButton);
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
      } else if (guesses.evaluate().isNotEmpty) {
        await tester.tap(guesses.first);
      } else {
        await tester.tap(find.byType(ActionChip).first);
      }
      await settle(tester, rounds: 2);
    }
    final ended =
        find.textContaining('答案是').evaluate().isNotEmpty ||
        find.textContaining('猜对了').evaluate().isNotEmpty;
    expect(ended, isTrue, reason: '应当以猜对或时间到结束');
    expect(find.text('再来一局'), findsOneWidget);

    // —— 单词 UNO ——
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
    await tester.pumpWidget(
      const MaterialApp(home: WordUnoPage(assetPath: _assetPath)),
    );
    await settleUntil(tester, find.textContaining('手牌'));
    expect(find.textContaining('手牌'), findsOneWidget);

    // 反复点手牌（能出的会出，不能出的给提示），或摸牌，直到出现万能牌选色。
    var picked = false;
    for (var k = 0; k < 60 && !picked; k++) {
      if (find.text('红').evaluate().isNotEmpty &&
          find.textContaining('选一个颜色').evaluate().isNotEmpty) {
        await tester.tap(find.text('红'));
        await settle(tester, rounds: 2);
        expect(find.textContaining('换成了红色'), findsOneWidget);
        picked = true;
        break;
      }
      final cards = find.byType(InkWell);
      if (cards.evaluate().length > 1) {
        await tester.tap(cards.at(1 + k % (cards.evaluate().length - 1)));
      }
      await settle(tester, rounds: 1);
      if (find.textContaining('摸牌').evaluate().isNotEmpty) {
        final draw = find.textContaining('摸牌');
        await tester.tap(draw.first);
      }
      await settle(tester, rounds: 1);
    }
    expect(picked, isTrue, reason: '应当能遇到万能牌并选择颜色');
  });
}
