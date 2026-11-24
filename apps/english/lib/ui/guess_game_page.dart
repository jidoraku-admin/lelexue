import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/unit_repository.dart';
import '../domain/twenty_questions.dart';
import '../domain/english_game_adapter.dart';
import '../domain/game_item.dart';
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
  YesNoQuestion? _pending;
  final List<String> _log = [];

  /// 每局随机选答案，不使用固定种子，避免每次答案相同。
  TwentyQuestions _newRound(Unit unit) => TwentyQuestions(
    items: wordsToItems(unit.words),
    secretIndex: Random().nextInt(unit.words.length),
  );

  void _restart(Unit unit) {
    setState(() {
      _game = _newRound(unit);
      _pending = null;
      _log.clear();
    });
  }

  void _confirmAsk() {
    final q = _pending!;
    final game = _game!;
    setState(() {
      _pending = null;
      final yes = game.ask(q);
      _log.insert(0, '问：${q.text}  系统答：${yes ? '是' : '否'}');
    });
  }

  void _guess(GameItem w) {
    final game = _game!;
    setState(() {
      _pending = null;
      final ok = game.guess(w);
      _log.insert(0, '直接猜：${w.text}  →  ${ok ? '猜对了！' : '不对'}');
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
          final game = _game ??= _newRound(unit);
          final theme = Theme.of(context);
          final questions = game.availableQuestions().take(8).toList();
          final candidates = game.remainingCandidates;
          final allWords = wordsToItems(unit.words);
          final possible = allWords.where(game.candidatesContain).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 玩法说明：页面本身要能看懂在玩什么。
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '系统想好了一个本单元的英文单词。选一个「是/否」问题提问，缩小范围；候选词少的时候可以直接猜。最多问 ${TwentyQuestions.defaultMax} 次。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '已问 ${game.asked}/${TwentyQuestions.defaultMax}　还剩 $candidates 个候选词',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 候选词默认收起：展开后会直接看到全部答案范围，失去玩的意义。
              ExpansionTile(
                initiallyExpanded: false,
                title: Text('剩余候选词（$candidates）'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      possible.map((w) => w.text).join('、'),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
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
                              ? '猜对了！答案是 ${game.reveal().text}'
                              : '时间到。答案是 ${game.reveal().text}（${game.reveal().detail}）',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _restart(unit),
                          child: const Text('再来一局'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (_pending != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '确定问：${_pending!.text}',
                            style: theme.textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => _pending = null),
                                child: const Text('取消'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: _confirmAsk,
                                child: const Text('确定提问'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('选一个问题问：', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final q in questions)
                      ActionChip(
                        label: Text(q.text),
                        onPressed: () => setState(() => _pending = q),
                      ),
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
                      for (final w in possible)
                        OutlinedButton(
                          onPressed: () => _guess(w),
                          child: Text(w.text),
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
}
