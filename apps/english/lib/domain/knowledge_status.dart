import 'knowledge_points.dart';
import 'progress.dart';

/// 知识点的学情状态（应用题口径，与 2★ 掌握规则一致）。
enum KpState { notStarted, inProgress, mastered2 }

class KpStatus {
  const KpStatus({
    required this.point,
    required this.state,
    required this.correct,
    required this.total,
  });

  final KnowledgePoint point;
  final KpState state;

  /// 应用题首次作答的正确题数与题数。
  final int correct;
  final int total;

  String get label => switch (state) {
    KpState.notStarted => '未开始',
    KpState.inProgress => '进行中',
    KpState.mastered2 => '已掌握（2★）',
  };
}

/// 计算每个知识点的学情。只统计应用题（itemType = use）。
List<KpStatus> knowledgeStatus({
  required List<KnowledgePoint> points,
  required List<QuestionAttempt> attempts,
  required Set<String> mastered,
}) {
  return [
    for (final p in points)
      () {
        final use = attempts
            .where((a) => a.knowledgePointId == p.id && a.itemType == 'use')
            .toList();
        final correct = use.where((a) => a.correct).length;
        final state = mastered.contains('${p.id}#2')
            ? KpState.mastered2
            : use.isEmpty
            ? KpState.notStarted
            : KpState.inProgress;
        return KpStatus(
          point: p,
          state: state,
          correct: correct,
          total: use.length,
        );
      }(),
  ];
}
