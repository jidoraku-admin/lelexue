import 'unit.dart';

/// 一次关卡挑战（v0.16 §2.3）。
/// 答错时保留在本题并给出讲解，直到选中正确选项才进入下一题；
/// 得分只统计每题首次作答即正确的题目。
class LevelRun {
  LevelRun(this.level);

  final Level level;
  int index = 0;
  int firstTryCorrect = 0;
  final List<Question> missed = [];
  bool lastCorrect = false;
  int? lastChoice;
  String? feedback;
  bool _wrongOnCurrent = false;

  Question get current => level.questions[index];
  bool get finished => index >= level.questions.length;

  /// 作答当前题。返回是否正确。
  bool answer(int choice) {
    final q = current;
    final ok = choice == q.answer;
    lastChoice = choice;
    lastCorrect = ok;
    if (ok) {
      if (!_wrongOnCurrent) firstTryCorrect++;
      feedback = '正确！';
    } else {
      if (!_wrongOnCurrent) missed.add(q);
      _wrongOnCurrent = true;
      feedback = q.explanation;
    }
    return ok;
  }

  /// 正确后进入下一题。
  void next() {
    if (!lastCorrect) return;
    index++;
    lastCorrect = false;
    lastChoice = null;
    feedback = null;
    _wrongOnCurrent = false;
  }

  double get score =>
      level.questions.isEmpty ? 0 : firstTryCorrect / level.questions.length;

  int get percent => (score * 100).round();

  bool get passed => score >= level.passRate;

  /// 星级：达到通过线为 1 星，80% 以上 2 星，满分 3 星；未通过为 0。
  int get stars {
    if (!passed) return 0;
    if (score >= 1) return 3;
    if (score >= 0.8) return 2;
    return 1;
  }
}
