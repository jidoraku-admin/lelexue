import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'domain/unit.dart';
import 'domain/unit_loader.dart';

void main() {
  runApp(const LelexueEnglishApp());
}

class LelexueEnglishApp extends StatelessWidget {
  const LelexueEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学 英语',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const UnitMapPage(),
    );
  }
}

/// Unit 1 地图的骨架页面：列出关卡，视觉与动画待后续实现。
class UnitMapPage extends StatelessWidget {
  const UnitMapPage({super.key});

  Future<Unit> _load() async {
    final source = await rootBundle.loadString('assets/data/unit1.json');
    return const UnitLoader().parse(source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unit 1 Greetings')),
      body: FutureBuilder<Unit>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = snapshot.data!;
          return ListView(
            children: [
              if (!unit.isValidated)
                const ListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('词表待核对（#44），仅供内部试玩'),
                ),
              for (final level in unit.levels)
                ListTile(
                  title: Text(level.title),
                  subtitle: Text(level.words.isNotEmpty
                      ? '${level.words.length} 个词'
                      : '${level.sentences.length} 个句型'),
                ),
            ],
          );
        },
      ),
    );
  }
}
