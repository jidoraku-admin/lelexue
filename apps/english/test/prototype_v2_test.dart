import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 资源读取是真实异步，转圈动画也会持续出帧，所以用真实时间与帧交替推进，不用 pumpAndSettle。
Future<void> settle(WidgetTester tester, {int rounds = 30}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openUnit1(WidgetTester tester) async {
  await tester.pumpWidget(const LelexueEnglishApp());
  await settle(tester);
  expect(find.text('Unit 1 Greetings'), findsOneWidget, reason: '单元列表应已加载');
  await tester.tap(find.text('Unit 1 Greetings'));
  await settle(tester);
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

  // 两个玩法放在同一个用例里顺序验证：同一个应用实例中多次加载资源，分开写会互相干扰。
  testWidgets('单元 1：动画开场 → 返回地图 → 翻卡挑战', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openUnit1(tester);

    // 动画开场：角色出场，逐句台词，最后可以开始学习。
    await tester.tap(find.text('动画开场'));
    await settle(tester, rounds: 40);
    var guard = 0;
    while (find.text('开始学习').evaluate().isEmpty && guard++ < 10) {
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await settle(tester, rounds: 5);
    }
    expect(find.text('开始学习'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('story-next')));
    await settle(tester);
    expect(find.text('动画开场'), findsOneWidget, reason: '回到单元地图');

    // 翻卡挑战：可以翻牌，翻开的牌显示文字，未翻的牌仍是问号。
    await tester.tap(find.text('翻卡挑战'));
    await settle(tester);
    expect(find.text('?'), findsWidgets);
    final before = find.text('?').evaluate().length;
    await tester.tap(find.text('?').first);
    await settle(tester, rounds: 5);
    expect(find.text('?').evaluate().length, before - 1);
  });
}
