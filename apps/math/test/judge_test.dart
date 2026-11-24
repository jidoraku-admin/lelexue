import 'package:flutter_test/flutter_test.dart';
import 'package:lelexue_math/unit01/judge.dart';

void main() {
  const item = Unit01Item(
    id: 'math.g3.v1.u01.k002',
    game: 'observe_choice',
    prompt: '从左边看，看到几个方块？',
    answer: '2',
    distractors: ['1', '3'],
  );

  test('正确答案判为正确', () {
    expect(judgeChoice(item, '2'), isTrue);
  });

  test('干扰项判为错误', () {
    expect(judgeChoice(item, '1'), isFalse);
    expect(judgeChoice(item, '3'), isFalse);
  });

  test('非选项的作答判为错误', () {
    expect(judgeChoice(item, '5'), isFalse);
  });

  test('knowledgePointId 格式校验', () {
    expect(isValidKnowledgePointId('math.g3.v1.u01.k001'), isTrue);
    expect(isValidKnowledgePointId('math.g3.v1.u1.k1'), isFalse);
    expect(isValidKnowledgePointId('english.g3.v1.u01.k001'), isFalse);
  });
}
