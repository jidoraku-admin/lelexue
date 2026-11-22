import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 播放英语语音。语音由 Piper TTS 预先生成，索引见 assets/audio/audio_index.json。
class SpeechPlayer {
  SpeechPlayer();

  /// 测试环境没有音频插件，测试里关闭发音；正常运行时保持开启。
  static bool enabled = true;

  // 第一次发音时才创建播放器，不发音的页面不占用音频资源。
  AudioPlayer? _player;
  Map<String, String>? _index;

  Future<Map<String, String>> _load() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('assets/audio/audio_index.json');
    _index = (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
    return _index!;
  }

  /// 文本没有对应语音时静默跳过。
  Future<void> speak(String text) async {
    if (!enabled) return;
    final index = await _load();
    final file = index[text];
    if (file == null) return;
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('audio/$file'));
    } catch (_) {
      // 音频失败不影响答题流程。
    }
  }

  Future<void> dispose() async => _player?.dispose();
}

/// 是否为英文文本（包含字母且不含中文）。
bool isEnglish(String text) =>
    RegExp(r'[A-Za-z]').hasMatch(text) && !RegExp(r'[一-鿿]').hasMatch(text);
