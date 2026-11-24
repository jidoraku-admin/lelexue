import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_english/domain/knowledge_points.dart';
import 'package:lelexue_english/domain/knowledge_status.dart';
import 'package:lelexue_english/domain/progress.dart';

void main() {
  test('知识点清单与 docs/data 的知识点文件一致', () {
    final json = jsonDecode(
      File('../../docs/data/english-g3a-knowledge-points.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final source = (json['units'] as Map)['Unit 1'] as List;
    expect(unit1KnowledgePoints.length, source.length);
    for (var i = 0; i < source.length; i++) {
      final s = source[i] as Map<String, dynamic>;
      expect(unit1KnowledgePoints[i].id, s['id']);
      expect(unit1KnowledgePoints[i].name, s['name']);
      expect(unit1KnowledgePoints[i].pattern, s['pattern']);
    }
  });

  QuestionAttempt a(String kp, bool ok, {String type = 'use'}) =>
      QuestionAttempt(
        questionId: 'q',
        knowledgePointId: kp,
        levelId: 'use-1',
        correct: ok,
        answeredAt: DateTime.utc(2026, 11, 23),
        itemType: type,
      );

  test('未开始、进行中、已掌握三种状态；只统计应用题', () {
    final statuses = knowledgeStatus(
      points: unit1KnowledgePoints,
      attempts: [
        a(unit1KnowledgePoints[0].id, true),
        a(unit1KnowledgePoints[0].id, false),
        a(unit1KnowledgePoints[1].id, true, type: 'sentence'),
      ],
      mastered: {'${unit1KnowledgePoints[2].id}#2'},
    );
    expect(statuses[0].state, KpState.inProgress);
    expect(statuses[0].correct, 1);
    expect(statuses[0].total, 2);
    expect(statuses[1].state, KpState.notStarted);
    expect(statuses[2].state, KpState.mastered2);
    expect(statuses[2].label, '已掌握（2★）');
  });
}
