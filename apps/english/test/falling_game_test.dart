import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lelexue_english/data/speech_player.dart';
import 'package:lelexue_english/data/unit_repository.dart';
import 'package:lelexue_english/domain/english_game_adapter.dart'
    show shortMeaning;
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/ui/falling_game_page.dart';

/// 真实异步加载资源，用真实时间推进，再交替泵帧。
Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 等待某个控件出现（资源读取是真实异步的）。
Future<void> settleUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await settle(tester, rounds: 1);
  }
}

const _assetPath = 'assets/data/unit1.json';

/// 等待屏幕上出现目标词（wantTarget）或非目标词，返回它的英文；每次都重新读取当前目标。
/// 只认中心点能被点中的气泡：气泡会互相重叠，被遮住的那个点下去会点到别的词。
Future<String> waitForBubble(
  WidgetTester tester,
  Unit unit, {
  required bool wantTarget,
}) async {
  for (var i = 0; i < 300; i++) {
    final target = await currentTargetEn(tester, unit);
    for (final w in unit.words) {
      final isTarget = w.en == target;
      if (isTarget == wantTarget &&
          find.text(w.en).hitTestable().evaluate().isNotEmpty) {
        return w.en;
      }
    }
    await settle(tester, rounds: 1);
  }
  fail('等待气泡超时');
}

/// 点中某个单词气泡（取能被点中的那一个）。
Future<void> tapBubble(WidgetTester tester, String en) async {
  await tester.tap(find.text(en).hitTestable().first);
  await settle(tester, rounds: 2);
}

/// 读出页面顶部的剩余命数。
int lives() {
  final header = find.textContaining('进度 ').evaluate().first.widget as Text;
  return '❤'.allMatches(header.data!).length;
}

/// 读出页面顶部"找：xxx"里的中文，再从单元词表里找到对应的英文。
Future<String> currentTargetEn(WidgetTester tester, Unit unit) async {
  final header = find.textContaining('找：').evaluate().first.widget as Text;
  final zh = header.data!.replaceFirst('找：', '');
  return unit.words.firstWhere((w) => shortMeaning(w.zh) == zh).en;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SpeechPlayer.enabled = false;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          final file = File(key);
          if (!file.existsSync()) return null;
          return ByteData.sublistView(file.readAsBytesSync());
        });
  });

  // 三个场景合并在一个用例里：资源异步加载，分开写会互相干扰（与其他用例的做法一致）。
  testWidgets('青蛙吃虫：说明、点对得分、点错扣命', (tester) async {
    // 1. 开始前的说明
    await tester.pumpWidget(
      const MaterialApp(
        home: FallingGamePage(
          assetPath: _assetPath,
          kind: FallingKind.frog,
          seed: 7,
        ),
      ),
    );
    await settleUntil(tester, find.text('开始'));
    expect(find.textContaining('点中屏幕上对应的英文单词'), findsOneWidget);
    await tester.tap(find.text('开始'));
    await settle(tester, rounds: 2);

    final unit = await tester.runAsync(
      () => const UnitRepository().load(_assetPath),
    );
    await currentTargetEn(tester, unit!);

    // 2. 点错：扣一条命，给出提示（目标可能已飞走换了，所以点击前重新读取）
    // 等待期间目标可能飞走扣命，所以按点击前后的差值判断。
    final wrong = await waitForBubble(tester, unit, wantTarget: false);
    final livesBefore = lives();
    await tapBubble(tester, wrong);
    expect(find.textContaining('不是这个哦'), findsOneWidget);
    expect(lives(), livesBefore - 1);

    // 3. 点对：得分、进度前进
    final right = await waitForBubble(tester, unit, wantTarget: true);
    await tapBubble(tester, right);
    expect(find.textContaining('分数 10'), findsOneWidget);
    expect(find.textContaining('进度 1/10'), findsOneWidget);

    // 4. 一直点对，直到通关：应出现结束卡片
    for (var k = 0; k < 12 && find.text('再玩一局').evaluate().isEmpty; k++) {
      final next = await waitForBubble(tester, unit, wantTarget: true);
      await tapBubble(tester, next);
    }
    expect(find.text('再玩一局'), findsOneWidget, reason: '通关后应出现结束卡片');
    expect(find.textContaining('进度 10/10'), findsOneWidget);
  });
}
