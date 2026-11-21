import 'package:material_ui/material_ui.dart';

import '../data/unit_index.dart';
import 'unit_map_page.dart';

/// 首页：列出所有单元。单元来自索引，新增单元不需要改这里。
class UnitListPage extends StatelessWidget {
  const UnitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('乐乐学 · 英语（人教版三年级上）')),
      body: FutureBuilder<List<UnitIndexEntry>>(
        future: const UnitIndex().load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('加载失败：${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final units = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final u in units)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                    title: Text('${u.code} ${u.title}'),
                    subtitle: Text(u.isValidated ? '已核对' : '词表待核对（仅内部试玩）'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => UnitMapPage(assetPath: u.assetPath)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
