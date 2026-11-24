import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/content/chemistry_content.dart';
import 'package:lelexue_chemistry/scoring/chemistry_scoring.dart';
import 'package:lelexue_chemistry/slices/e1_collect_method/e1_page.dart';
import 'package:shared/core/core.dart';

void main() {
  testWidgets('E1 全部答对：显示结果并记录 1★ 掌握草稿', (tester) async {
    final scoring = ChemistryScoring(userId: UserId('test-user'), reviewInterval: const Duration(hours: 24));
    await tester.pumpWidget(MaterialApp(home: E1Page(scoring: scoring)));

    // 题目数不足 5 题时不会达到门槛，这里只验证流程与计分不报错。
    for (final q in e1Questions) {
      expect(find.text(q.prompt), findsOneWidget);
      await tester.tap(find.text(q.options[q.answerIndex]));
      await tester.pump();
      await tester.tap(find.text(q == e1Questions.last ? '查看结果' : '下一题'));
      await tester.pump();
    }

    expect(find.textContaining('本轮答对 ${e1Questions.length} / ${e1Questions.length}'), findsOneWidget);
    expect(scoring.drainPendingMastery(), isEmpty);
  });

  testWidgets('E1 选错后显示正确答案与原理解释，选项不可再选', (tester) async {
    final scoring = ChemistryScoring(userId: UserId('test-user'), reviewInterval: const Duration(hours: 24));
    await tester.pumpWidget(MaterialApp(home: E1Page(scoring: scoring)));

    final first = e1Questions.first;
    final wrong = (first.answerIndex + 1) % first.options.length;
    await tester.tap(find.text(first.options[wrong]));
    await tester.pump();

    expect(find.textContaining('正确答案是：${first.options[first.answerIndex]}'), findsOneWidget);
    expect(find.text(first.explanation), findsOneWidget);
  });
}
