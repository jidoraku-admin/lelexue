/// 激励用语。按次数轮换，避免每次都一样。
const List<String> _praises = ['太棒了！', '真厉害！', '好极了！', '你真聪明！'];
const List<String> _englishPraises = [
  'Great!',
  'Nice!',
  'Awesome!',
  'Perfect!',
];

/// 第 n 次命中时的鼓励语。
String praiseFor(int n) => _praises[n % _praises.length];

/// 英文鼓励语，用在朗读单词之后。
String englishPraiseFor(int n) => _englishPraises[n % _englishPraises.length];

/// 连击提示；连击不到 2 次时不提示。
String? comboText(int streak) => streak >= 2 ? '连击 $streak 次！' : null;

/// 结束时的总结语。
String endingMessage({required bool won, required int points}) =>
    won ? '你真棒！本局得 $points 分' : '没关系，下次一定更好！本局得 $points 分';
