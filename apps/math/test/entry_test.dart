import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_math/entry.dart';
import 'package:lelexue_math/unit01/items_loader.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/core/core.dart';

// 与 hub 打包的资源同一文件，确保 k004–k006 能经入口进入。
final _source = File('assets/data/math-g3-unit01-items.json').readAsStringSync();

Widget _host({required VoidCallback onExit}) => MaterialApp(
      home: MathEntry(
        userId: UserId('dev-test'),
        onExit: onExit,
        loadUnit01Source: () async => _source,
      ),
    );

void main() {
  testWidgets('buildSubjectEntry 返回数学入口', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: buildSubjectEntry(
        userId: UserId('dev-test'),
        subject: SubjectCode.math,
        onExit: () {},
      ),
    ));
    expect(find.text('乐乐学·数学'), findsOneWidget);
    expect(find.byKey(const Key('math-unit01')), findsOneWidget);
  });

  testWidgets('点返回时调用 onExit', (tester) async {
    var exited = 0;
    await tester.pumpWidget(_host(onExit: () => exited++));
    await tester.tap(find.byKey(const Key('math-exit')));
    expect(exited, 1);
  });

  testWidgets('从入口可依次走到 k004–k006 并完成单元', (tester) async {
    await tester.pumpWidget(_host(onExit: () {}));
    await tester.tap(find.byKey(const Key('math-unit01')));
    await tester.pumpAndSettle();

    final prompts = <String>[];
    for (var i = 0; i < 6; i++) {
      final prompt = tester.widget<Text>(find.byKey(const Key('prompt')));
      prompts.add(prompt.data!);
      final option = find.byWidgetPredicate(
        (w) => w is ElevatedButton && w.key.toString().contains('option-'),
      );
      await tester.tap(option.first);
      await tester.pump();
      await tester.tap(find.text('下一题'));
      await tester.pump();
    }
    final items = parseUnit01Items(_source);
    final p2 = items.where((e) => RegExp(r'k00[4-6]$').hasMatch(e.id));
    expect(p2.length, 3);
    for (final item in p2) {
      expect(prompts, contains(item.prompt));
    }
    expect(find.text('这一单元你学会了从不同位置观察，下一站再见！'), findsOneWidget);
  });
}
