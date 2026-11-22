import 'package:shared/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('SubjectCode', () {
    test('round-trips wire names', () {
      for (final code in SubjectCode.values) {
        expect(SubjectCode.fromWire(code.wireName), code);
      }
    });
    test('rejects unknown codes', () {
      expect(() => SubjectCode.fromWire('biology'), throwsArgumentError);
    });
  });

  group('Grade and Stage', () {
    test('derives stage from grade', () {
      expect(Grade(3).stage, Stage.primary);
      expect(Grade(6).stage, Stage.primary);
      expect(Grade(8).stage, Stage.junior);
      expect(Grade(9).stage, Stage.junior);
      expect(Grade(10).stage, Stage.senior);
    });
    test('rejects grades outside 1-12', () {
      expect(() => Grade(0), throwsArgumentError);
      expect(() => Grade(13), throwsArgumentError);
    });
    test('chemistry starting point is junior 9 upper', () {
      final grade = Grade(9);
      expect(grade.stage, Stage.junior);
      expect(Volume.fromNumber(1), Volume.upper);
    });
    test('volume only accepts 1 or 2', () {
      expect(() => Volume.fromNumber(3), throwsArgumentError);
      expect(Volume.fromNumber(2), Volume.lower);
    });
  });

  group('UserId', () {
    test('rejects empty values', () {
      expect(() => UserId(''), throwsArgumentError);
      expect(() => UserId('   '), throwsArgumentError);
    });
    test('compares by value', () {
      expect(UserId('u1'), UserId('u1'));
    });
  });

  group('MasteryChanged', () {
    final ok = MasteryChanged(
      eventId: 'e1',
      userId: UserId('u1'),
      subject: SubjectCode.english,
      knowledgePointId: 'kp-unit1-word-cat',
      level: 2,
      achievedAt: DateTime.utc(2026, 11, 22),
    );

    test('accepts a valid event', () {
      expect(ok.level, 2);
      expect(ok.dedupeKey.$4, 2);
    });
    test('rejects empty eventId and level below 1', () {
      expect(
        () => MasteryChanged(
          eventId: '',
          userId: UserId('u1'),
          subject: SubjectCode.math,
          knowledgePointId: 'kp',
          level: 1,
          achievedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => MasteryChanged(
          eventId: 'e2',
          userId: UserId('u1'),
          subject: SubjectCode.math,
          knowledgePointId: 'kp',
          level: 0,
          achievedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
    test('rejects non-UTC timestamps', () {
      expect(
        () => MasteryChanged(
          eventId: 'e3',
          userId: UserId('u1'),
          subject: SubjectCode.math,
          knowledgePointId: 'kp',
          level: 1,
          achievedAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
    });
  });
}
