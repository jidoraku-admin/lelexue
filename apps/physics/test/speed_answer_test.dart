import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_physics/core/speed_answer.dart';
import 'package:lelexue_physics/p2_speed_questions.dart';

void main() {
  group('平均速度判题：数值', () {
    test('标准答案通过', () {
      expect(judgeSpeedAnswer('0.30 m/s', 0.30), SpeedJudgement.correct);
      expect(judgeSpeedAnswer('0.3m/s', 0.30), SpeedJudgement.correct);
    });
    test('误差边界：±2% 内通过，超出不通过', () {
      expect(judgeSpeedAnswer('0.306 m/s', 0.30), SpeedJudgement.correct);
      expect(judgeSpeedAnswer('0.294 m/s', 0.30), SpeedJudgement.correct);
      expect(judgeSpeedAnswer('0.307 m/s', 0.30), SpeedJudgement.wrongValue);
      expect(judgeSpeedAnswer('0.293 m/s', 0.30), SpeedJudgement.wrongValue);
    });
    test('把 s 与 t 颠倒（t / s）判错', () {
      // 0.90 m、3.0 s：t / s ≈ 3.33
      expect(judgeSpeedAnswer('3.33 m/s', 0.30), SpeedJudgement.wrongValue);
    });
  });

  group('平均速度判题：单位', () {
    test('km/h 按 1 m/s = 3.6 km/h 换算后判定', () {
      expect(judgeSpeedAnswer('1.08 km/h', 0.30), SpeedJudgement.correct);
      expect(judgeSpeedAnswer('45 km/h', 12.5), SpeedJudgement.correct);
    });
    test('数值对但单位换错判为数值错误', () {
      // 0.30 m/s 写成 0.30 km/h
      expect(judgeSpeedAnswer('0.30 km/h', 0.30), SpeedJudgement.wrongValue);
    });
    test('中文单位可识别', () {
      expect(judgeSpeedAnswer('0.5 米/秒', 0.5), SpeedJudgement.correct);
      expect(judgeSpeedAnswer('1.8 千米/时', 0.5), SpeedJudgement.correct);
    });
    test('非速度单位判为单位错误', () {
      expect(judgeSpeedAnswer('0.30 m', 0.30), SpeedJudgement.wrongUnit);
      expect(judgeSpeedAnswer('0.30 s', 0.30), SpeedJudgement.wrongUnit);
      expect(judgeSpeedAnswer('0.30 s/m', 0.30), SpeedJudgement.wrongUnit);
    });
    test('缺少单位单独提示', () {
      expect(judgeSpeedAnswer('0.30', 0.30), SpeedJudgement.missingUnit);
    });
    test('无法识别的输入', () {
      expect(judgeSpeedAnswer('', 0.30), SpeedJudgement.unparsable);
      expect(judgeSpeedAnswer('m/s', 0.30), SpeedJudgement.unparsable);
    });
  });

  group('P2 题目', () {
    test('共 5 道，标准答案（m/s）均能通过', () {
      expect(p2SpeedQuestions.length, 5);
      for (final q in p2SpeedQuestions) {
        expect(q.judge('${q.trueSpeedMps} m/s'), SpeedJudgement.correct);
      }
    });
    test('标准答案数值', () {
      expect(p2SpeedQuestions.map((q) => q.trueSpeedMps).toList(),
          [closeTo(0.5, 1e-9), closeTo(0.3, 1e-9), closeTo(0.2, 1e-9), closeTo(0.5, 1e-9), closeTo(12.5, 1e-9)]);
    });
  });
}
