import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_physics/main.dart';

void main() {
  testWidgets('首关页面可以渲染第一题', (tester) async {
    await tester.pumpWidget(const PhysicsFirstSliceApp());
    expect(find.textContaining('第 1 / 5 题'), findsOneWidget);
  });
}
