import 'question.dart';

/// 首个切片的题目（第二单元「空气和氧气」）。原创题干。
///
/// E1 对应 chemistry.g9.v1.u02.k001（氧气收集方法）
/// E3 对应 chemistry.g9.v1.u02.k003（氧气检验，现象预测）
/// E2（k002）待项目总监决定，本文件不含。
final List<Question> e1Questions = [
  Question(
    id: 'e1-q1',
    knowledgePointId: 'chemistry.g9.v1.u02.k001',
    level: 1,
    prompt: '收集较纯净的氧气，最好选择哪种方法？',
    options: ['排水法', '向上排空气法', '向下排空气法'],
    answerIndex: 0,
    explanation: '氧气不易溶于水，用排水法收集得到的气体较纯净。',
  ),
  Question(
    id: 'e1-q2',
    knowledgePointId: 'chemistry.g9.v1.u02.k001',
    level: 1,
    prompt: '用排水法收集氧气，什么时候开始收集？',
    options: ['刚开始冒出气泡时', '导管口有连续均匀气泡冒出时', '集气瓶装满水后'],
    answerIndex: 1,
    explanation: '刚开始排出的是装置内的空气，等导管口有连续均匀的气泡再收集。',
  ),
  Question(
    id: 'e1-q3',
    knowledgePointId: 'chemistry.g9.v1.u02.k001',
    level: 1,
    prompt: '用向上排空气法收集氧气时，怎样验满？',
    options: ['将带火星的木条放在集气瓶口，木条复燃', '将燃着的木条伸入集气瓶底部', '闻气味'],
    answerIndex: 0,
    explanation: '氧气能使带火星的木条复燃，验满要把木条放在瓶口，而不是伸入瓶中。',
  ),
];

final List<Question> e3Questions = [
  Question(
    id: 'e3-q1',
    knowledgePointId: 'chemistry.g9.v1.u02.k003',
    level: 1,
    prompt: '预测：把带火星的木条伸入一瓶无色气体，木条复燃。该气体最可能是？',
    options: ['氧气', '氮气', '二氧化碳'],
    answerIndex: 0,
    explanation: '能使带火星的木条复燃的气体是氧气。',
  ),
  Question(
    id: 'e3-q2',
    knowledgePointId: 'chemistry.g9.v1.u02.k003',
    level: 1,
    prompt: '预测：把燃着的木条伸入一瓶氮气中，木条的现象是？',
    options: ['木条熄灭', '木条燃烧更旺', '木条没有变化'],
    answerIndex: 0,
    explanation: '氮气不燃烧也不支持燃烧，燃着的木条会熄灭。',
  ),
  Question(
    id: 'e3-q3',
    knowledgePointId: 'chemistry.g9.v1.u02.k003',
    level: 1,
    prompt: '预测：把燃着的木条伸入一瓶空气中，木条的现象是？',
    options: ['燃烧更旺', '木条继续燃烧但不如在氧气中剧烈', '立刻变成蓝色火焰'],
    answerIndex: 1,
    explanation: '空气中氧气含量约21%，木条能继续燃烧，但不如在纯氧中剧烈。',
  ),
];
