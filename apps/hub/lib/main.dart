import 'package:material_ui/material_ui.dart';
import 'package:shared/core/user_id.dart';

import 'identity.dart';
import 'registry.dart';

void main() {
  runApp(const HubApp());
}

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const HubHomePage(),
          );
        }
        final match = RegExp(r'^/subjects/([a-z]+)$').firstMatch(name);
        if (match != null) {
          final module = findSubject(match.group(1)!);
          if (module != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SubjectEntryPage(module: module),
            );
          }
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(body: Center(child: Text('页面不存在'))),
        );
      },
    );
  }
}

/// 入口页：登录状态条 + 五张学科卡片（契约第 1 节）。
class HubHomePage extends StatelessWidget {
  const HubHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserId? userId = currentDevUserId();
    return Scaffold(
      appBar: AppBar(title: const Text('乐乐学')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  userId == null ? Icons.person_outline : Icons.verified_user,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(userId == null ? '未登录' : '已登录（开发测试账号）'),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 3 : 2;
                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    for (final m in subjectRegistry) _SubjectCard(module: m),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 每个学科的图标与颜色（仅用于入口卡片的视觉区分）。
const Map<String, (IconData, Color)> _subjectStyle = {
  'english': (Icons.translate, Colors.indigo),
  'math': (Icons.calculate, Colors.teal),
  'chinese': (Icons.menu_book, Colors.deepOrange),
  'physics': (Icons.bolt, Colors.blue),
  'chemistry': (Icons.science, Colors.green),
};

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.module});

  final SubjectModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _subjectStyle[module.code.wireName];
    final color = style?.$2 ?? theme.colorScheme.primary;
    final icon = style?.$1 ?? Icons.school;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed('/subjects/${module.code.wireName}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(module.displayName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '进入学习',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 学科入口页。未接入的学科显示占位；返回按钮回到入口页（契约第 1 节）。
class SubjectEntryPage extends StatelessWidget {
  const SubjectEntryPage({super.key, required this.module});

  final SubjectModule module;

  @override
  Widget build(BuildContext context) {
    final entry = module.entry;
    if (entry != null) {
      final userId = currentDevUserId();
      if (userId != null) {
        return entry(
          userId: userId,
          subject: module.code,
          onExit: () => Navigator.of(context).popUntil((r) => r.isFirst),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(module.displayName)),
      body: Center(
        child: Text(
          entry == null ? '${module.displayName}：入口待接入' : '请先登录',
        ),
      ),
    );
  }
}
