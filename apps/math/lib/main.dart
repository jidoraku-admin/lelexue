// 乐乐学数学：第 1 单元「观察物体」使用版入口（#3）。
// 题目来自 assets/data/math-g3-unit01-items.json（与 docs/data 同源，内容未经数学复核）。
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

import 'unit01/items_loader.dart';
import 'unit01/judge.dart';
import 'unit01/unit01_page.dart';

void main() {
  runApp(const LelexueMathApp());
}

class LelexueMathApp extends StatelessWidget {
  const LelexueMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学 数学',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text('第 1 单元 观察物体')),
        body: _Unit01Loader(),
      ),
    );
  }
}

class _Unit01Loader extends StatelessWidget {
  const _Unit01Loader();

  Future<List<Unit01Item>> _load() async {
    final source = await rootBundle.loadString(
      'assets/data/math-g3-unit01-items.json',
    );
    return parseUnit01Items(source);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Unit01Item>>(
      future: _load(),
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
