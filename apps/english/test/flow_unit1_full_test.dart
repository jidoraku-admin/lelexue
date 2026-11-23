import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/unit_loader.dart';
import 'package:lelexue_english/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 第 1 单元完整流程：地图 → 认词 → 句型 → 运用 → 单元 Boss（逐关首次全对通关）。
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

  testWidgets('第 1 单元全部关卡可按顺序通关', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final unit = const UnitLoader().parse(
      File('assets/data/unit1.json').readAsStringSync(),
    );

    await tester.pumpWidget(const LelexueEnglishApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Unit 1 Greetings'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    for (final Level level in unit.levels) {
      await tester.ensureVisible(find.text(level.title).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(level.title).first);
      await tester.pumpAndSettle();

      for (final q in level.questions) {
        final correct = q.options[q.answer];
        await tester.ensureVisible(find.text(correct).first);
        await tester.tap(find.text(correct).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byKey(const ValueKey<String>('next')),
          findsOneWidget,
          reason: '${level.id} ${q.id}',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('next')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('next')));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text('过关！'), findsOneWidget, reason: level.id);
      await tester.tap(find.text('返回地图'));
      await tester.pumpAndSettle();
    }
  });
}
