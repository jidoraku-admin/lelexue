import 'package:material_ui/material_ui.dart';

import '../../content/chemistry_content.dart';
import '../../scoring/chemistry_scoring.dart';
import '../quiz_page.dart';

/// E3：氧气的检验（学科内现象预测，k003）。玩法留在学科内，不使用共通框架。
class E3Page extends StatelessWidget {
  const E3Page({super.key, required this.scoring});

  final ChemistryScoring scoring;

  @override
  Widget build(BuildContext context) {
    return QuizPage(title: 'E3 氧气的检验', questions: e3Questions, scoring: scoring);
  }
}
