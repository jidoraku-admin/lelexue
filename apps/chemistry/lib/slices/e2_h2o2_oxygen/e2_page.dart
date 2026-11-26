import 'package:material_ui/material_ui.dart';

import '../../content/chemistry_content.dart';
import '../../scoring/chemistry_scoring.dart';
import '../quiz_page.dart';

/// E2：过氧化氢制氧（二氧化锰作催化剂，k002）。
///
/// 第一版为学科内交互：选择条件并预测现象，再看真实结果（#197 总监决定）。
/// 共通框架第二批（拖拽搭建）上线后，改为拖拽组装发生装置。
class E2Page extends StatelessWidget {
  const E2Page({super.key, required this.scoring});

  final ChemistryScoring scoring;

  @override
  Widget build(BuildContext context) {
    return QuizPage(
      title: 'E2 过氧化氢制氧',
      questions: e2Questions,
      scoring: scoring,
      safetyNotice: e2SafetyNotice,
    );
  }
}
