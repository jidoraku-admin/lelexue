import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 单元索引（assets/data/index.json，由导出脚本生成）。
class UnitIndexEntry {
  const UnitIndexEntry({required this.assetPath, required this.code, required this.title, required this.validation});

  final String assetPath;
  final String code;
  final String title;
  final String validation;

  bool get isValidated => validation == 'passed';
}

class UnitIndex {
  const UnitIndex();

  Future<List<UnitIndexEntry>> load() async {
    final raw = await rootBundle.loadString('assets/data/index.json');
    final units = (jsonDecode(raw) as Map<String, dynamic>)['units'] as List;
    return [
      for (final u in units)
        UnitIndexEntry(
          assetPath: 'assets/data/${(u as Map)['file']}',
          code: u['code'] as String,
          title: u['title'] as String,
          validation: u['validation'] as String,
        ),
    ];
  }
}
