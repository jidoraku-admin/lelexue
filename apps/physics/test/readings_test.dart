import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_physics/core/readings.dart';
import 'package:lelexue_physics/first_slice_questions.dart';
import 'package:lelexue_physics/mastery/mastery_draft.dart';

void main() {
  group('刻度尺读数判定', () {
    test('正确读数在容差内通过', () {
      expect(isCorrectRulerLength(2.45, 2.45), isTrue);
      expect(isCorrectRulerLength(2.46, 2.45), isTrue);
      expect(isCorrectRulerLength(2.47, 2.45), isTrue);
      expect(isCorrectRulerLength(2.48, 2.45), isFalse);
    });
  });

  group('停表读数判定', () {
    test('总秒数合成', () {
      expect(stopwatchTotalSeconds(minutes: 1, seconds: 23.4), closeTo(83.4, 1e-9));
      expect(() => stopwatchTotalSeconds(minutes: 0, seconds: 60), throwsArgumentError);
    });
    test('误差不超过半个分度值', () {
      expect(isCorrectStopwatch(83.4, 83.4), isTrue);
      expect(isCorrectStopwatch(83.45, 83.4), isTrue);
      expect(isCorrectStopwatch(83.6, 83.4), isFalse);
    });
  });

  group('题目判定', () {
    test('每道题的标准答案能通过判定', () {
      for (final q in firstSliceQuestions) {
        if (q is RulerQuestion) {
          expect(judgeQuestion(q, answerCm: q.trueLengthCm), isTrue);
        } else if (q is StopwatchQuestion) {
          expect(judgeQuestion(q, answerSec: q.trueSeconds), isTrue);
        }
      }
    });
    test('题目共 5 道', () {
      expect(firstSliceQuestions.length, 5);
    });
  });

  group('掌握度草稿（物理 1★）', () {
    test('草稿不含 eventId，subject 固定为 physics', () {
      final d = buildLevel1Draft(
        knowledgePointId: 'physics.g8.v1.u01.k001',
        results: [true, true, true, true, true],
      );
      expect(d.subject.wireName, 'physics');
      expect(d.level, 1);
      expect(d.meetsLevel1Rule, isTrue);
    });
    test('不足 5 题不满足 1★', () {
      final d = buildLevel1Draft(
        knowledgePointId: 'physics.g8.v1.u01.k001',
        results: [true, true, true, true],
      );
      expect(d.meetsLevel1Rule, isFalse);
    });
    test('正确率低于 80% 不满足 1★', () {
      final d = buildLevel1Draft(
        knowledgePointId: 'physics.g8.v1.u01.k001',
        results: [true, true, true, false, false],
      );
      expect(d.accuracy, closeTo(0.6, 1e-9));
      expect(d.meetsLevel1Rule, isFalse);
    });
    test('knowledgePointId 格式非法时拒绝', () {
      expect(
        () => buildLevel1Draft(knowledgePointId: 'english.g8.v1.u01.k001', results: const []),
        throwsArgumentError,
      );
    });
  });
}
