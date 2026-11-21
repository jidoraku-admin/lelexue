/// 关卡挑战状态（v0.16 §2.3）：失败后可立即再挑战，不扣经验；
/// Boss 失败后标出薄弱项，补救通过后可再次挑战。
class LevelAttempt {
  LevelAttempt({required this.isBoss});

  final bool isBoss;
  int failures = 0;
  bool passed = false;
  bool needsRemediation = false;

  void recordFailure() {
    failures++;
    if (isBoss) needsRemediation = true;
  }

  void recordPass() {
    passed = true;
    needsRemediation = false;
  }

  /// 可以立即再挑战：未通过，且（非 Boss 或已完成补救）。
  bool get canRetry => !passed && !needsRemediation;

  /// 补救完成后调用，允许 Boss 再次挑战。
  void completeRemediation() {
    needsRemediation = false;
  }
}
