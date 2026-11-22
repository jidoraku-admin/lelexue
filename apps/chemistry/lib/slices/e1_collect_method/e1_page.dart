import 'package:material_ui/material_ui.dart';

import '../../content/chemistry_content.dart';
import '../../scoring/chemistry_scoring.dart';
import '../quiz_page.dart';

/// E1：氧气的收集方法（学科内选择题，k001）。
class E1Page extends StatelessWidget {
  const E1Page({super.key, required this.scoring});

  final ChemistryScoring scoring;

  @override
  Widget build(BuildContext context) {
    return QuizPage(title: 'E1 氧气的收集', questions: e1Questions, scoring: scoring);
  }
}
