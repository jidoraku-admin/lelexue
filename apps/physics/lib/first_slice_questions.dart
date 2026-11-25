// 第一章 P1 的题目（原创，共 5 题，用于 1★ 判定）。
//
// 停表题已移除：「停表小表盘读分钟、大表盘读秒」在教材原页未找到依据，
// 按 #5 总监决定（2026-11-24）不进入题库、不上线。
import 'core/readings.dart';

sealed class SliceQuestion {
  const SliceQuestion(this.prompt);
  final String prompt;
}

/// 刻度尺题：学生在 0–10 cm 刻度尺上点选物体左右两端，读出长度。
class RulerQuestion extends SliceQuestion {
  const RulerQuestion(super.prompt, {required this.startCm, required this.endCm});
  final double startCm;
  final double endCm;
  double get trueLengthCm => endCm - startCm;
}

const List<SliceQuestion> firstSliceQuestions = [
  RulerQuestion('灯灯：赛车的车身从刻度 1.00 cm 对到 3.45 cm，车身有多长？',
      startCm: 1.00, endCm: 3.45),
  RulerQuestion('灯灯：铅笔头从刻度 2.00 cm 对到 8.65 cm，铅笔头这段有多长？',
      startCm: 2.00, endCm: 8.65),
  RulerQuestion('灯灯：纸条的左端在 0.50 cm，右端在 6.20 cm，纸条有多长？',
      startCm: 0.50, endCm: 6.20),
  RulerQuestion('灯灯：橡皮的左端在 3.30 cm，右端在 7.05 cm，橡皮有多长？',
      startCm: 3.30, endCm: 7.05),
  RulerQuestion('灯灯：螺丝的左端在 4.10 cm，右端在 5.75 cm，螺丝长多少？',
      startCm: 4.10, endCm: 5.75),
];

/// 判定一题的作答是否正确。
bool judgeQuestion(SliceQuestion q, {double? answerCm}) {
  if (q is RulerQuestion) {
    return answerCm != null && isCorrectRulerLength(answerCm, q.trueLengthCm);
  }
  return false;
}
