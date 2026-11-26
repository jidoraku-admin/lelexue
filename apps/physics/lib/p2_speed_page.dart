// 第一章 P2「测量小车的平均速度」页面：输入「数值 + 单位」，用 speed_answer.dart 判题。
import 'package:material_ui/material_ui.dart';

import 'core/speed_answer.dart';
import 'p2_speed_questions.dart';

class P2SpeedPage extends StatefulWidget {
  const P2SpeedPage({super.key, this.questions = p2SpeedQuestions});

  final List<SpeedQuestion> questions;

  @override
  State<P2SpeedPage> createState() => _P2SpeedPageState();
}

class _P2SpeedPageState extends State<P2SpeedPage> {
  final TextEditingController _controller = TextEditingController();
  final List<bool> _results = [];
  int _index = 0;
  SpeedJudgement? _last;

  bool get _finished => _index >= widget.questions.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final judgement = widget.questions[_index].judge(_controller.text);
    setState(() {
      _last = judgement;
      // 格式问题（无法识别）不计入作答，学生可改后再交。
      if (judgement != SpeedJudgement.unparsable) {
        _results.add(judgement == SpeedJudgement.correct);
      }
    });
  }

  void _next() {
    setState(() {
      _index++;
      _last = null;
      _controller.clear();
    });
  }

  static String feedbackFor(SpeedJudgement j) {
    switch (j) {
      case SpeedJudgement.correct:
        return '回答正确。灯灯：「v = s / t，单位也写对了！」';
      case SpeedJudgement.wrongValue:
        return '灯灯：「单位对了，再算一下：路程 ÷ 时间。」';
      case SpeedJudgement.wrongUnit:
        return '灯灯：「这不是速度的单位哦，试试 m/s 或 km/h。」';
      case SpeedJudgement.missingUnit:
        return '灯灯：「别忘了写单位，例如 m/s。」';
      case SpeedJudgement.unparsable:
        return '请按「数值 单位」的格式输入，例如 0.30 m/s。';
    }
  }

  bool get _answered =>
      _last != null && _last != SpeedJudgement.unparsable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第一章 机械运动 · 平均速度（P2）')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _finished ? _buildSummary() : _buildQuestion(context),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final q = widget.questions[_index];
    final last = _last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('第 ${_index + 1} / ${widget.questions.length} 题',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          key: const Key('p2-answer'),
          controller: _controller,
          enabled: !_answered,
          decoration: const InputDecoration(
            labelText: '答案（数值 + 单位）',
            hintText: '例如 0.30 m/s',
          ),
        ),
        const SizedBox(height: 12),
        if (last != null)
          Text(feedbackFor(last),
              style: TextStyle(
                  color: last == SpeedJudgement.correct
                      ? Colors.green[800]
                      : Colors.red[800])),
        const Spacer(),
        if (_answered)
          FilledButton(onPressed: _next, child: const Text('下一题'))
        else
          FilledButton(onPressed: _submit, child: const Text('确认')),
      ],
    );
  }

  Widget _buildSummary() {
    final correct = _results.where((r) => r).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('本关结束：答对 $correct / ${_results.length}'),
      ],
    );
  }
}
