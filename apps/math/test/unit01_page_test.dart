import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_math/unit01/judge.dart';
import 'package:lelexue_math/unit01/unit01_page.dart';

const _item = Unit01Item(
  id: 'math.g3.v1.u01.k002',
  game: 'observe_choice',
  prompt: '从左边看，看到几个方块？',
  answer: '2',
  distractors: ['1', '3'],
);

void main() {
  testWidgets('答对时显示正确反馈', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Unit01Page(items: [_item]))));
    await tester.tap(find.byKey(const Key('option-2')));
    await tester.pump();
    expect(find.byKey(const Key('feedback')), findsOneWidget);
    expect(find.text('答对了！'), findsOneWidget);
  });

  testWidgets('答错时显示提示，并可进入下一题', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Unit01Page(items: [_item]))));
    await tester.tap(find.byKey(const Key('option-1')));
    await tester.pump();
    expect(find.text('再看看，换个角度想想。'), findsOneWidget);
    await tester.tap(find.text('下一题'));
    await tester.pump();
    expect(find.text('第 1 单元完成！'), findsOneWidget);
  });
}
