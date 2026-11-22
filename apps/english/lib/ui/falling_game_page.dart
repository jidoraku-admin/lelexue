import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/speech_player.dart';
import '../data/unit_repository.dart';
import '../domain/falling_round.dart';
import '../domain/match_game.dart' show shortMeaning;
import '../domain/unit.dart';

enum FallingKind { frog, plane }

/// 下落类小游戏：青蛙吃虫、打飞机。规则相同（见 FallingRound），只换画面与操作的故事。
class FallingGamePage extends StatefulWidget {
  const FallingGamePage({
    super.key,
    required this.assetPath,
    required this.kind,
  });

  final String assetPath;
  final FallingKind kind;

  @override
  State<FallingGamePage> createState() => _FallingGamePageState();
}

class _Falling {
  _Falling(this.id, this.word, this.x);
  final int id;
  final Word word;
  final double x; // 0..1，屏幕宽度的比例
  double y = -0.1; // 0..1，屏幕高度的比例
}

class _FallingGamePageState extends State<FallingGamePage> {
  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  final SpeechPlayer _speech = SpeechPlayer();
  final Random _random = Random();
  FallingRound? _round;
  final List<_Falling> _items = [];
  Timer? _timer;
  int _tick = 0;
  int _nextId = 0;
  int _seed = 0;

  static const int _goal = 10;

  @override
  void dispose() {
    _timer?.cancel();
    _speech.dispose();
    super.dispose();
  }

  void _start(Unit unit) {
    _timer?.cancel();
    _items.clear();
    _tick = 0;
    _round = FallingRound(words: unit.words, goal: _goal, seed: _seed++);
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _step());
  }

  void _step() {
    final round = _round;
    if (round == null || round.isOver) {
      _timer?.cancel();
      return;
    }
    setState(() {
      _tick++;
      // 大约每 1.2 秒出现一个：四成是目标，其余是干扰项。
      if (_tick % 36 == 0) {
        final isTarget = _random.nextInt(10) < 4;
        final word = isTarget ? round.target : round.randomDistractor();
        _items.add(_Falling(_nextId++, word, 0.1 + _random.nextDouble() * 0.8));
      }
      for (final item in _items) {
        item.y += 0.011;
      }
      final escaped = _items.where((i) => i.y >= 1).toList();
      for (final item in escaped) {
        _items.remove(item);
        if (item.word.en == round.target.en) round.targetEscaped();
      }
      if (round.isOver) {
        _timer?.cancel();
      }
    });
  }

  void _tapItem(_Falling item, FallingRound round) {
    if (round.isOver) return;
    late bool ok;
    setState(() {
      _items.remove(item);
      ok = round.hit(item.word);
    });
    if (round.isOver) {
      _timer?.cancel();
    }
    if (ok) {
      _speech.speak(item.word.en);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFrog = widget.kind == FallingKind.frog;
    return Scaffold(
      appBar: AppBar(title: Text(isFrog ? '青蛙吃虫' : '打飞机')),
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
          if (_round == null) _start(unit);
          final round = _round!;
          final theme = Theme.of(context);
          return LayoutBuilder(
            builder: (context, c) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: isFrog
                          ? const Color(0xFFBDE7A8)
                          : const Color(0xFFBFE6FF),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Text(
                          round.isOver
                              ? ''
                              : '找：${shortMeaning(round.target.zh)}',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '得分 ${round.score}/$_goal    ${List.filled(round.lives.clamp(0, 3), '❤').join()}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  for (final item in _items)
                    Positioned(
                      left: item.x * c.maxWidth - 40,
                      top: item.y * c.maxHeight,
                      child: GestureDetector(
                        onTap: () => _tapItem(item, round),
                        child: _WordBubble(text: item.word.en, isFrog: isFrog),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Icon(
                      isFrog ? Icons.pest_control : Icons.airplanemode_active,
                      size: 56,
                      color: isFrog
                          ? Colors.green.shade800
                          : Colors.blueGrey.shade700,
                    ),
                  ),
                  if (round.isOver)
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                round.isWon ? '太棒了！' : '再试一次',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => setState(() => _start(unit)),
                                child: const Text('再玩一局'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('返回'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _WordBubble extends StatelessWidget {
  const _WordBubble({required this.text, required this.isFrog});

  final String text;
  final bool isFrog;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFrog ? Colors.lime.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black54),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFrog ? Icons.bug_report : Icons.flight, size: 18),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
