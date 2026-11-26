// 第一章 P2：平均速度数值题的判题（纯 Dart，无界面依赖）。
//
// 教材依据：人教版八年级上册第一章第 3 节（运动的快慢，v = s / t，
// 速度单位 m/s、km/h）与第 4 节 p.32（测量小车运动的速度）。
// 题目模型由物理在 apps/physics 内自定（#5 项目总监决定，2026-11-26）。

/// 速度单位。
enum SpeedUnit {
  metersPerSecond(1.0),
  kilometersPerHour(1 / 3.6);

  const SpeedUnit(this.toMetersPerSecond);

  /// 换算到 m/s 的系数（1 km/h = 1/3.6 m/s）。
  final double toMetersPerSecond;
}

/// 判题结果。
enum SpeedJudgement {
  /// 数值与单位都正确。
  correct,

  /// 单位正确，数值超出允许误差。
  wrongValue,

  /// 写了单位，但不是速度单位（如 m、s）。
  wrongUnit,

  /// 只写了数字，没有单位。
  missingUnit,

  /// 无法识别为「数字 + 单位」。
  unparsable,
}

/// 允许的相对误差：2%（物理学科自定，小事）。
/// 例如标准答案 0.30 m/s 时，0.294–0.306 m/s 判为正确。
const double speedRelativeTolerance = 0.02;

final RegExp _answerPattern = RegExp(r'^\s*([+-]?\d+(?:\.\d+)?)\s*(.*?)\s*$');

/// 把单位文本规范化后识别为速度单位；不是速度单位时返回 null。
SpeedUnit? _parseSpeedUnit(String raw) {
  final u = raw
      .replaceAll(' ', '')
      .replaceAll('／', '/')
      .replaceAll('·', '')
      .toLowerCase();
  switch (u) {
    case 'm/s':
    case '米/秒':
    case '米每秒':
      return SpeedUnit.metersPerSecond;
    case 'km/h':
    case '千米/时':
    case '千米/小时':
    case '千米每时':
    case '千米每小时':
      return SpeedUnit.kilometersPerHour;
  }
  return null;
}

/// 判定学生输入的平均速度 [input]（如 "0.30 m/s"、"1.08 km/h"）
/// 是否等于标准答案 [trueMetersPerSecond]（单位 m/s）。
SpeedJudgement judgeSpeedAnswer(String input, double trueMetersPerSecond) {
  final match = _answerPattern.firstMatch(input);
  if (match == null) return SpeedJudgement.unparsable;
  final value = double.parse(match.group(1)!);
  final unitText = match.group(2)!;
  if (unitText.isEmpty) return SpeedJudgement.missingUnit;
  final unit = _parseSpeedUnit(unitText);
  if (unit == null) return SpeedJudgement.wrongUnit;
  final answerMps = value * unit.toMetersPerSecond;
  final allowed = trueMetersPerSecond.abs() * speedRelativeTolerance + 1e-9;
  return (answerMps - trueMetersPerSecond).abs() <= allowed
      ? SpeedJudgement.correct
      : SpeedJudgement.wrongValue;
}
