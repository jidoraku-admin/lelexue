import 'package:material_ui/material_ui.dart';

/// 乐乐学·化学 入口（骨架）。界面与 E1、E3 切片在后续 PR 中实现。
void main() {
  runApp(const ChemistryApp());
}

class ChemistryApp extends StatelessWidget {
  const ChemistryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学·化学',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('乐乐学·化学（骨架）')),
      ),
    );
  }
}
