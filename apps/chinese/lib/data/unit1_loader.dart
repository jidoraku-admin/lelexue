import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/chinese_unit1_adapter.dart';

/// 作为依赖被 hub 引用时，资源键带包前缀；独立运行或测试时不带前缀。
const unit1AssetKeys = [
  'packages/lelexue_chinese/assets/data/chinese-unit1.json',
  'assets/data/chinese-unit1.json',
];

/// 读取第 1 单元数据。依次尝试 [unit1AssetKeys]，都失败时抛出最后一个错误。
Future<ChineseUnit1Data> loadUnit1Data([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  Object? lastError;
  for (final key in unit1AssetKeys) {
    try {
      final raw = await b.loadString(key);
      return ChineseUnit1Data.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FlutterError catch (e) {
      lastError = e;
    }
  }
  throw lastError!;
}
