import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/ui/guess_game_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('20 个问题：有玩法说明，候选词默认收起，可以提问', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuessGamePage(assetPath: 'assets/data/unit1.json'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('系统想好了一个本单元的英文单词'), findsOneWidget);

    // 候选词默认收起：折叠内容不可见。
    final tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
    expect(tile.initiallyExpanded, isFalse);

    // 提问流程：选问题 → 确定提问 → 出现系统回答。
    await tester.tap(find.byType(ActionChip).first);
    await tester.pump();
    await tester.tap(find.text('确定提问'));
    await tester.pump();
    expect(find.textContaining('系统答：'), findsOneWidget);
  });
}
