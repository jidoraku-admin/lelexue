import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/content/question.dart';
import 'package:lelexue_chemistry/scoring/review_selection.dart';

const _kp = 'chemistry.g9.v1.u02.k001';
const _other = 'chemistry.g9.v1.u02.k002';

Question _q(String id, String kp) => Question(
      id: id,
      knowledgePointId: kp,
      level: 2,
      prompt: '题目 $id',
      options: const ['甲', '乙'],
      answerIndex: 0,
      explanation: '解释',
    );

void main() {
  test('选取同一知识点、id 不同于 2★ 题目的复习题', () {
    final pool = [_q('a', _kp), _q('b', _kp), _q('c', _other)];
    final picked = pickReviewQuestion(
      pool: pool,
      knowledgePointId: _kp,
      twoStarQuestionId: 'a',
    );
    expect(picked?.id, 'b');
  });

  test('不会选到其他知识点的题目', () {
    final pool = [_q('a', _kp), _q('c', _other)];
    expect(
      pickReviewQuestion(pool: pool, knowledgePointId: _kp, twoStarQuestionId: 'a'),
      isNull,
    );
  });

  test('题库没有第二道题时返回 null，且 3★ 不可启用', () {
    final pool = [_q('a', _kp)];
    expect(
      pickReviewQuestion(pool: pool, knowledgePointId: _kp, twoStarQuestionId: 'a'),
      isNull,
    );
    expect(
      canEnableThreeStar(pool: pool, knowledgePointId: _kp, twoStarQuestionId: 'a'),
      isFalse,
    );
  });

  test('有第二道题时可启用 3★', () {
    final pool = [_q('a', _kp), _q('b', _kp)];
    expect(
      canEnableThreeStar(pool: pool, knowledgePointId: _kp, twoStarQuestionId: 'a'),
      isTrue,
    );
  });

  test('不复用原题：2★ 题目本身永远不会被选为复习题', () {
    final pool = [_q('a', _kp), _q('a2', _kp)];
    for (var i = 0; i < 3; i++) {
      final picked = pickReviewQuestion(
        pool: pool,
        knowledgePointId: _kp,
        twoStarQuestionId: 'a',
      );
      expect(picked?.id == 'a', isFalse);
    }
  });
}
