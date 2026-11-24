import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/entry.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';

void main() {
  testWidgets('返回键调用 onExit，且不直接弹出路由', (tester) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => buildSubjectEntry(
                  userId: UserId('stu-001'),
                  subject: SubjectCode.english,
                  onExit: () => exits++,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(exits, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(exits, 1);
  });
}
