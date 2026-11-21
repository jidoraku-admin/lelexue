import 'package:material_ui/material_ui.dart';

import '../data/unit_repository.dart';
import '../domain/match_game.dart';
import '../domain/unit.dart';

/// 翻卡挑战：用本单元的词做英文与中文配对。局数与发牌由 seed 决定，可以再来一局。
class MatchGamePage extends StatefulWidget {
  const MatchGamePage({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<MatchGamePage> createState() => _MatchGamePageState();
}

class _MatchGamePageState extends State<MatchGamePage> {
  late final Future<Unit> _future = const UnitRepository().load(widget.assetPath);
  MatchGame? _game;
  int _seed = 0;

  void _start(Unit unit) {
    _game = MatchGame.fromWords(unit.words, seed: _seed);
  }

  void _restart(Unit unit) {
    setState(() {
      _seed++;
      _start(unit);
    });
  }

  void _tap(int index) {
    final game = _game!;
    if (game.hasPendingMismatch) return;
    setState(() => game.flip(index));
    if (game.hasPendingMismatch) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => game.hideMismatch());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('翻卡挑战')),
      body: FutureBuilder<Unit>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('加载失败：${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final unit = snapshot.data!;
          _game ??= MatchGame.fromWords(unit.words, seed: _seed);
          final game = _game!;
          final theme = Theme.of(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  game.isComplete
                      ? '全部配对！用了 ${game.moves} 次翻牌'
                      : '找出英文和中文的一对。已翻 ${game.moves} 次',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < game.cards.length; i++) _CardView(card: game.cards[i], onTap: () => _tap(i)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonal(
                  onPressed: () => _restart(unit),
                  child: Text(game.isComplete ? '再来一局' : '重新发牌'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.onTap});

  final MatchCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showFace = card.faceUp || card.matched;
    final color = card.matched
        ? Colors.green.shade100
        : showFace
            ? theme.colorScheme.surface
            : theme.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: card.matched || showFace ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(
          showFace ? card.text : '?',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: showFace ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
