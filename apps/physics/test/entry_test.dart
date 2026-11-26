import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lelexue_physics/physics.dart';
import 'package:shared/core/core.dart';

Widget _app({required VoidCallback onExit}) => MaterialApp(
      home: Builder(
        builder: (_) => buildSubjectEntry(
          userId: UserId('test-student'),
          subject: SubjectCode.physics,
          onExit: onExit,
        ),
      ),
    );

void main() {
  testWidgets('从入口进入 P2 并答对第一题', (tester) async {
    await tester.pumpWidget(_app(onExit: () {}));

    await tester.tap(find.text('P2 测量小车的平均速度'));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 / 5 题'), findsOneWidget);

    // 第 1 题：5 m / 10 s = 0.5 m/s
    await tester.enterText(find.byKey(const Key('p2-answer')), '0.5 m/s');
    await tester.tap(find.text('确认'));
    await tester.pump();
    expect(find.textContaining('回答正确'), findsOneWidget);

    await tester.tap(find.text('下一题'));
    await tester.pump();
    expect(find.textContaining('第 2 / 5 题'), findsOneWidget);
  });

  testWidgets('P2 漏写单位时提示，不进入下一题', (tester) async {
    await tester.pumpWidget(_app(onExit: () {}));
    await tester.tap(find.text('P2 测量小车的平均速度'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('p2-answer')), '0.5');
    await tester.tap(find.text('确认'));
    await tester.pump();
    expect(find.textContaining('别忘了写单位'), findsOneWidget);
    expect(find.text('下一题'), findsOneWidget);
  });

  testWidgets('从入口进入 P1 首关', (tester) async {
    await tester.pumpWidget(_app(onExit: () {}));
    await tester.tap(find.text('P1 赛道测速：刻度尺读数'));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 / 5 题'), findsOneWidget);
  });

  testWidgets('点返回调用 onExit', (tester) async {
    var exited = false;
    await tester.pumpWidget(_app(onExit: () => exited = true));
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(exited, isTrue);
  });
}
