import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_hub/main.dart';
import 'package:lelexue_hub/registry.dart';
import 'package:shared/core/subject_code.dart';

void main() {
  test('注册表顺序固定为英语、数学、语文、物理、化学', () {
    expect(
      subjectRegistry.map((m) => m.code).toList(),
      [
        SubjectCode.english,
        SubjectCode.math,
        SubjectCode.chinese,
        SubjectCode.physics,
        SubjectCode.chemistry,
      ],
    );
  });

  test('findSubject 按 wireName 查找，未知返回 null', () {
    expect(findSubject('english')?.displayName, '英语');
    expect(findSubject('biology'), isNull);
  });

  testWidgets('入口页显示五张学科卡片', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(const HubApp());
    for (final name in ['英语', '数学', '语文', '物理', '化学']) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
