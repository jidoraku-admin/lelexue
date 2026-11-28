// 数学掌握度草稿（学科适配层，#3 F5）。
//
// 记录每个知识点的作答结果；达到 1★ 规则时给出草稿，交数据平台发布。
// 不生成 eventId、不计经验（经验只来自数据平台发布的掌握事件，见 F7）。
import 'package:shared/core/core.dart';

import '../unit01/judge.dart' show isValidKnowledgePointId;
import 'mastery_rules.dart';

class MasteryDraft {
  const MasteryDraft({
    required this.knowledgePointId,
    required this.level,
    required this.attempts,
    required this.correct,
  });

  /// 固定为 math；与 SubjectCode 一致。
  SubjectCode get subject => SubjectCode.math;
  final String knowledgePointId;
  final int level;
  final int attempts;
  final int correct;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// 按知识点累计作答，判断 1★。
class MasteryTracker {
  MasteryTracker({this.rule = mathLevel1Rule});

  final MasteryRuleDecl rule;
  final Map<String, List<bool>> _results = {};
  final Set<String> _drafted = {};

  /// 记录一次作答。knowledgePointId 不合法时抛出 [ArgumentError]。
  void record(String knowledgePointId, bool correct) {
    if (!isValidKnowledgePointId(knowledgePointId)) {
      throw ArgumentError.value(knowledgePointId, 'knowledgePointId',
          'must follow math.g<grade>.v<volume>.u<unit>.k<seq>');
    }
    (_results[knowledgePointId] ??= []).add(correct);
  }

  int attemptsOf(String id) => _results[id]?.length ?? 0;
  int correctOf(String id) => _results[id]?.where((r) => r).length ?? 0;

  /// 全部知识点的合计（结算页展示用）。
  int get totalAttempts =>
      _results.values.fold(0, (sum, r) => sum + r.length);
  int get totalCorrect =>
      _results.values.fold(0, (sum, r) => sum + r.where((x) => x).length);

  bool meetsRule(String id) =>
      rule.isMetBy(attempts: attemptsOf(id), correct: correctOf(id));

  /// 新达到规则的知识点草稿；同一知识点同一级别只给一次。
  List<MasteryDraft> takeNewDrafts() {
    final drafts = <MasteryDraft>[];
    for (final id in _results.keys) {
      if (_drafted.contains(id) || !meetsRule(id)) continue;
      _drafted.add(id);
      drafts.add(MasteryDraft(
        knowledgePointId: id,
        level: rule.level,
        attempts: attemptsOf(id),
        correct: correctOf(id),
      ));
    }
    return drafts;
  }
}
