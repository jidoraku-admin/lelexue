// 从 docs/data/math-g3-unit01-items.json 读取第 1 单元题目（#3）。
// 只做结构与格式校验，不改写题干和答案；数据内容的正确性由数学复核负责。
import 'dart:convert';

import 'judge.dart';

/// 本单元允许的玩法（与数据 _meta.games 一致）。
const Set<String> unit01Games = {'match_viewpoint', 'observe_choice'};

/// 解析数据文件的全文。格式不合法时抛出 [FormatException]。
List<Unit01Item> parseUnit01Items(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('根节点必须是对象');
  }
  final raw = decoded['items'];
  if (raw is! List || raw.isEmpty) {
    throw const FormatException('items 必须是非空数组');
  }

  final items = <Unit01Item>[];
  final seenIds = <String>{};
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('每个 item 必须是对象');
    }
    final id = _requireString(entry, 'id');
    final game = _requireString(entry, 'game');
    final prompt = _requireString(entry, 'prompt');
    final answer = _requireString(entry, 'answer');
    final distractors = _requireStrings(entry, 'distractors');

    if (!isValidKnowledgePointId(id)) {
      throw FormatException('knowledgePointId 不合法：$id');
    }
    if (!seenIds.add(id)) {
      throw FormatException('id 重复：$id');
    }
    if (!unit01Games.contains(game)) {
      throw FormatException('未知玩法 $game（$id）');
    }
    if (distractors.isEmpty ||
        distractors.toSet().length != distractors.length ||
        distractors.contains(answer)) {
      throw FormatException('选项必须互不相同，且不含答案：$id');
    }

    items.add(Unit01Item(
      id: id,
      game: game,
      prompt: prompt,
      answer: answer,
      distractors: distractors,
    ));
  }
  return items;
}

String _requireString(Map<String, dynamic> entry, String key) {
  final value = entry[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('字段 $key 必须是非空字符串');
  }
  return value;
}

List<String> _requireStrings(Map<String, dynamic> entry, String key) {
  final value = entry[key];
  if (value is! List || value.any((e) => e is! String || e.isEmpty)) {
    throw FormatException('字段 $key 必须是非空字符串数组');
  }
  return value.cast<String>();
}
