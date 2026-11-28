import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chinese/domain/chinese_unit1_adapter.dart';
import 'package:lelexue_chinese/entry.dart';
import 'package:lelexue_chinese/ui/match_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';
import 'package:shared/game_kit/game_kit.dart';

ChineseUnit1Data loadData() => ChineseUnit1Data.fromJson(
      jsonDecode(File('assets/data/chinese-unit1.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  group('配对界面', () {
    late List<GameAnswer> answers;
    late ChineseUnit1Data data;

    Future<void> pump(WidgetTester tester) async {
      answers = [];
      data = loadData();
      final n = data.matchPairs.length;
      await tester.pumpWidget(MaterialApp(
        home: MatchPage(
          config: buildMatchConfig(data, answers.add),
          rightOrder: List<int>.generate(n, (i) => n - 1 - i),
        ),
      ));
    }

    testWidgets('显示全部字与拼音', (tester) async {
      await pump(tester);
      for (final p in data.matchPairs) {
        expect(find.text(p.char), findsOneWidget);
        expect(find.text(p.pinyin), findsOneWidget);
      }
      expect(find.text('已配对 0 / ${data.matchPairs.length}'), findsOneWidget);
    });

    testWidgets('点对一组：进度加一，上报正确', (tester) async {
      await pump(tester);
      final p = data.matchPairs.first;
      await tester.tap(find.byKey(ValueKey('left-${p.id}')));
      await tester.tap(find.byKey(ValueKey('right-${p.id}')));
      await tester.pump();
      expect(find.text('已配对 1 / ${data.matchPairs.length}'), findsOneWidget);
      expect(find.text('对了！'), findsOneWidget);
      expect(answers.single.correct, isTrue);
    });

    testWidgets('点错：提示再想想，上报错误', (tester) async {
      await pump(tester);
      final a = data.matchPairs[0];
      final b = data.matchPairs[1];
      await tester.tap(find.byKey(ValueKey('left-${a.id}')));
      await tester.tap(find.byKey(ValueKey('right-${b.id}')));
      await tester.pump();
      expect(find.text('再想想，读一读这个字'), findsOneWidget);
      expect(find.text('已配对 0 / ${data.matchPairs.length}'), findsOneWidget);
      expect(answers.single.correct, isFalse);
    });

    testWidgets('全部配对后可以重玩', (tester) async {
      await pump(tester);
      for (final p in data.matchPairs) {
        await tester.ensureVisible(find.byKey(ValueKey('left-${p.id}')));
        await tester.tap(find.byKey(ValueKey('left-${p.id}')));
        await tester.ensureVisible(find.byKey(ValueKey('right-${p.id}')));
        await tester.tap(find.byKey(ValueKey('right-${p.id}')));
        await tester.pump();
      }
      expect(find.text('全部配对完成！'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('restart')));
      await tester.pump();
      expect(find.text('已配对 0 / ${data.matchPairs.length}'), findsOneWidget);
      expect(find.byKey(const ValueKey('restart')), findsNothing);
    });
  });

  group('hub 入口', () {
    Future<List<int>> pumpEntry(WidgetTester tester,
        {Future<ChineseUnit1Data> Function()? loader}) async {
      final exits = <int>[];
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => buildSubjectEntry(
            userId: UserId('u-test'),
            subject: SubjectCode.chinese,
            onExit: () => exits.add(1),
            loader: loader ?? () async => loadData(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return exits;
    }

    testWidgets('进入配对并返回', (tester) async {
      final exits = await pumpEntry(tester);
      expect(find.text('乐乐学·语文'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('step-match')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MatchPage), findsNothing);
      expect(exits, isEmpty);
      await tester.tap(find.byTooltip('返回'));
      expect(exits, hasLength(1));
    });

    testWidgets('加载失败时提示', (tester) async {
      await pumpEntry(tester, loader: () async => throw const FormatException('x'));
      expect(find.text('题目加载失败，请稍后再试'), findsOneWidget);
    });
  });
}
