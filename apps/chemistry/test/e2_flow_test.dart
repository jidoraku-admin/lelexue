import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/chemistry.dart';
import 'package:lelexue_chemistry/content/chemistry_content.dart';
import 'package:shared/core/core.dart';

Widget _app() => MaterialApp(
      home: Builder(
        builder: (_) => buildSubjectEntry(
          userId: UserId('test-user'),
          subject: SubjectCode.chemistry,
          onExit: () {},
        ),
      ),
    );

void main() {
  testWidgets('入口中 E2 位于 E1 与 E3 之间', (tester) async {
    await tester.pumpWidget(_app());
    final y1 = tester.getTopLeft(find.text('E1 氧气的收集')).dy;
    final y2 = tester.getTopLeft(find.text('E2 过氧化氢制氧')).dy;
    final y3 = tester.getTopLeft(find.text('E3 氧气的检验')).dy;
    expect(y1 < y2 && y2 < y3, isTrue);
  });

  testWidgets('E2 从入口进入并完成一次作答，每一步都显示安全提示', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('E2 过氧化氢制氧'));
    await tester.pumpAndSettle();

    for (final q in e2Questions) {
      expect(find.text(q.prompt), findsOneWidget);
      expect(find.text('安全提示：$e2SafetyNotice'), findsOneWidget);
      await tester.tap(find.text(q.options[q.answerIndex]));
      await tester.pump();
      expect(find.text('答对了。'), findsOneWidget);
      expect(find.text('安全提示：$e2SafetyNotice'), findsOneWidget);
      await tester.tap(find.text(q == e2Questions.last ? '查看结果' : '下一题'));
      await tester.pump();
    }

    expect(find.textContaining('本轮答对 ${e2Questions.length} / ${e2Questions.length}'), findsOneWidget);
  });

  testWidgets('E2 二氧化锰作用题选错：判为错误并显示正确答案', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('E2 过氧化氢制氧'));
    await tester.pumpAndSettle();

    // 前两题答对，跳到第 3 题（样例题 1）。
    for (final q in e2Questions.take(2)) {
      await tester.tap(find.text(q.options[q.answerIndex]));
      await tester.pump();
      await tester.tap(find.text('下一题'));
      await tester.pump();
    }
    final q3 = e2Questions[2];
    expect(q3.prompt, contains('二氧化锰的作用'));
    await tester.tap(find.text('提供氧气'));
    await tester.pump();
    expect(find.textContaining('正确答案是：改变反应速率'), findsOneWidget);
    expect(find.text(q3.explanation), findsOneWidget);
  });

  test('E2 判题：催化剂相关答案正确', () {
    expect(e2Questions[2].isCorrect(e2Questions[2].options.indexOf('改变反应速率')), isTrue);
    expect(e2Questions[2].isCorrect(e2Questions[2].options.indexOf('提供氧气')), isFalse);
    expect(e2Questions[3].options[e2Questions[3].answerIndex], '质量和化学性质都不变');
    expect(e2Questions[0].options[e2Questions[0].answerIndex], contains('气泡'));
  });
}
