import 'question.dart';

/// 首个切片的题目（第二单元「空气和氧气」）。原创题干。
///
/// E1 对应 chemistry.g9.v1.u02.k001（氧气收集方法）
/// E2 对应 chemistry.g9.v1.u02.k002（过氧化氢制氧，二氧化锰作催化剂）。
///   第一版为学科内「选择条件、预测现象、看真实结果」，框架第二批上线后改为拖拽组装（#197）。
/// E3 对应 chemistry.g9.v1.u02.k003（氧气检验，现象预测）
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

/// E2 每一步都显示的安全提示（设计稿第 3 节安全红线）。
const String e2SafetyNotice = '注意滴加速度，防止冲出';

final List<Question> e2Questions = [
  Question(
    id: 'e2-q1',
    knowledgePointId: 'chemistry.g9.v1.u02.k002',
    level: 1,
    prompt: '条件：向盛有少量二氧化锰的试管中滴加过氧化氢溶液。预测会看到什么现象？',
    options: ['迅速产生大量气泡', '没有任何变化', '溶液立即变成蓝色'],
    answerIndex: 0,
    explanation: '真实结果：迅速产生气泡。二氧化锰能加快过氧化氢分解，放出氧气。',
  ),
  Question(
    id: 'e2-q2',
    knowledgePointId: 'chemistry.g9.v1.u02.k002',
    level: 1,
    prompt: '条件：常温下，试管中只有过氧化氢溶液，不加二氧化锰。预测现象是？',
    options: ['迅速产生大量气泡', '只有很少的气泡，带火星的木条不能复燃', '溶液剧烈沸腾'],
    answerIndex: 1,
    explanation: '真实结果：常温下过氧化氢分解很慢，产生的氧气很少，带火星的木条难以复燃。',
  ),
  Question(
    id: 'e2-q3',
    knowledgePointId: 'chemistry.g9.v1.u02.k002',
    level: 1,
    prompt: '过氧化氢溶液制氧时，二氧化锰的作用是什么？',
    options: ['提供氧气', '改变反应速率', '与过氧化氢反应生成氧气', '不影响反应'],
    answerIndex: 1,
    explanation: '二氧化锰是催化剂，只改变（这里是加快）反应速率，本身不提供氧气。',
  ),
  Question(
    id: 'e2-q4',
    knowledgePointId: 'chemistry.g9.v1.u02.k002',
    level: 1,
    prompt: '预测：反应结束后，把二氧化锰过滤、洗涤、干燥再称量，它的质量和化学性质会怎样？',
    options: ['质量减少，性质改变', '质量和化学性质都不变', '质量增加，性质不变'],
    answerIndex: 1,
    explanation: '真实结果：催化剂在反应前后质量和化学性质都不变，可以再次使用。',
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
