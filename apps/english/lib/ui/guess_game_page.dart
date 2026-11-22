import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/unit_repository.dart';
import '../domain/twenty_questions.dart';
import '../domain/unit.dart';

/// 20 个问题：系统想好一个单词，玩家问是/否问题，缩小范围后猜出来。
class GuessGamePage extends StatefulWidget {
  const GuessGamePage({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<GuessGamePage> createState() => _GuessGamePageState();
}

class _GuessGamePageState extends State<GuessGamePage> {
  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  TwentyQuestions? _game;
  final List<String> _log = [];
  int _seed = 0;

  void _newGame(Unit unit) {
    setState(() {
      _game = TwentyQuestions(
        words: unit.words,
        secretIndex: Random(_seed++).nextInt(unit.words.length),
      );
      _log.clear();
    });
  }

  void _ask(YesNoQuestion q) {
    final game = _game!;
    setState(() {
      final yes = game.ask(q);
      _log.insert(0, '${q.text}  →  ${yes ? '是' : '否'}');
    });
  }

  void _guess(Word w) {
    final game = _game!;
    setState(() {
      final ok = game.guess(w);
      _log.insert(0, '猜 ${w.en}  →  ${ok ? '猜对了！' : '不对'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('20 个问题')),
      body: FutureBuilder<Unit>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = snapshot.data!;
          final game = _game ??= TwentyQuestions(
            words: unit.words,
            secretIndex: _seed++ % unit.words.length,
          );
          final theme = Theme.of(context);
          final questions = game.availableQuestions().take(8).toList();
          final candidates = game.remainingCandidates;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '已问 ${game.asked}/${TwentyQuestions.defaultMax}　还剩 $candidates 个候选词',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (game.isOver)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          game.isWon
                              ? '猜对了！答案是 ${game.reveal().en}'
                              : '时间到。答案是 ${game.reveal().en}（${game.reveal().zh}）',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _newGame(unit),
                          child: const Text('再来一局'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text('选一个问题问：', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final q in questions)
                      ActionChip(label: Text(q.text), onPressed: () => _ask(q)),
                  ],
                ),
                if (candidates <= 6) ...[
                  const SizedBox(height: 16),
                  Text('或者直接猜：', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in unit.words.where(
                        (w) => _stillPossible(game, w),
                      ))
                        OutlinedButton(
                          onPressed: () => _guess(w),
                          child: Text(w.en),
                        ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              for (final line in _log) Text(line),
            ],
          );
        },
      ),
    );
  }

  /// 只列出还没被排除的候选词（用于直接猜）。
  bool _stillPossible(TwentyQuestions game, Word w) =>
      game.candidatesContain(w);
}
