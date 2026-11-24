import '../content/question.dart';

/// 3★ 间隔复习题选取（总监决定 B，#6）。
///
/// 复习题必须与 2★ 作答的题目 id 不同，且属于同一知识点。
/// 题库中没有符合条件的第二道题时返回 null，此时 3★ 应保持关闭，不临时复用原题。
Question? pickReviewQuestion({
  required List<Question> pool,
  required String knowledgePointId,
  required String twoStarQuestionId,
}) {
  for (final q in pool) {
    if (q.knowledgePointId == knowledgePointId && q.id != twoStarQuestionId) {
      return q;
    }
  }
  return null;
}

/// 题库是否能支撑 3★：该知识点至少有一道与 2★ 题目不同的复习题。
bool canEnableThreeStar({
  required List<Question> pool,
  required String knowledgePointId,
  required String twoStarQuestionId,
}) =>
    pickReviewQuestion(
          pool: pool,
          knowledgePointId: knowledgePointId,
          twoStarQuestionId: twoStarQuestionId,
        ) !=
        null;
