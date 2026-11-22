import 'dart:math';

import 'game_item.dart';

/// 翻卡配对：英文卡与中文卡成对，翻开两张，相同则配对成功，不同则翻回。
class MatchCard {
  MatchCard({
    required this.pairId,
    required this.text,
    required this.isEnglish,
  });

  final int pairId;
  final String text;
  final bool isEnglish;
  bool faceUp = false;
  bool matched = false;
}

/// 一次翻牌的结果。
enum FlipOutcome { ignored, firstOpen, matched, mismatch }

class MatchGame {
  MatchGame._(this.cards, this._scoreForStreak);

  final List<MatchCard> cards;
  final int Function(int streak) _scoreForStreak;
  int? _open;
  List<int>? _pendingMismatch;
  int moves = 0;
  int streak = 0; // 当前连续配对次数
  int bestStreak = 0;
  int points = 0;

  /// 用题目生成一局。取前 [pairs] 个题目，每个题目做成一对卡。计分规则由调用方注入。
  factory MatchGame.fromItems(
    List<GameItem> items, {
    required int Function(int streak) scoreForStreak,
    int pairs = 8,
    int seed = 0,
  }) {
    final chosen = items.take(pairs).toList();
    final cards = <MatchCard>[];
    for (var i = 0; i < chosen.length; i++) {
      cards.add(MatchCard(pairId: i, text: chosen[i].text, isEnglish: true));
      cards.add(
        MatchCard(pairId: i, text: chosen[i].label, isEnglish: false),
      );
    }
    cards.shuffle(Random(seed));
    return MatchGame._(cards, scoreForStreak);
  }

  bool get isComplete => cards.every((c) => c.matched);

  /// 发生不匹配后，两张牌需要先翻回，UI 在短暂停留后调用 [hideMismatch]。
  bool get hasPendingMismatch => _pendingMismatch != null;

  FlipOutcome flip(int index) {
    if (_pendingMismatch != null) return FlipOutcome.ignored;
    final card = cards[index];
    if (card.faceUp || card.matched) return FlipOutcome.ignored;

    card.faceUp = true;
    if (_open == null) {
      _open = index;
      return FlipOutcome.firstOpen;
    }

    moves++;
    final firstIndex = _open!;
    final first = cards[firstIndex];
    _open = null;
    if (first.pairId == card.pairId && first.isEnglish != card.isEnglish) {
      first.matched = true;
      card.matched = true;
      streak++;
      points += _scoreForStreak(streak);
      if (streak > bestStreak) bestStreak = streak;
      return FlipOutcome.matched;
    }
    streak = 0;
    _pendingMismatch = [firstIndex, index];
    return FlipOutcome.mismatch;
  }

  void hideMismatch() {
    final pending = _pendingMismatch;
    if (pending == null) return;
    for (final i in pending) {
      cards[i].faceUp = false;
    }
    _pendingMismatch = null;
  }
}
