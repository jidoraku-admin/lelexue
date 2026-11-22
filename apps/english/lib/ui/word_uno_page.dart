import 'package:material_ui/material_ui.dart';

import '../data/speech_player.dart';
import '../data/unit_repository.dart';
import '../domain/unit.dart';
import '../domain/english_game_adapter.dart';
import '../domain/word_uno.dart';

/// 单词 UNO：顶牌是英文或中文；同色、或是它的另一半，才能出。出完手牌即胜利。
class WordUnoPage extends StatefulWidget {
  const WordUnoPage({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<WordUnoPage> createState() => _WordUnoPageState();
}

class _WordUnoPageState extends State<WordUnoPage> {
  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  final SpeechPlayer _speech = SpeechPlayer();
  WordUno? _game;
  int _seed = 0;
  String? _message;
  UnoCard? _pickingWild; // 正在为哪张万能牌选颜色

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  void _newGame(Unit unit) {
    setState(() {
      _game = WordUno.fromItems(wordsToItems(unit.words), seed: _seed++);
      _message = null;
      _pickingWild = null;
    });
  }

  void _play(UnoCard card) {
    final game = _game!;
    if (card.isWild) {
      setState(() {
        _pickingWild = card;
        _message = '万能牌：选一个颜色';
      });
      return;
    }
    if (!game.canPlay(card)) {
      setState(() => _message = '颜色不同，也不是一对。试试别的牌，或者摸一张。');
      return;
    }
    setState(() {
      game.play(card);
      _message = game.isWon ? '全部出完！你真棒！' : '出得好！';
    });
    if (card.isEnglish) {
      _speech.speak(card.text);
    }
  }

  void _pickColor(int color) {
    final game = _game!;
    final card = _pickingWild!;
    setState(() {
      game.play(card, chosenColor: color);
      _pickingWild = null;
      _message = game.isWon ? '全部出完！你真棒！' : '万能牌换成了${_colorNames[color]}色。';
    });
  }

  void _draw() {
    final game = _game!;
    setState(() {
      if (!game.draw()) {
        _message = '牌都摸完了。';
      } else {
        _message = '摸了一张牌。';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单词 UNO')),
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
          final game = _game ??= WordUno.fromItems(wordsToItems(unit.words), seed: _seed++);
          final theme = Theme.of(context);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('顶牌', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _CardTile(card: game.top, big: true),
                const SizedBox(height: 12),
                if (_message != null)
                  Text(
                    _message!,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                if (_pickingWild != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < _colorNames.length; i++)
                        ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: _CardTile._colorFor(i),
                          ),
                          label: Text(_colorNames[i]),
                          onPressed: () => _pickColor(i),
                        ),
                      ActionChip(
                        label: const Text('取消'),
                        onPressed: () => setState(() {
                          _pickingWild = null;
                          _message = null;
                        }),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '手牌 ${game.hand.length} 张（点能出的牌）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in game.hand)
                          _CardTile(
                            card: c,
                            playable: game.canPlay(c),
                            onTap: () => _play(c),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (game.isWon)
                  FilledButton(
                    onPressed: () => _newGame(unit),
                    child: const Text('再来一局'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: game.canDraw ? _draw : null,
                          child: Text(
                            game.drawPile.isEmpty
                                ? '摸牌（洗回弃牌）'
                                : '摸牌（剩 ${game.drawPile.length}）',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (game.isStuck)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      onPressed: () => _newGame(unit),
                      child: const Text('卡住了，重新发牌'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _colorNames = ['红', '蓝', '绿', '橙'];

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    this.big = false,
    this.playable = true,
    this.onTap,
  });

  final UnoCard card;
  final bool big;
  final bool playable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = card.isWild && card.color < 0
        ? Colors.blueGrey.shade700
        : _colorFor(card.color);
    return Opacity(
      opacity: playable ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: big ? 200 : 100,
          height: big ? 110 : 64,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            card.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: big ? 22 : 15,
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorFor(int i) => const [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
  ][i];
}
