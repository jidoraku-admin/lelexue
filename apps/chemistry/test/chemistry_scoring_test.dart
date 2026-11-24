import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/scoring/chemistry_scoring.dart';
import 'package:shared/core/core.dart';

const _kp = 'chemistry.g9.v1.u02.k001';
const _interval = Duration(hours: 24);

void main() {
  final user = UserId('u-test-1');
  final at = DateTime.utc(2026, 11, 22, 12);

  ChemistryScoring newScoring() => ChemistryScoring(userId: user, reviewInterval: _interval);

  bool answer(ChemistryScoring s, bool correct, {int level = 1, bool newContext = false, DateTime? when}) =>
      s.recordAnswer(
        knowledgePointId: _kp,
        level: level,
        correct: correct,
        answeredAt: when ?? at,
        newContext: newContext,
      );

  /// 把 2★ 推到 [at]，用于后续 3★ 测试。
  ChemistryScoring reachTwoStar() {
    final s = newScoring();
    for (var i = 0; i < 5; i++) {
      answer(s, true, level: 2);
    }
    s.drainPendingMastery();
    return s;
  }

  test('4 题全对不足 5 题，不掌握', () {
    final s = newScoring();
    for (var i = 0; i < 4; i++) {
      expect(answer(s, true), isFalse);
    }
    expect(s.drainPendingMastery(), isEmpty);
  });

  test('5 题 4 对（80%）达到 1★，产生一条草稿', () {
    final s = newScoring();
    final results = [true, true, false, true, true];
    late bool reached;
    for (final r in results) {
      reached = answer(s, r);
    }
    expect(reached, isTrue);
    final drafts = s.drainPendingMastery();
    expect(drafts, hasLength(1));
    expect(drafts.single.knowledgePointId, _kp);
    expect(drafts.single.level, 1);
    expect(drafts.single.subject, SubjectCode.chemistry);
    expect(drafts.single.achievedAt.isUtc, isTrue);
  });

  test('5 题 3 对（60%）不达标', () {
    final s = newScoring();
    for (final r in [true, true, false, true, false]) {
      answer(s, r);
    }
    expect(s.drainPendingMastery(), isEmpty);
  });

  test('同一 (知识点, 等级) 只计一次，之后作答不再产生草稿', () {
    final s = newScoring();
    for (var i = 0; i < 5; i++) {
      answer(s, true);
    }
    expect(s.drainPendingMastery(), hasLength(1));
    for (var i = 0; i < 5; i++) {
      expect(answer(s, true), isFalse);
    }
    expect(s.drainPendingMastery(), isEmpty);
  });

  test('不同等级互不影响', () {
    final s = newScoring();
    for (var i = 0; i < 5; i++) {
      answer(s, true, level: 1);
    }
    for (var i = 0; i < 5; i++) {
      answer(s, true, level: 2);
    }
    final drafts = s.drainPendingMastery();
    expect(drafts.map((d) => d.level), [1, 2]);
  });

  test('非法知识点 id 被拒绝', () {
    final s = newScoring();
    expect(
      () => s.recordAnswer(knowledgePointId: 'english.g3.v1.u01.k001', level: 1, correct: true, answeredAt: at),
      throwsArgumentError,
    );
  });

  test('level 小于 1 被拒绝', () {
    final s = newScoring();
    expect(() => answer(s, true, level: 0), throwsArgumentError);
  });

  test('3★ 作答必须是新语境，否则拒绝', () {
    final s = reachTwoStar();
    expect(() => answer(s, true, level: 3, newContext: false), throwsArgumentError);
  });

  test('3★ 只有新语境正确率达标，没有间隔复习通过时不掌握', () {
    final s = reachTwoStar();
    for (var i = 0; i < 5; i++) {
      answer(s, true, level: 3, newContext: true);
    }
    expect(s.drainPendingMastery(), isEmpty);
  });

  test('3★ 间隔复习未满 reviewInterval 时不计，满后答对才计', () {
    final s = reachTwoStar();
    // 过早答对：不计
    expect(
      s.recordReview(knowledgePointId: _kp, correct: true, answeredAt: at.add(const Duration(hours: 1))),
      isFalse,
    );
    // 满间隔后答错：不计
    expect(
      s.recordReview(knowledgePointId: _kp, correct: false, answeredAt: at.add(_interval)),
      isFalse,
    );
    // 满间隔后答对：通过一次
    expect(
      s.recordReview(knowledgePointId: _kp, correct: true, answeredAt: at.add(_interval)),
      isFalse, // 新语境题还没达标，只是复习通过
    );
    for (var i = 0; i < 5; i++) {
      answer(s, true, level: 3, newContext: true, when: at.add(_interval));
    }
    final drafts = s.drainPendingMastery();
    expect(drafts.map((d) => d.level), [3]);
  });

  test('3★ 两个条件同时满足时，无论先后，在第二个条件满足时产生草稿', () {
    final s = reachTwoStar();
    s.recordReview(knowledgePointId: _kp, correct: true, answeredAt: at.add(_interval));
    late bool reached;
    for (var i = 0; i < 5; i++) {
      reached = answer(s, true, level: 3, newContext: true, when: at.add(_interval));
    }
    expect(reached, isTrue);
    expect(s.drainPendingMastery().single.level, 3);
  });

  test('2★ 未达到时，间隔复习不计', () {
    final s = newScoring();
    expect(
      s.recordReview(knowledgePointId: _kp, correct: true, answeredAt: at.add(_interval)),
      isFalse,
    );
  });
}
