import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 小游戏的领域代码不依赖英语的 Word、语音与计分规则（见 0010）。
/// 这些文件只能依赖 game_item.dart；英语规则只能经由 english_game_adapter.dart 进入。
void main() {
  const gameFiles = [
    'lib/domain/match_game.dart',
    'lib/domain/falling_round.dart',
    'lib/domain/word_uno.dart',
    'lib/domain/twenty_questions.dart',
    'lib/domain/game_item.dart',
  ];
  const forbidden = [
    'unit.dart',
    'english_game_adapter.dart',
    'speech_player.dart',
    'audioplayers',
    'progress.dart',
  ];

  for (final path in gameFiles) {
    test('$path 不依赖英语专用模块', () {
      final source = File(path).readAsStringSync();
      for (final name in forbidden) {
        expect(source.contains(name), isFalse, reason: '$path 不应引用 $name');
      }
      expect(RegExp(r'\bWord\b').hasMatch(source), isFalse, reason: '$path 不应使用 Word');
    });
  }
}
