import 'dart:async';
import 'dart:math';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../data/speech_player.dart';
import '../data/unit_repository.dart';
import '../domain/encouragement.dart';
import '../domain/falling_round.dart';
import '../domain/english_game_adapter.dart';
import '../domain/game_item.dart';
import '../domain/unit.dart';

enum FallingKind { frog, plane }

/// 下落类小游戏：青蛙吃虫、打飞机。规则相同（见 FallingRound），只换画面与操作的故事。
class FallingGamePage extends StatefulWidget {
  const FallingGamePage({
    super.key,
    required this.assetPath,
    required this.kind,
    this.seed,
  });

  final String assetPath;
  final FallingKind kind;

  /// 随机种子。不传时每局随机；测试传固定值，使单词出现的顺序与位置可复现。
  final int? seed;

  @override
  State<FallingGamePage> createState() => _FallingGamePageState();
}

class _Falling {
  _Falling(this.word, this.x);
  final GameItem word;
  final double x; // 0..1，屏幕宽度的比例
  double y = 0.16; // 0..1，屏幕高度的比例；从提示文字下方出现
}

class _FallingGamePageState extends State<FallingGamePage> {
  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  final SpeechPlayer _speech = SpeechPlayer();
  late final Random _random = Random(widget.seed);
  FallingRound? _round;
  FallingSpeed _speed = FallingSpeed.slow;
  final List<_Falling> _items = [];
  Timer? _timer;
  Timer? _toastTimer;
  String? _toast;
  int _tick = 0;
  int _praiseCount = 0;
  late int _seed = widget.seed ?? 0;

  static const int _goal = 10;
  static const double _bubbleMaxWidth = 150;
  // 落到这条线以下算飞走，线在主角上方，气泡不会被挡住。
  static const double _escapeLine = 0.86;

  @override
  void dispose() {
    _timer?.cancel();
    _toastTimer?.cancel();
    _speech.dispose();
    super.dispose();
  }

  void _start(Unit unit) {
    _timer?.cancel();
    _items.clear();
    _tick = 0;
    _toast = null;
    _round = FallingRound(
      items: wordsToItems(unit.words),
      goal: _goal,
      scoreForStreak: pointsForStreak,
      seed: _seed++,
    );
    setState(() {});
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
      // 四成是目标，其余是干扰项；出现的间隔由速度等级决定。
      if (_tick % _speed.spawnEvery == 0) {
        final isTarget = _random.nextInt(10) < 4;
        final word = isTarget ? round.target : round.randomDistractor();
        _items.add(_Falling(word, 0.1 + _random.nextDouble() * 0.8));
      }
      for (final item in _items) {
        item.y += _speed.step;
      }
      final escapedTarget = _items.any(
        (i) => i.y >= _escapeLine && i.word.id == round.target.id,
      );
      _items.removeWhere((i) => i.y >= _escapeLine);
      if (escapedTarget) {
        final gone = round.target.id;
        round.targetEscaped();
        _items.removeWhere((i) => i.word.id == gone);
        _showToast('目标飞走了，扣一条命');
      }
      if (round.isOver) {
        _timer?.cancel();
      }
    });
  }

  void _tapItem(_Falling item, FallingRound round) {
    if (round.isOver) {
      return;
    }
    late bool ok;
    setState(() {
      ok = round.hit(item.word);
      if (ok) {
        // 目标词的其他副本也一起消失，否则它们会变成干扰项，误扣命。
        _items.removeWhere((i) => i.word.id == item.word.id);
        _showToast(
          '${praiseFor(_praiseCount++)}  ${comboText(round.streak) ?? ''}'
              .trim(),
        );
      } else {
        _items.remove(item);
        _showToast('不是这个哦，扣一条命');
      }
    });
    if (round.isOver) {
      _timer?.cancel();
    }
    if (ok) {
      _speech.speak(item.word.text);
    }
  }

  void _showToast(String text) {
    _toast = text;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _toast = null);
      }
    });
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
          final round = _round;
          if (round == null) {
            return _SpeedPanel(
              speed: _speed,
              onSpeed: (s) => setState(() => _speed = s),
              onStart: () => _start(unit),
            );
          }
          return _playfield(context, unit, round, isFrog);
        },
      ),
    );
  }

  Widget _playfield(
    BuildContext context,
    Unit unit,
    FallingRound round,
    bool isFrog,
  ) {
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
                    round.isOver ? '' : '找：${round.target.label}',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '分数 ${round.points}   进度 ${round.score}/$_goal   ${List.filled(round.lives.clamp(0, 3), '❤').join()}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            // 提示文字与主角只用于展示，不拦截点击，否则会挡住下面的单词。
            if (_toast != null)
              Positioned(
                top: 110,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    _toast!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            for (final item in _items)
              Positioned(
                left: 8 + item.x * (c.maxWidth - 16 - _bubbleMaxWidth),
                top: item.y * c.maxHeight,
                child: GestureDetector(
                  onTap: () => _tapItem(item, round),
                  child: _WordBubble(text: item.word.text, isFrog: isFrog),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: SvgPicture.asset(
                    isFrog ? 'assets/art/frog.svg' : 'assets/art/plane.svg',
                    width: 84,
                    height: 84,
                  ),
                ),
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
                        const SizedBox(height: 8),
                        Text(
                          endingMessage(won: round.isWon, points: round.points),
                          textAlign: TextAlign.center,
                        ),
                        if (round.bestStreak >= 2)
                          Text('最高连击 ${round.bestStreak} 次'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _start(unit),
                          child: const Text('再玩一局'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _timer?.cancel();
                            _round = null;
                          }),
                          child: const Text('换速度'),
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
  }
}

/// 开始前选择速度等级。
class _SpeedPanel extends StatelessWidget {
  const _SpeedPanel({
    required this.speed,
    required this.onSpeed,
    required this.onStart,
  });

  final FallingSpeed speed;
  final ValueChanged<FallingSpeed> onSpeed;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('怎么玩', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '上面写着中文，点中屏幕上对应的英文单词。'
              '点对得分，连续点对会加分；点错或目标飞走扣一条命；凑够 10 个就通关。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('选择速度', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                for (final s in FallingSpeed.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: speed == s,
                    onSelected: (_) => onSpeed(s),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onStart, child: const Text('开始')),
          ],
        ),
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
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 150),
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
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
