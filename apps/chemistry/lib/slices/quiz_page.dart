import 'package:material_ui/material_ui.dart';

import '../content/question.dart';
import '../scoring/chemistry_scoring.dart';

/// 学科内选择题页面（E1、E3 共用）。答对与答错都给出原理解释，不扣分。
class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.title,
    required this.questions,
    required this.scoring,
  });

  final String title;
  final List<Question> questions;
  final ChemistryScoring scoring;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _index = 0;
  int? _selected;
  int _correctCount = 0;
  int _newMasteryCount = 0;
  bool _finished = false;

  Question get _current => widget.questions[_index];

  void _choose(int option) {
    if (_selected != null) return;
    final q = _current;
    final correct = q.isCorrect(option);
    final reached = widget.scoring.recordAnswer(
      knowledgePointId: q.knowledgePointId,
      level: q.level,
      correct: correct,
      answeredAt: DateTime.now().toUtc(),
    );
    setState(() {
      _selected = option;
      if (correct) _correctCount++;
      if (reached) _newMasteryCount++;
    });
  }

  void _next() {
    if (_index + 1 >= widget.questions.length) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _finished ? _buildSummary() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _current;
    final answered = _selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('第 ${_index + 1} / ${widget.questions.length} 题',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        Text(q.prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: answered ? null : () => _choose(i),
              child: Text(q.options[i]),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 8),
          Text(
            _selected == q.answerIndex ? '答对了。' : '再想想。正确答案是：${q.options[q.answerIndex]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(q.explanation),
          const Spacer(),
          ElevatedButton(
            onPressed: _next,
            child: Text(_index + 1 >= widget.questions.length ? '查看结果' : '下一题'),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('本轮答对 $_correctCount / ${widget.questions.length}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('本轮新达到掌握门槛：$_newMasteryCount 个（掌握草稿待数据平台发布）'),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('返回'),
        ),
      ],
    );
  }
}
