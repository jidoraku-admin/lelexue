import 'question.dart';

/// 第一单元「走进化学世界」的题目（学科内选择题，1★ 识别）。原创题干，不复制教材文字。
/// 草稿：题目上线前需真人审核（#23 审核第 5 条）。
///
/// U1A 对应 chemistry.g9.v1.u01.k001（物理变化与化学变化）
/// U1B 对应 chemistry.g9.v1.u01.k002（仪器与基本操作）
/// 第 4.0 节 k002 的安全提示，附在每道 U1B 题的解释之后。
const String u1bSafetyTip = '安全提示：加热试管时，液体不超过试管容积的三分之一，并注意加热安全。';

final List<Question> u1aQuestions = [
  Question(
    id: 'u1a-q1',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '下列变化中，属于化学变化的是？',
    options: ['冰雪融化', '纸张燃烧', '玻璃破碎'],
    answerIndex: 1,
    explanation: '纸张燃烧生成了新物质，属于化学变化；冰雪融化和玻璃破碎只是状态或形状改变。',
  ),
  Question(
    id: 'u1a-q2',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '下列描述中，属于化学性质的是？',
    options: ['酒精易挥发', '铁在潮湿空气中会生锈', '铜是紫红色固体'],
    answerIndex: 1,
    explanation: '需要通过化学变化才能表现出来的性质是化学性质，铁生锈就是铁与其他物质发生的化学变化。',
  ),
  Question(
    id: 'u1a-q3',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '下列描述中，属于物理性质的是？',
    options: ['氧气能支持燃烧', '镁能与盐酸反应', '水在常压下沸点是100℃'],
    answerIndex: 2,
    explanation: '沸点不需要发生化学变化就能观察到，属于物理性质；另两项都需要通过化学变化表现。',
  ),
  Question(
    id: 'u1a-q4',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '下列现象中，能说明发生了化学变化的是？',
    options: ['灯泡通电后发光放热', '食醋与小苏打混合后产生大量气泡', '瓶口出现白雾'],
    answerIndex: 1,
    explanation: '产生气体说明生成了新物质，是化学变化的重要标志；发光放热和白雾不一定有新物质生成。',
  ),
  Question(
    id: 'u1a-q5',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '下列过程中，没有新物质生成的是？',
    options: ['蜡烛燃烧', '牛奶变酸', '把湿衣服晾干'],
    answerIndex: 2,
    explanation: '湿衣服晾干只是水由液态变成气态，没有新物质生成，属于物理变化；燃烧和变酸都生成了新物质。',
  ),
  Question(
    id: 'u1a-q6',
    knowledgePointId: 'chemistry.g9.v1.u01.k001',
    level: 1,
    prompt: '判断一个变化是不是化学变化，最根本的依据是？',
    options: ['是否发光放热', '是否有新物质生成', '是否有颜色变化'],
    answerIndex: 1,
    explanation: '化学变化的本质特征是生成新物质；发光、放热、变色等现象只能帮助判断，不能作为根本依据。',
  ),
];

final List<Question> u1bQuestions = [
  Question(
    id: 'u1b-q1',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '可用作少量试剂的反应容器，常温或加热时都可使用的仪器是？',
    options: ['量筒', '试管', '漏斗'],
    answerIndex: 1,
    explanation: '试管可用作少量试剂的反应容器，常温或加热时使用。量筒不能加热，也不能作反应容器。\n$u1bSafetyTip',
  ),
  Question(
    id: 'u1b-q2',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '要量取一定体积的液体，应选用哪种仪器？',
    options: ['烧杯', '量筒', '试管'],
    answerIndex: 1,
    explanation: '量筒用于量取液体体积，量筒不能加热，也不能作反应容器。\n$u1bSafetyTip',
  ),
  Question(
    id: 'u1b-q3',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '用来固定和支持各种仪器的是？',
    options: ['铁架台', '滴瓶', '集气瓶'],
    answerIndex: 0,
    explanation: '铁架台用于固定和支持各种仪器，过滤、加热等操作常用它。\n$u1bSafetyTip',
  ),
  Question(
    id: 'u1b-q4',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '给试管里的液体加热时，液体体积一般不超过试管容积的多少？',
    options: ['三分之一', '二分之一', '全部'],
    answerIndex: 0,
    explanation: '液体过多在加热时容易沸腾溅出，所以一般不超过试管容积的三分之一。\n$u1bSafetyTip',
  ),
  Question(
    id: 'u1b-q5',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '用酒精灯给物质加热时，应该使用火焰的哪一部分？',
    options: ['外焰', '内焰', '焰心'],
    answerIndex: 0,
    explanation: '酒精灯外焰温度最高，加热时应使用外焰。\n$u1bSafetyTip',
  ),
  Question(
    id: 'u1b-q6',
    knowledgePointId: 'chemistry.g9.v1.u01.k002',
    level: 1,
    prompt: '熄灭酒精灯的正确方法是？',
    options: ['用嘴吹灭', '用灯帽盖灭', '用水浇灭'],
    answerIndex: 1,
    explanation: '用灯帽盖灭酒精灯，隔绝空气使火焰熄灭；不能用嘴吹，以免引起危险。\n$u1bSafetyTip',
  ),
];
