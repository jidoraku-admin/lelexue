import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../data/unit_repository.dart';
import '../domain/unit.dart';

/// 单元动画开场：角色依次跑入场景，旁白与角色台词逐句出现。数据全部来自单元文件。
class StoryIntroPage extends StatefulWidget {
  const StoryIntroPage({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<StoryIntroPage> createState() => _StoryIntroPageState();
}

class _StoryIntroPageState extends State<StoryIntroPage> {
  late final Future<Unit> _future = const UnitRepository().load(
    widget.assetPath,
  );
  int _shown = 0; // 已经出场的角色数
  int _line = 0; // 当前台词序号（0 为旁白）
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      final unit = _unit;
      if (unit == null) return; // 数据还没加载，等下一拍
      if (_shown >= unit.characters.length) {
        t.cancel();
        return;
      }
      setState(() => _shown++);
    });
  }

  Unit? _unit;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next(Unit unit) {
    if (_line < unit.characters.length) {
      setState(() => _line++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动画开场')),
      body: FutureBuilder<Unit>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = _unit = snapshot.data!;
          final chars = unit.characters;
          final isEnd = _line >= chars.length;
          final speaker = _line == 0 ? null : chars[_line - 1];
          final text = _line == 0 ? unit.scenario : speaker!.line;
          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SvgPicture.asset(
                      'assets/art/gate_bg.svg',
                      fit: BoxFit.cover,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < chars.length; i++)
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                offset: i < _shown
                                    ? Offset.zero
                                    : const Offset(-1.5, 0),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: i < _shown ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: _Bounce(
                                      speaking: _line == i + 1,
                                      child: SvgPicture.asset(
                                        chars[i].asset,
                                        width: 96,
                                        height: 96,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (speaker != null)
                      Text(
                        speaker.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        text,
                        key: ValueKey(_line),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('story-next'),
                      onPressed: _shown < chars.length && _line == 0
                          ? null
                          : () => isEnd
                                ? Navigator.of(context).pop()
                                : _next(unit),
                      child: Text(isEnd ? '开始学习' : '下一句'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 角色待机时轻微弹跳；正在说话时放大并加快，让画面动起来。
class _Bounce extends StatefulWidget {
  const _Bounce({required this.speaking, required this.child});

  final bool speaking;
  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant _Bounce old) {
    super.didUpdateWidget(old);
    _c.duration = Duration(milliseconds: widget.speaking ? 260 : 600);
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final lift = -10 * _c.value;
        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: widget.speaking ? 1.15 : 1,
          child: Transform.translate(offset: Offset(0, lift), child: child),
        );
      },
      child: widget.child,
    );
  }
}
