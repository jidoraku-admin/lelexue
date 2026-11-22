import 'package:material_ui/material_ui.dart';

import 'falling_game_page.dart';
import 'guess_game_page.dart';
import 'word_uno_page.dart';
import 'match_game_page.dart';

/// 游戏大厅：同一个单元的词，用不同的玩法来练。玩家自己选。
class GameHubPage extends StatelessWidget {
  const GameHubPage({super.key, required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final games = [
      _Game(
        title: '20 个问题',
        desc: '用「是/否」问题缩小范围，猜出系统想的单词。',
        icon: Icons.help_outline,
        page: GuessGamePage(assetPath: assetPath),
      ),
      _Game(
        title: '单词 UNO',
        desc: '出与顶牌同色、或是它另一半的牌，先出完者胜。',
        icon: Icons.style,
        page: WordUnoPage(assetPath: assetPath),
      ),
      _Game(
        title: '翻卡配对',
        desc: '翻开两张牌，找出英文和中文的一对。',
        icon: Icons.grid_view,
        page: MatchGamePage(assetPath: assetPath),
      ),
      _Game(
        title: '青蛙吃虫',
        desc: '看中文提示，点中正确的单词虫子。',
        icon: Icons.pest_control,
        page: FallingGamePage(assetPath: assetPath, kind: FallingKind.frog),
      ),
      _Game(
        title: '打飞机',
        desc: '敌机从天上掉下来，击中提示的那个单词。',
        icon: Icons.airplanemode_active,
        page: FallingGamePage(assetPath: assetPath, kind: FallingKind.plane),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('游戏大厅')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in games)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(g.icon)),
                title: Text(g.title),
                subtitle: Text(g.desc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => g.page)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Game {
  const _Game({
    required this.title,
    required this.desc,
    required this.icon,
    required this.page,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Widget page;
}
