import 'package:material_ui/material_ui.dart' show IconData, Icons;

/// 单词的装饰图标。目前还没有每个单词的插画，先用图标代替；有插画后替换这里即可。
const Map<String, IconData> _byWord = {
  'hello': Icons.waving_hand,
  'hi': Icons.waving_hand,
  'good morning': Icons.wb_sunny,
  'good afternoon': Icons.wb_twilight,
  'good evening': Icons.nights_stay,
  'good night': Icons.bedtime,
  'goodbye': Icons.directions_walk,
  'bye': Icons.directions_walk,
  'name': Icons.badge,
  'i': Icons.person,
  'you': Icons.person_outline,
  'ruler': Icons.straighten,
  'pencil': Icons.edit,
  'pen': Icons.create,
  'eraser': Icons.cleaning_services,
  'schoolbag': Icons.backpack,
  'ball': Icons.sports_soccer,
  'kite': Icons.air,
  'doll': Icons.child_care,
  'bike': Icons.pedal_bike,
  'cat': Icons.pets,
  'dog': Icons.pets,
};

const List<IconData> _fallback = [
  Icons.star,
  Icons.auto_awesome,
  Icons.favorite,
  Icons.emoji_objects,
];

/// 找不到专门图标时，按单词稳定地挑一个，保证同一个词每次都一样。
IconData wordIcon(String en) {
  final key = en.toLowerCase().replaceAll(RegExp(r'[!?.,]'), '').trim();
  return _byWord[key] ?? _fallback[key.hashCode.abs() % _fallback.length];
}
