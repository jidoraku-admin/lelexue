// 第一章 P1 的题目（原创，共 5 题，用于 1★ 判定）。
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

/// 停表题：学生分别输入小表盘的分钟数与大表盘的秒数。
class StopwatchQuestion extends SliceQuestion {
  const StopwatchQuestion(super.prompt, {required this.trueSeconds});
  final double trueSeconds;
}

const List<SliceQuestion> firstSliceQuestions = [
  RulerQuestion('灯灯：赛车的车身从刻度 1.00 cm 对到 3.45 cm，车身有多长？',
      startCm: 1.00, endCm: 3.45),
  StopwatchQuestion('灯灯：计时器显示小表盘 1 分钟，大表盘 23.4 秒，总时间是多少？',
      trueSeconds: 83.4),
  RulerQuestion('灯灯：纸条的左端在 0.50 cm，右端在 6.20 cm，纸条有多长？',
      startCm: 0.50, endCm: 6.20),
  StopwatchQuestion('灯灯：小表盘 0 分钟，大表盘 47.2 秒，总时间是多少？',
      trueSeconds: 47.2),
  RulerQuestion('灯灯：螺丝的左端在 4.10 cm，右端在 5.75 cm，螺丝长多少？',
      startCm: 4.10, endCm: 5.75),
];

/// 判定一题的作答是否正确。
bool judgeQuestion(SliceQuestion q, {double? answerCm, double? answerSec}) {
  if (q is RulerQuestion) {
    return answerCm != null && isCorrectRulerLength(answerCm, q.trueLengthCm);
  }
  if (q is StopwatchQuestion) {
    return answerSec != null && isCorrectStopwatch(answerSec, q.trueSeconds);
  }
  return false;
}
