// 第一章 P1：刻度尺与停表读数的判定（纯 Dart，无界面依赖）。
//
// 教材依据：人教版八年级上册第一章第 1 节（长度和时间的测量）。
// 题目与数值为原创，不入库教材原文。

/// 刻度尺的分度值（cm）。1 mm。
const double rulerDivisionCm = 0.1;

/// 估读容差（cm）：允许最后一位估读误差，即 0.02 cm。
/// 数值由物理学科自定（#16 v0.11 决定：数值学科自定）。
const double rulerToleranceCm = 0.02;

/// 停表秒表盘的分度值（s）。0.1 s。
const double stopwatchDivisionSec = 0.1;

/// 判定刻度尺的长度读数是否正确。
///
/// [answerCm] 为学生读出的长度，[trueCm] 为物体真实长度（cm）。
bool isCorrectRulerLength(double answerCm, double trueCm) {
  return (answerCm - trueCm).abs() <= rulerToleranceCm + 1e-9;
}

/// 判定停表读数是否正确。
///
/// 读数 = 小表盘分钟数 × 60 + 大表盘秒数。误差不超过半个分度值。
bool isCorrectStopwatch(double answerSec, double trueSec) {
  return (answerSec - trueSec).abs() <= stopwatchDivisionSec / 2 + 1e-9;
}

/// 把停表两表盘读数合成为总秒数。
double stopwatchTotalSeconds({required int minutes, required double seconds}) {
  if (minutes < 0) {
    throw ArgumentError.value(minutes, 'minutes', 'must not be negative');
  }
  if (seconds < 0 || seconds >= 60) {
    throw ArgumentError.value(seconds, 'seconds', 'must be in [0, 60)');
  }
  return minutes * 60 + seconds;
}
