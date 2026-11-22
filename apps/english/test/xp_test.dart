import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/level_run.dart';
import 'package:lelexue_english/domain/progress.dart';
import 'package:lelexue_english/domain/unit.dart';
import 'package:lelexue_english/domain/xp.dart';

Progress _usePassed(String kp, int n, {int wrong = 0}) {
  final answers = <FirstAnswer>[
    for (var i = 0; i < n; i++)
      FirstAnswer(
        question: Question(
          id: 'u$kp$i',
          prompt: 'p',
          options: const ['a', 'b'],
          answer: 0,
          explanation: 'e',
          knowledgePointId: kp,
        ),
        correct: i >= wrong,
        stage: Stage.use,
      ),
  ];
  final p = Progress();
  p.recordAttempts('use-1', answers, DateTime.utc(2026, 11, 23));
  return p;
}

void main() {
  test('等级与升级所需经验', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(99), 1);
    expect(levelForXp(100), 2);
    expect(xpToNextLevel(0), 100);
    expect(xpToNextLevel(90), 10);
  });

  test('首次达到 2★ 获得一次经验，重复应用不再加', () {
    final p = _usePassed('english.g3.v1.u01.k001', 5);
    p.applyMastery(DateTime.utc(2026, 11, 23));
    p.applyMastery(DateTime.utc(2026, 11, 23, 1));
    expect(p.xp, xpPerMastery);
    expect(p.pendingAchievements.length, 1);
  });

  test('未达到门槛不获得经验（4/5 恰好达标，3/5 不达标）', () {
    final ok = _usePassed('english.g3.v1.u01.k002', 5, wrong: 1);
    ok.applyMastery(DateTime.utc(2026, 11, 23));
    expect(ok.xp, xpPerMastery);

    final low = _usePassed('english.g3.v1.u01.k003', 5, wrong: 2);
    low.applyMastery(DateTime.utc(2026, 11, 23));
    expect(low.xp, 0);
  });

  test('经验随进度持久化，旧数据读取为 0', () {
    final p = _usePassed('english.g3.v1.u01.k004', 5);
    p.applyMastery(DateTime.utc(2026, 11, 23));
    final restored = Progress.fromJson(p.toJson());
    expect(restored.xp, xpPerMastery);

    final legacy = Progress.fromJson({'stars': {}, 'missed': <String>[]});
    expect(legacy.xp, 0);
  });
}
