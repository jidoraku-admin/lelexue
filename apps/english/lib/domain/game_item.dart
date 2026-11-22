/// 小游戏通用的题目单位。小游戏只认识这四个字段，不认识英语的单词类型，也不认识语音与计分规则。
class GameItem {
  const GameItem({
    required this.id,
    required this.text,
    required this.label,
    required this.detail,
  });

  /// 唯一标识，用于判断两个题目是否为同一个。
  final String id;

  /// 主文本，例如英文单词。
  final String text;

  /// 短释义，用于配对卡、下落提示等空间有限的地方。
  final String label;

  /// 完整释义，用于揭晓答案等需要完整说明的地方。
  final String detail;
}
