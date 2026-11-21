import 'package:flutter/services.dart' show rootBundle;

import '../domain/unit.dart';
import '../domain/unit_loader.dart';

/// 数据层：从资源包读取单元数据并交给领域层组装。
/// 新增单元只需新增 assets/data/unitN.json，这里不需要改动。
class UnitRepository {
  const UnitRepository();

  Future<Unit> load(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    return const UnitLoader().parse(source);
  }
}
