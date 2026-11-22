import 'game_item.dart';
import 'unit.dart';

/// 英语适配层：把英语的 Word 转为小游戏通用的 GameItem，并保存英语专用的释义裁剪与计分规则。
/// 小游戏的领域代码不引用本文件。
GameItem wordToItem(Word w) => GameItem(
  id: w.en,
  text: w.en,
  label: shortMeaning(w.zh),
  detail: w.zh,
);

List<GameItem> wordsToItems(List<Word> words) => words.map(wordToItem).toList();

/// 中文释义取第一个义项，并去掉括号里的用法说明，例如 "（用于…）是" 变成 "是"。
String shortMeaning(String zh) {
  final noParen = zh.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '').trim();
  final first = noParen.split(RegExp(r'[；;，,]')).first.trim();
  return first.isEmpty ? zh : first;
}

/// 英语的一次命中分数：基础 10 分，连击越多加分越多（最多加到 20 分）。
int pointsForStreak(int streak) => 10 + (streak - 1).clamp(0, 4) * 5;
