import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_chemistry/scoring/chemistry_scoring.dart';
import 'package:shared/core/core.dart';

const _kp = 'chemistry.g9.v1.u02.k001';

void main() {
  final user = UserId('u-test-1');
  final at = DateTime.utc(2026, 11, 22, 12);

  ChemistryScoring newScoring() => ChemistryScoring(userId: user);

  bool answer(ChemistryScoring s, bool correct, {int level = 1}) => s.recordAnswer(
        knowledgePointId: _kp,
        level: level,
        correct: correct,
        answeredAt: at,
      );

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

  test('3★ 尚未支持', () {
    final s = newScoring();
    expect(() => answer(s, true, level: 3), throwsUnsupportedError);
  });
}
