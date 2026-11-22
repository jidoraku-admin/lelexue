import 'dart:math' as math;

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

  // 停表题的表盘点选状态（小表盘分钟数、大表盘秒数）
  int? _pickedMinutes;
  double? _pickedSeconds;

  SliceQuestion get _q => firstSliceQuestions[_index];
  bool get _finished => _index >= firstSliceQuestions.length;

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
      _pickedMinutes = null;
      _pickedSeconds = null;
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
    final m = _pickedMinutes;
    final s = _pickedSeconds;
    return Column(
      children: [
        const Text('点击表盘读数：左边小表盘选分钟，右边大表盘选秒（0.1 s 分度）。'),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildDial(
            caption: '分钟',
            size: 140,
            major: 10,
            minor: 1,
            labels: List.generate(10, (i) => '$i'),
            pointerFraction: m == null ? null : m / 10,
            enabled: !answered,
            onTapAt: (dx, dy) => setState(() => _pickedMinutes = minutesFromDial(dx, dy)),
          ),
          _buildDial(
            caption: '秒',
            size: 140,
            major: 6,
            minor: 10,
            labels: List.generate(6, (i) => '${i * 10}'),
            pointerFraction: s == null ? null : s / 60,
            enabled: !answered,
            onTapAt: (dx, dy) => setState(() => _pickedSeconds = secondsFromDial(dx, dy)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(m == null || s == null
            ? '读数：${m == null ? '- 分' : '$m 分'} ${s == null ? '- 秒' : '${s.toStringAsFixed(1)} 秒'}'
            : '读数：$m 分 ${s.toStringAsFixed(1)} 秒'),
        const SizedBox(height: 8),
        if (!answered && m != null && s != null)
          FilledButton(
            onPressed: () => _submit(answerSec: stopwatchTotalSeconds(minutes: m, seconds: s)),
            child: const Text('确认'),
          ),
      ],
    );
  }

  /// 可点击的表盘。点击位置换算为圆心角，再由 [onTapAt] 转成数值。
  Widget _buildDial({
    required String caption,
    required double size,
    required int major,
    required int minor,
    required List<String> labels,
    required double? pointerFraction,
    required bool enabled,
    required void Function(double dx, double dy) onTapAt,
  }) {
    return Column(
      children: [
        Text(caption),
        const SizedBox(height: 4),
        GestureDetector(
          onTapDown: enabled
              ? (d) {
                  final c = size / 2;
                  onTapAt(d.localPosition.dx - c, d.localPosition.dy - c);
                }
              : null,
          child: CustomPaint(
            size: Size(size, size),
            painter: _DialPainter(
              major: major,
              minor: minor,
              labels: labels,
              pointerFraction: pointerFraction,
            ),
          ),
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

/// 表盘绘制：外圈刻度与数字，指针指向已选位置（pointerFraction 为圆周比例，0 在正上方）。
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.major,
    required this.minor,
    required this.labels,
    this.pointerFraction,
  });
  final int major;
  final int minor;
  final List<String> labels;
  final double? pointerFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF5F5F5));
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    Offset polar(double frac, double r) {
      final a = frac * 2 * math.pi - math.pi / 2;
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    final total = major * minor;
    final tickPaint = Paint()..color = Colors.black87..strokeWidth = 1;
    for (int i = 0; i < total; i++) {
      final isMajor = i % minor == 0;
      final frac = i / total;
      canvas.drawLine(polar(frac, radius),
          polar(frac, radius - (isMajor ? 12 : 6)), tickPaint);
    }
    for (int i = 0; i < major; i++) {
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: Colors.black87, fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = polar(i / major, radius - 26) - Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, p);
    }
    if (pointerFraction != null) {
      canvas.drawLine(
          center,
          polar(pointerFraction!, radius - 18),
          Paint()
            ..color = Colors.indigo
            ..strokeWidth = 3);
    }
    canvas.drawCircle(center, 4, Paint()..color = Colors.indigo);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.pointerFraction != pointerFraction ||
      old.major != major ||
      old.minor != minor;
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
