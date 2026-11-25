// 第一章 P1：刻度尺读数的判定（纯 Dart，无界面依赖）。
//
// 教材依据：人教版八年级上册第一章第 1 节（长度和时间的测量）。
// 题目与数值为原创，不入库教材原文。

/// 刻度尺的分度值（cm）。1 mm。
const double rulerDivisionCm = 0.1;

/// 估读容差（cm）：允许最后一位估读误差，即 0.02 cm。
/// 数值由物理学科自定（#16 v0.11 决定：数值学科自定）。
const double rulerToleranceCm = 0.02;

/// 判定刻度尺的长度读数是否正确。
///
/// [answerCm] 为学生读出的长度，[trueCm] 为物体真实长度（cm）。
bool isCorrectRulerLength(double answerCm, double trueCm) {
  return (answerCm - trueCm).abs() <= rulerToleranceCm + 1e-9;
}
