/// 英语经验与等级（v0.16.1 §经验与等级，#7）。
///
/// 规则：每个知识点首次达到 2★ 时给予一次经验（由 Progress.applyMastery 保证只发一次）。
/// 经验数值与等级曲线是英语的学科参数（小事），后续可由后台配置替换。
library;

/// 首次达到 2★ 的经验值。
const xpPerMastery = 20;

/// 每级所需经验：第 n 级需要的累计经验为 (n - 1) * xpPerLevel。
const xpPerLevel = 100;

/// 当前等级（从 1 开始）。
int levelForXp(int xp) => xp < 0 ? 1 : xp ~/ xpPerLevel + 1;

/// 距离下一级还需要的经验。
int xpToNextLevel(int xp) {
  final nextThreshold = levelForXp(xp) * xpPerLevel;
  return nextThreshold - xp;
}
