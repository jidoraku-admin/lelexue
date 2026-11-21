import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progress.dart';

/// 进度的本地存储（Web 使用 localStorage，移动端使用系统存储）。
class ProgressStore {
  const ProgressStore({required this.unitCode});

  /// 单元代码，例如 "Unit 1"。每个单元的进度独立保存。
  final String unitCode;

  String get key =>
      'english.${unitCode.replaceAll(' ', '').toLowerCase()}.progress';

  Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return Progress();
    return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(progress.toJson()));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
