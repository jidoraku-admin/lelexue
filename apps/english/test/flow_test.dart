import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/main.dart';
import 'package:lelexue_english/domain/unit_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // 资源从本地文件读取，避免测试环境依赖打包资源。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          final file = File(key);
          if (!file.existsSync()) return null;
          final bytes = file.readAsBytesSync();
          return ByteData.sublistView(bytes);
        });
  });

  testWidgets('地图 → 认词关 1 完整通关', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final source = File('assets/data/unit1.json').readAsStringSync();
    final unit = const UnitLoader().parse(source);
    final level = unit.levels.first;

    await tester.pumpWidget(const LelexueEnglishApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Unit 1 Greetings'), findsOneWidget);
    await tester.tap(find.text('Unit 1 Greetings'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('认词关 1'), findsOneWidget);

    await tester.ensureVisible(find.text('认词关 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('认词关 1'));
    await tester.pumpAndSettle();

    for (final q in level.questions) {
      final correct = q.options[q.answer];
      await tester.ensureVisible(find.text(correct).first);
      await tester.tap(find.text(correct).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(ValueKey<String>('next')),
        findsOneWidget,
        reason: q.id,
      );
      await tester.ensureVisible(find.byKey(ValueKey<String>('next')));
      await tester.tap(find.byKey(ValueKey<String>('next')));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('过关！'), findsOneWidget);
    expect(find.text('返回地图'), findsOneWidget);
  });
}
