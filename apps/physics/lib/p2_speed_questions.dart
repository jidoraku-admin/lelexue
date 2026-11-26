// 第一章 P2「测量小车的平均速度」题目（原创，共 5 题，用于 1★ 判定）。
//
// 教材依据：人教版八年级上册第一章第 4 节 p.32「测量小车运动的速度」：
// 用刻度尺测路程、停表测时间，由 v = s / t 求平均速度。
// 题目与数值为原创，不入库教材原文。
import 'core/speed_answer.dart';

/// 平均速度数值题：给出路程与时间，学生输入「数值 + 单位」。
class SpeedQuestion {
  const SpeedQuestion(this.prompt, {required this.distanceM, required this.timeS});
  final String prompt;
  final double distanceM;
  final double timeS;

  /// 标准答案（m/s）：v = s / t。
  double get trueSpeedMps => distanceM / timeS;

  SpeedJudgement judge(String input) => judgeSpeedAnswer(input, trueSpeedMps);
}

const List<SpeedQuestion> p2SpeedQuestions = [
  SpeedQuestion('灯灯：一辆小车 10 s 内通过 5 m 路程，它的平均速度是多少？',
      distanceM: 5, timeS: 10),
  SpeedQuestion('灯灯：小车从斜面顶端滑到底端，路程 0.90 m，用时 3.0 s，全程的平均速度是多少？',
      distanceM: 0.90, timeS: 3.0),
  SpeedQuestion('灯灯：小车通过斜面上半段，路程 0.40 m，用时 2.0 s，这段的平均速度是多少？',
      distanceM: 0.40, timeS: 2.0),
  SpeedQuestion('灯灯：小车通过斜面下半段，路程 0.50 m，用时 1.0 s，这段的平均速度是多少？',
      distanceM: 0.50, timeS: 1.0),
  SpeedQuestion('灯灯：赛车在赛道上跑完 100 m，停表显示 8.0 s，赛车的平均速度是多少？',
      distanceM: 100, timeS: 8.0),
];
