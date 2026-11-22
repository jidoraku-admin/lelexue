import 'package:material_ui/material_ui.dart';

import '../data/speech_player.dart';
import 'word_icon.dart';
import '../data/unit_repository.dart';
import '../domain/encouragement.dart';
import '../domain/english_game_adapter.dart';
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
  final SpeechPlayer _speech = SpeechPlayer();

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  MatchGame? _game;
  int _seed = 0;

  void _start(Unit unit) {
    _game = MatchGame.fromItems(
      wordsToItems(unit.words),
      scoreForStreak: pointsForStreak,
      seed: _seed,
    );
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
    final card = game.cards[index];
    setState(() => game.flip(index));
    if (card.isEnglish) _speech.speak(card.text);
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
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = snapshot.data!;
          _game ??= MatchGame.fromItems(
      wordsToItems(unit.words),
      scoreForStreak: pointsForStreak,
      seed: _seed,
    );
          final game = _game!;
          final theme = Theme.of(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      game.isComplete
                          ? '${endingMessage(won: true, points: game.points)}（最高连对 ${game.bestStreak} 次）'
                          : '分数 ${game.points}    已翻 ${game.moves} 次',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!game.isComplete && comboText(game.streak) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          comboText(game.streak)!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.extent(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  maxCrossAxisExtent: 84,
                  childAspectRatio: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < game.cards.length; i++)
                      _CardView(card: game.cards[i], onTap: () => _tap(i)),
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
    final scheme = theme.colorScheme;
    final showFace = card.faceUp || card.matched;

    final BoxDecoration decoration;
    if (card.matched) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.green.shade400],
        ),
      );
    } else if (showFace) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: card.isEnglish
              ? [Colors.white, Colors.lime.shade100]
              : [Colors.white, Colors.amber.shade100],
        ),
      );
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: card.matched || showFace ? null : onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        scale: card.matched ? 1.05 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: showFace
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (card.isEnglish)
                      Icon(wordIcon(card.text), size: 22, color: scheme.primary)
                    else
                      const Icon(
                        Icons.translate,
                        size: 20,
                        color: Colors.brown,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      card.text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (card.matched)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.star_border,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }
}
