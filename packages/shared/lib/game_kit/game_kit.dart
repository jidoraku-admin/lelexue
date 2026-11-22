/// 共通玩法框架（game kit）接口草案 v0.1。
///
/// 依据 docs/decisions/0010-shared-game-kit.md。
/// 本文件只定义接口，不含实现。框架不认识学科，不计分，不调用语音与数据加载。
library game_kit;

/// 通用题目条目。学科适配层把自己的内容映射为这个结构。
class GameItem {
  const GameItem({
    required this.id,
    required this.prompt,
    this.hint,
  });

  /// 条目 id。配对玩法中，两段文本共用同一个 id。
  final String id;

  /// 主文本，例如题干或一个配对词。
  final String prompt;

  /// 副文本，例如释义或反馈文本。框架只展示，不解释。
  final String? hint;
}

/// 一次作答的结果。框架只上报对错与用时，不计分。
class GameAnswer {
  const GameAnswer({
    required this.itemId,
    required this.correct,
    required this.durationMs,
  });

  final String itemId;
  final bool correct;
  final int durationMs;
}

/// 作答回调。由学科适配层注入，用于接收结果并决定计分与记录。
typedef AnswerReporter = void Function(GameAnswer answer);

/// 首批玩法的种类。第二批候选（拖拽搭建、排序）待项目总监确认后再加入。
enum GameMechanicKind {
  match,
  fallingChoice,
  cardPlay,
  guess,
}

/// 玩法配置的公共部分。每种玩法各有一个子类。
sealed class GameMechanicConfig {
  const GameMechanicConfig({required this.onAnswer});

  final AnswerReporter onAnswer;

  GameMechanicKind get kind;
}

/// 配对：成对的条目共用同一个 id。
class MatchConfig extends GameMechanicConfig {
  const MatchConfig({
    required super.onAnswer,
    required this.pairs,
  });

  /// 每一对包含两个条目，id 相同。
  final List<(GameItem, GameItem)> pairs;

  @override
  GameMechanicKind get kind => GameMechanicKind.match;
}

/// 下落选择：目标条目与干扰条目按规则下落。
class FallingChoiceConfig extends GameMechanicConfig {
  const FallingChoiceConfig({
    required super.onAnswer,
    required this.targets,
    required this.distractors,
    this.lives = 3,
  });

  final List<GameItem> targets;
  final List<GameItem> distractors;

  /// 漏接或误接的容忍次数。具体数值由学科配置。
  final int lives;

  @override
  GameMechanicKind get kind => GameMechanicKind.fallingChoice;
}

/// 卡牌条目。属性的含义由学科定义，框架只做匹配。
class GameCard {
  const GameCard({
    required this.item,
    required this.attribute,
  });

  final GameItem item;

  /// 属性值，例如颜色。框架只判断是否相等。
  final String attribute;
}

/// 出牌：玩家按属性匹配顶牌出牌。
class CardPlayConfig extends GameMechanicConfig {
  const CardPlayConfig({
    required super.onAnswer,
    required this.hand,
    required this.startCard,
  });

  final List<GameCard> hand;
  final GameCard startCard;

  @override
  GameMechanicKind get kind => GameMechanicKind.cardPlay;
}

/// 猜测：通过提问收窄候选集。问题的含义由学科适配层提供。
class GuessConfig extends GameMechanicConfig {
  const GuessConfig({
    required super.onAnswer,
    required this.candidates,
    required this.questions,
  });

  final List<GameItem> candidates;

  /// 学科定义的可问特征。框架只调用，不解释。
  final List<GuessQuestion> questions;

  @override
  GameMechanicKind get kind => GameMechanicKind.guess;
}

/// 一个可问的特征。`matches` 由学科适配层实现。
class GuessQuestion {
  const GuessQuestion({
    required this.id,
    required this.text,
    required this.matches,
  });

  final String id;

  /// 提问文本，由学科提供。
  final String text;

  /// 判断某个候选是否满足该特征。
  final bool Function(GameItem candidate) matches;
}

/// 玩法入口的抽象契约。框架各玩法实现这个接口。
abstract class GameMechanic {
  /// 开始一局。
  void start(GameMechanicConfig config);

  /// 结束一局并释放资源。
  void dispose();
}
