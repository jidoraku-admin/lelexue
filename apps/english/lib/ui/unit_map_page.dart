import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/knowledge_points.dart';
import '../domain/knowledge_status.dart';
import '../domain/progress.dart';
import '../domain/xp.dart';
import '../domain/unit.dart';
import '../domain/unit_summary.dart';
import '../data/unit_repository.dart';
import '../data/progress_store.dart';
import 'level_page.dart';
import 'game_hub_page.dart';
import 'story_intro_page.dart';

/// Unit 1 地图：按路径展示关卡，已通过、可挑战、未解锁三种状态。
class UnitMapPage extends StatefulWidget {
  const UnitMapPage({super.key, required this.assetPath});

  /// 单元数据文件路径，例如 assets/data/unit1.json。
  final String assetPath;

  @override
  State<UnitMapPage> createState() => _UnitMapPageState();
}

class _UnitMapPageState extends State<UnitMapPage> {
  late Future<_Loaded> _future = _load();
  late ProgressStore store;

  Future<_Loaded> _load() async {
    final unit = await const UnitRepository().load(widget.assetPath);
    store = ProgressStore(unitCode: unit.code);
    final progress = await store.load();
    return _Loaded(unit, progress);
  }

  void _reload() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _open(Unit unit, Progress progress, Level level) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LevelPage(
          level: level,
          progress: progress,
          store: store,
          characters: unit.characters,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  void _showKnowledge(BuildContext context, Progress progress) {
    final statuses = knowledgeStatus(
      points: unit1KnowledgePoints,
      attempts: progress.attempts,
      mastered: progress.mastered.toSet(),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('知识点学情（应用题）'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final s in statuses)
                ListTile(
                  key: ValueKey<String>('kp-${s.point.name}'),
                  title: Text(s.point.name),
                  subtitle: Text(s.point.pattern),
                  trailing: Text(
                    s.total == 0
                        ? s.label
                        : '${s.label} ${s.correct}/${s.total}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetProgress() async {
    await store.reset();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<_Loaded>(
          future: _future,
          builder: (_, s) => Text(
            s.hasData ? '${s.data!.unit.code} ${s.data!.unit.title}' : '',
          ),
        ),
        actions: [
          FutureBuilder<_Loaded>(
            future: _future,
            builder: (_, s) {
              if (!s.hasData) return const SizedBox.shrink();
              final xp = s.data!.progress.xp;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '等级 ${levelForXp(xp)} · 经验 $xp',
                    key: const ValueKey<String>('xp-badge'),
                  ),
                ),
              );
            },
          ),
          FutureBuilder<_Loaded>(
            future: _future,
            builder: (context, s) => IconButton(
              tooltip: '知识点学情',
              icon: const Icon(Icons.insights),
              onPressed: s.hasData
                  ? () => _showKnowledge(context, s.data!.progress)
                  : null,
            ),
          ),
          IconButton(
            tooltip: '重置进度（仅试玩）',
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetProgress,
          ),
        ],
      ),
      body: FutureBuilder<_Loaded>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = snapshot.data!;
          final unit = loaded.unit;
          final progress = loaded.progress;
          final path = progress.path(unit);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!unit.isValidated)
                Card(
                  color: Colors.amber.shade50,
                  child: const ListTile(
                    leading: Icon(Icons.warning_amber),
                    title: Text('词表待核对（#44），仅供内部试玩'),
                  ),
                ),
              _SummaryCard(summary: UnitSummary.of(unit, progress)),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset(
                      'assets/art/gate_bg.svg',
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          for (final c in unit.characters) ...[
                            Tooltip(
                              message: '${c.name}：${c.line}',
                              child: SvgPicture.asset(
                                c.asset,
                                width: 56,
                                height: 56,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const SizedBox(width: 8),
                          Expanded(child: Text(unit.scenario)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.movie),
                      label: const Text('动画开场'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StoryIntroPage(assetPath: widget.assetPath),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.sports_esports),
                      label: const Text('小游戏'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              GameHubPage(assetPath: widget.assetPath),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < path.length; i++)
                _LevelTile(
                  level: path[i],
                  stars: progress.stars[path[i].id] ?? 0,
                  unlocked: progress.isUnlocked(path, i),
                  onTap: progress.isUnlocked(path, i)
                      ? () => _open(unit, progress, path[i])
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Loaded {
  const _Loaded(this.unit, this.progress);
  final Unit unit;
  final Progress progress;
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final Level level;
  final int stars;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        enabled: unlocked,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: unlocked
              ? theme.colorScheme.primary
              : Colors.grey.shade300,
          child: Icon(
            unlocked ? Icons.play_arrow : Icons.lock,
            color: unlocked ? theme.colorScheme.onPrimary : Colors.grey,
          ),
        ),
        title: Text(level.title),
        subtitle: Text(
          '${level.questions.length} 题 · 通过线 ${(level.passRate * 100).round()}%',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var s = 1; s <= 3; s++)
              Icon(
                Icons.star,
                size: 18,
                color: s <= stars ? Colors.amber : Colors.grey.shade300,
              ),
          ],
        ),
      ),
    );
  }
}

/// 单元总结卡片：星星、学会的词、错题本，通关后显示祝贺。
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final UnitSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: summary.complete ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.complete ? '单元通关！' : '单元进度',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('星星 ${summary.starsEarned}/${summary.starsTotal}'),
            Text('学会的单词 ${summary.wordsLearned}/${summary.wordsTotal}'),
            Text('错题本 ${summary.missedLeft} 个待复习'),
          ],
        ),
      ),
    );
  }
}
