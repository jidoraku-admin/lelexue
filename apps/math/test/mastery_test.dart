import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_math/mastery/mastery_rules.dart';
import 'package:lelexue_math/mastery/mastery_tracker.dart';
import 'package:shared/core/core.dart';

const _kp = 'math.g3.v1.u01.k001';

void main() {
  test('1★ 规则与英语、物理一致：≥80% 且 ≥5 次', () {
    expect(mathLevel1Rule.level, 1);
    expect(mathLevel1Rule.minAccuracy, 0.8);
    expect(mathLevel1Rule.minAttempts, 5);
    expect(mathLevel1Rule.grantsExperience, isFalse);
    expect(mathMasteryRules, [mathLevel1Rule]);
  });

  test('不足 5 次时即使全对也不达标', () {
    final t = MasteryTracker();
    for (var i = 0; i < 4; i++) {
      t.record(_kp, true);
    }
    expect(t.meetsRule(_kp), isFalse);
    expect(t.takeNewDrafts(), isEmpty);
  });

  test('5 次答对 4 次（80%）达标，生成一次草稿', () {
    final t = MasteryTracker();
    for (final r in [true, false, true, true, true]) {
      t.record(_kp, r);
    }
    final drafts = t.takeNewDrafts();
    expect(drafts, hasLength(1));
    expect(drafts.single.subject, SubjectCode.math);
    expect(drafts.single.knowledgePointId, _kp);
    expect(drafts.single.level, 1);
    expect(drafts.single.attempts, 5);
    expect(drafts.single.correct, 4);
    t.record(_kp, true);
    expect(t.takeNewDrafts(), isEmpty, reason: '同一知识点同一级别只给一次');
  });

  test('5 次答对 3 次（60%）不达标', () {
    final t = MasteryTracker();
    for (final r in [true, false, true, false, true]) {
      t.record(_kp, r);
    }
    expect(t.meetsRule(_kp), isFalse);
  });

  test('知识点编号不合法时拒绝记录', () {
    expect(() => MasteryTracker().record('physics.g8.v1.u01.k001', true),
        throwsArgumentError);
  });

  test('合计按全部知识点累加', () {
    final t = MasteryTracker()
      ..record(_kp, true)
      ..record('math.g3.v1.u01.k002', false);
    expect(t.totalAttempts, 2);
    expect(t.totalCorrect, 1);
  });
}
