import 'package:material_ui/material_ui.dart';
import 'package:shared/core/subject_code.dart';
import 'package:shared/core/user_id.dart';
import 'package:lelexue_english/entry.dart' as english;

/// 学科入口签名（契约第 2 节）。学科在 P1/P2 中按此导出 buildSubjectEntry。
typedef SubjectEntryBuilder = Widget Function({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
});

/// 学科注册项（契约第 2 节）。定义放在 hub 内，因为入口需要 Flutter Widget，
/// packages/shared 是纯 Dart 包。
class SubjectModule {
  const SubjectModule({
    required this.code,
    required this.displayName,
    this.entry,
  });

  final SubjectCode code;
  final String displayName;

  /// 学科入口；未接入时为 null，hub 显示占位页。
  final SubjectEntryBuilder? entry;
}

/// 静态注册表，顺序固定：英语、数学、语文、物理、化学。
const List<SubjectModule> subjectRegistry = [
  SubjectModule(
    code: SubjectCode.english,
    displayName: '英语',
    entry: english.buildSubjectEntry,
  ),
  SubjectModule(code: SubjectCode.math, displayName: '数学'),
  SubjectModule(code: SubjectCode.chinese, displayName: '语文'),
  SubjectModule(code: SubjectCode.physics, displayName: '物理'),
  SubjectModule(code: SubjectCode.chemistry, displayName: '化学'),
];

SubjectModule? findSubject(String wireName) {
  for (final m in subjectRegistry) {
    if (m.code.wireName == wireName) return m;
  }
  return null;
}
