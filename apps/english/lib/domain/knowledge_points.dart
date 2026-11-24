/// 英语第 1 单元知识点（与 docs/data/english-g3a-knowledge-points.json 一致，见 #95）。
library;

class KnowledgePoint {
  const KnowledgePoint({
    required this.id,
    required this.name,
    required this.pattern,
  });

  final String id;
  final String name;
  final String pattern;
}

const unit1KnowledgePoints = <KnowledgePoint>[
  KnowledgePoint(
    id: 'english.g3.v1.u01.k001',
    name: '问候时段',
    pattern: 'Good morning / afternoon / evening / night.',
  ),
  KnowledgePoint(
    id: 'english.g3.v1.u01.k002',
    name: '告别',
    pattern: 'Goodbye. / Bye.',
  ),
  KnowledgePoint(
    id: 'english.g3.v1.u01.k003',
    name: '打招呼',
    pattern: 'Hello. / Hi.',
  ),
  KnowledgePoint(
    id: 'english.g3.v1.u01.k004',
    name: '询问名字',
    pattern: "What's your name?",
  ),
  KnowledgePoint(
    id: 'english.g3.v1.u01.k005',
    name: '自我介绍',
    pattern: "I'm ___.",
  ),
  KnowledgePoint(
    id: 'english.g3.v1.u01.k006',
    name: '互相介绍',
    pattern: "Hi, ___. I'm ___.",
  ),
];
