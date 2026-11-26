// 第 1 单元题目加载（#3）：读取资源文件后交给作答界面。
// main.dart 与 hub 入口（entry.dart）共用。
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

import 'items_loader.dart';
import 'judge.dart';
import 'unit01_page.dart';

const String unit01AssetPath = 'assets/data/math-g3-unit01-items.json';

class Unit01Loader extends StatefulWidget {
  const Unit01Loader({super.key, this.loadSource});

  /// 读取数据全文；测试时可替换，默认读取 [unit01AssetPath]。
  final Future<String> Function()? loadSource;

  @override
  State<Unit01Loader> createState() => _Unit01LoaderState();
}

class _Unit01LoaderState extends State<Unit01Loader> {
  late final Future<List<Unit01Item>> _items = _load();

  Future<List<Unit01Item>> _load() async {
    final source = await (widget.loadSource ??
        () => rootBundle.loadString(unit01AssetPath))();
    return parseUnit01Items(source);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Unit01Item>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('题目数据读取失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Unit01Page(items: snapshot.data!);
      },
    );
  }
}
