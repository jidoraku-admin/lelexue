import 'package:material_ui/material_ui.dart';

import 'core/readings.dart';
import 'first_slice_questions.dart';
import 'mastery/mastery_draft.dart';

void main() => runApp(const PhysicsFirstSliceApp());

class PhysicsFirstSliceApp extends StatelessWidget {
  const PhysicsFirstSliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学 · 物理 第一章',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const FirstSlicePage(),
    );
  }
}

class FirstSlicePage extends StatefulWidget {
  const FirstSlicePage({super.key});

  @override
  State<FirstSlicePage> createState() => _FirstSlicePageState();
}

class _FirstSlicePageState extends State<FirstSlicePage> {
  static const _knowledgePointIdRuler = 'physics.g8.v1.u01.k001';
  static const _knowledgePointIdTimer = 'physics.g8.v1.u01.k002';

  int _index = 0;
  final List<bool> _rulerResults = [];
  final List<bool> _timerResults = [];
  String _feedback = '';
  bool? _lastCorrect;

  // 刻度尺题的点选状态（单位 cm）
  double? _tapStartCm;
  double? _tapEndCm;

  // 停表题输入
  final _minutesCtrl = TextEditingController();
  final _secondsCtrl = TextEditingController();

  SliceQuestion get _q => firstSliceQuestions[_index];
  bool get _finished => _index >= firstSliceQuestions.length;

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  void _submit({double? answerCm, double? answerSec}) {
    final correct = judgeQuestion(_q, answerCm: answerCm, answerSec: answerSec);
    setState(() {
      (_q is RulerQuestion ? _rulerResults : _timerResults).add(correct);
      _lastCorrect = correct;
      _feedback = correct
          ? '读数正确。灯灯：「你找到了正确的刻度！」'
          : '灯灯：「你觉得是哪里不一样？先看分度值再估读。」';
    });
  }

  void _next() {
    setState(() {
      _index++;
      _feedback = '';
      _lastCorrect = null;
      _tapStartCm = null;
      _tapEndCm = null;
      _minutesCtrl.clear();
      _secondsCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第一章 机械运动 · 赛道测速（P1）')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _finished ? _buildSummary() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('第 ${_index + 1} / ${firstSliceQuestions.length} 题',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (q is RulerQuestion) _buildRuler(q) else _buildStopwatch(),
        const SizedBox(height: 12),
        if (_feedback.isNotEmpty)
          Text(_feedback,
              style: TextStyle(
                  color: _lastCorrect == true ? Colors.green[800] : Colors.red[800])),
        const Spacer(),
        if (_lastCorrect == null) const SizedBox.shrink() else
          FilledButton(onPressed: _next, child: const Text('下一题')),
      ],
    );
  }

  Widget _buildRuler(RulerQuestion q) {
    final answered = _lastCorrect != null;
    return Column(
      children: [
        const Text('点两下：先点左端，再点右端（精确到 0.01 cm）。'),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          final width = c.maxWidth;
          return GestureDetector(
            onTapDown: answered
                ? null
                : (d) {
                    final cm = (d.localPosition.dx / width) * 10.0;
                    final rounded = double.parse(cm.toStringAsFixed(2));
                    setState(() {
                      if (_tapStartCm == null) {
                        _tapStartCm = rounded;
                      } else {
                        _tapEndCm = rounded;
                      }
                    });
                  },
            child: CustomPaint(
              size: Size(width, 90),
              painter: _RulerPainter(
                  startCm: _tapStartCm, endCm: _tapEndCm),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(_tapEndCm == null
            ? '已点：${_tapStartCm?.toStringAsFixed(2) ?? '-'} cm'
            : '长度：${(_tapEndCm! - _tapStartCm!).abs().toStringAsFixed(2)} cm'),
        const SizedBox(height: 8),
        if (!answered && _tapEndCm != null)
          FilledButton(
            onPressed: () => _submit(
                answerCm: (_tapEndCm! - _tapStartCm!).abs()),
            child: const Text('确认'),
          ),
      ],
    );
  }

  Widget _buildStopwatch() {
    final answered = _lastCorrect != null;
    return Column(
      children: [
        const Text('输入两表盘读数：小表盘分钟数，大表盘秒数（0.1 s 分度）。'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _minutesCtrl,
              enabled: !answered,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '分钟'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _secondsCtrl,
              enabled: !answered,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '秒（0–59.9）'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (!answered)
          FilledButton(
            onPressed: () {
              final m = int.tryParse(_minutesCtrl.text.trim());
              final s = double.tryParse(_secondsCtrl.text.trim());
              if (m == null || s == null || s < 0 || s >= 60) {
                setState(() => _feedback = '请输入有效的分钟与秒数（秒在 0 到 59.9 之间）。');
                return;
              }
              _submit(answerSec: stopwatchTotalSeconds(minutes: m, seconds: s));
            },
            child: const Text('确认'),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final level1 = buildLevel1Draft(
      knowledgePointId: _knowledgePointIdRuler,
      results: _rulerResults,
    );
    final timerDraft = buildLevel1Draft(
      knowledgePointId: _knowledgePointIdTimer,
      results: _timerResults,
    );
    final allResults = [..._rulerResults, ..._timerResults];
    final ok = level1.meetsLevel1Rule && timerDraft.meetsLevel1Rule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('本关结束：答对 ${allResults.where((r) => r).length} / ${allResults.length}'),
        const SizedBox(height: 8),
        Text(ok
            ? '两个知识点的 1★ 规则均已满足（草稿，待数据平台发布）。'
            : '至少一个知识点未满足 1★ 规则（需正确率 ≥80% 且不少于 5 题）。'),
        const SizedBox(height: 8),
        Text('掌握度草稿（不含 eventId）：${level1.knowledgePointId} · 1★ · ${level1.correct}/${level1.attempts}'),
        Text('掌握度草稿（不含 eventId）：${timerDraft.knowledgePointId} · 1★ · ${timerDraft.correct}/${timerDraft.attempts}'),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({this.startCm, this.endCm});
  final double? startCm;
  final double? endCm;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRect(Offset.zero & size, bg);
    final line = Paint()..color = Colors.black87..strokeWidth = 1;
    final pxPerCm = size.width / 10;
    for (int i = 0; i <= 100; i++) {
      final x = i * pxPerCm / 10;
      final len = i % 10 == 0 ? 28.0 : (i % 5 == 0 ? 18.0 : 10.0);
      canvas.drawLine(Offset(x, 0), Offset(x, len), line);
    }
    for (int cm = 0; cm <= 10; cm++) {
      final tp = TextPainter(
        text: TextSpan(text: '$cm', style: const TextStyle(color: Colors.black87, fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cm * pxPerCm - tp.width / 2, 32));
    }
    final mark = Paint()..color = Colors.indigo..strokeWidth = 3;
    if (startCm != null) {
      final x = startCm! * pxPerCm;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), mark);
    }
    if (endCm != null) {
      final x = endCm! * pxPerCm;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), mark);
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.startCm != startCm || old.endCm != endCm;
}
