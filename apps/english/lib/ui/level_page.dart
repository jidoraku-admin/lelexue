import 'package:material_ui/material_ui.dart';

import '../domain/level_run.dart';
import '../domain/progress.dart';
import '../data/progress_store.dart';
import '../domain/unit.dart';
import '../data/speech_player.dart';

/// 关卡页：逐题作答，答错即时讲解，结束后结算并保存进度。
/// 返回 true 表示进度已变化，地图需要刷新。
class LevelPage extends StatefulWidget {
  const LevelPage({super.key, required this.level, required this.progress, required this.store});

  final Level level;
  final Progress progress;
  final ProgressStore store;

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  late LevelRun run = LevelRun(widget.level);
  bool saved = false;
  final SpeechPlayer _speech = SpeechPlayer();

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  void _choose(int i) {
    if (run.lastCorrect || run.finished) return;
    final ok = run.answer(i);
    setState(() {});
    if (ok && isEnglish(run.current.options[i])) _speech.speak(run.current.options[i]);
  }

  void _next() {
    setState(() => run.next());
    if (run.finished) _settle();
  }

  Future<void> _settle() async {
    if (saved) return;
    saved = true;
    final progress = widget.progress;
    progress.record(widget.level.id, run.stars);
    if (widget.level.id == Progress.remediationId && run.passed) {
      progress.remediation.clear();
      progress.stars.remove(Progress.remediationId);
    }
    if (widget.level.isBoss && !run.passed) {
      progress.remediation
        ..clear()
        ..addAll(run.missed.map((q) => q.id));
    }
    await widget.store.save(progress);
  }

  void _restart() {
    setState(() {
      run = LevelRun(widget.level);
      saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(level.title)),
        body: run.finished ? _result(context) : _question(context),
      ),
    );
  }

  Widget _question(BuildContext context) {
    final q = run.current;
    final total = run.level.questions.length;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: run.index / total),
          const SizedBox(height: 8),
          Text('第 ${run.index + 1} / $total 题', textAlign: TextAlign.right),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    q.prompt,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (isEnglish(q.prompt))
                    IconButton(
                      tooltip: '播放',
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _speech.speak(q.prompt),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedScale(
                scale: run.lastCorrect && run.lastChoice == i ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: FilledButton.tonal(
                  key: ValueKey('option-$i'),
                  onPressed: run.lastCorrect ? null : () => _choose(i),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _optionColor(theme, i),
                  ),
                  child: Text(q.options[i], style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (run.feedback != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: run.lastCorrect ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(run.feedback!, style: const TextStyle(fontSize: 16)),
            ),
          const SizedBox(height: 16),
          if (run.lastCorrect)
            FilledButton(
              key: const ValueKey('next'),
              onPressed: _next,
              child: Text(run.index + 1 == total ? '完成' : '下一题'),
            ),
        ],
      ),
    );
  }

  Color? _optionColor(ThemeData theme, int i) {
    if (run.lastChoice != i) return null;
    return run.lastCorrect ? Colors.green.shade200 : Colors.orange.shade200;
  }

  Widget _result(BuildContext context) {
    final theme = Theme.of(context);
    final passed = run.passed;
    final isBoss = widget.level.isBoss;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 1; s <= 3; s++)
                  AnimatedScale(
                    scale: s <= run.stars ? 1.2 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.star,
                      size: 48,
                      color: s <= run.stars ? Colors.amber : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              passed ? '过关！' : '差一点，再挑战一次',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('首次作答正确率 ${run.percent}%（通过线 ${(widget.level.passRate * 100).round()}%）'),
            if (!passed && isBoss) ...[
              const SizedBox(height: 12),
              Text(
                '需要补救 ${run.missed.length} 个薄弱题，补救通过后再挑战 Boss。',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('返回地图'),
            ),
            const SizedBox(height: 8),
            if (!passed && !(isBoss && run.missed.isNotEmpty))
              OutlinedButton(onPressed: _restart, child: const Text('立即再挑战')),
          ],
        ),
      ),
    );
  }
}
