// hub 调用的数学入口（#3、#191；契约见 #23 / #141 第 2 节）。
// 进入后可选第 1 单元「观察物体」，含 k001–k006 全部关卡。
// 独立运行的 main.dart 保留，不受影响；hub 注册表由共通负责登记。
import 'package:material_ui/material_ui.dart';
import 'package:shared/core/core.dart';

import 'unit01/unit01_loader.dart';

/// hub 调用的学科入口。只接收 [userId] 与 [subject]，返回时调用 [onExit]。
Widget buildSubjectEntry({
  required UserId userId,
  required SubjectCode subject,
  required VoidCallback onExit,
}) {
  return MathEntry(userId: userId, onExit: onExit);
}

class MathEntry extends StatelessWidget {
  const MathEntry({
    super.key,
    required this.userId,
    required this.onExit,
    this.loadUnit01Source,
  });

  final UserId userId;
  final VoidCallback onExit;

  /// 第 1 单元数据读取方式；测试时可替换。
  final Future<String> Function()? loadUnit01Source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乐乐学·数学'),
        leading: IconButton(
          key: const Key('math-exit'),
          icon: const Icon(Icons.arrow_back),
          onPressed: onExit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            key: const Key('math-unit01'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('第 1 单元 观察物体')),
                  body: Unit01Loader(loadSource: loadUnit01Source),
                ),
              ),
            ),
            child: const Text('第 1 单元 观察物体（6 关）'),
          ),
        ],
      ),
    );
  }
}
