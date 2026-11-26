// 乐乐学数学：第 1 单元「观察物体」独立运行入口（#3）。
// 题目来自 assets/data/math-g3-unit01-items.json（与 docs/data 同源，内容未经数学复核）。
// hub 内的入口见 entry.dart。
import 'package:material_ui/material_ui.dart';

import 'unit01/unit01_loader.dart';

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
        appBar: AppBar(title: const Text('第 1 单元 观察物体')),
        body: const Unit01Loader(),
      ),
    );
  }
}
