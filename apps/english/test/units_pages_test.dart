import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/ui/falling_game_page.dart';
import 'package:lelexue_english/ui/guess_game_page.dart';
import 'package:lelexue_english/ui/match_game_page.dart';
import 'package:lelexue_english/ui/word_uno_page.dart';
import 'package:material_ui/material_ui.dart';

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

  // 同一个用例里依次打开各单元的各个游戏页面（资源异步加载，分开写会互相干扰）。
  testWidgets('单元 2、3 复用同一套游戏页面，数据正确加载', (tester) async {
    for (final unit in ['unit2', 'unit3']) {
      final path = 'assets/data/$unit.json';

      await tester.pumpWidget(const SizedBox());
      await settle(tester, rounds: 2);
      await tester.pumpWidget(
        MaterialApp(home: GuessGamePage(assetPath: path)),
      );
      await settleUntil(tester, find.textContaining('已问 0/20'));
      expect(
        find.textContaining('已问 0/20'),
        findsOneWidget,
        reason: '$unit 20问',
      );
      expect(find.byType(ActionChip), findsWidgets, reason: '$unit 20问应有问题');

      await tester.pumpWidget(const SizedBox());
      await settle(tester, rounds: 2);
      await tester.pumpWidget(MaterialApp(home: WordUnoPage(assetPath: path)));
      await settleUntil(tester, find.textContaining('手牌'));
      expect(find.textContaining('手牌'), findsOneWidget, reason: '$unit UNO');

      await tester.pumpWidget(const SizedBox());
      await settle(tester, rounds: 2);
      await tester.pumpWidget(
        MaterialApp(home: MatchGamePage(assetPath: path)),
      );
      await settleUntil(tester, find.byType(InkWell));
      expect(find.byType(GridView), findsOneWidget, reason: '$unit 翻卡');

      await tester.pumpWidget(const SizedBox());
      await settle(tester, rounds: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: FallingGamePage(assetPath: path, kind: FallingKind.frog),
        ),
      );
      await settleUntil(tester, find.text('开始'));
      expect(find.text('开始'), findsOneWidget, reason: '$unit 青蛙吃虫');
    }
  });
}
