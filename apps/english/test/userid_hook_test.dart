import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/mastery.dart';
import 'package:lelexue_english/domain/student_identity.dart';

void main() {
  final achievement = MasteryAchievement(
    knowledgePointId: 'english.g3.v1.u01.k001',
    level: 2,
    achievedAt: DateTime.utc(2026, 11, 22, 15),
  );

  test('默认身份来源没有 UserId，不能伪造', () {
    expect(const NoStudentIdentity().userId, isNull);
  });

  test('payload 含业务字段，不含 eventId，userId 由调用方提供', () {
    final payload = masteryChangedPayload(achievement, userId: 'stu-001');
    expect(payload['userId'], 'stu-001');
    expect(payload['subject'], 'english');
    expect(payload['knowledgePointId'], 'english.g3.v1.u01.k001');
    expect(payload['level'], 2);
    expect(payload['achievedAt'], '2026-11-22T15:00:00.000Z');
    expect(payload.containsKey('eventId'), isFalse);
  });

  test('空 userId 直接拒绝', () {
    expect(
      () => masteryChangedPayload(achievement, userId: '  '),
      throwsArgumentError,
    );
  });
}
