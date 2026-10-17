import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/kids_palette.dart';
import '../data/reward_repository.dart';
import '../domain/rewards.dart';
import '../domain/word_entry.dart';

/// Clock seam so daily-bonus logic is testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final rewardsControllerProvider =
    NotifierProvider<RewardsController, PlayerProgress>(RewardsController.new);

/// Active clay palette (equipped theme reward).
final activePaletteProvider = Provider<ClayPalette>(
  (ref) => ClayPalette.byId(ref.watch(rewardsControllerProvider).equippedTheme),
);

class RewardsController extends Notifier<PlayerProgress> {
  RewardRepository get _repo => ref.read(rewardRepositoryProvider);

  @override
  PlayerProgress build() => ref.watch(rewardRepositoryProvider).load();

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Applies a win: stars, streak, badges and unlocks. Returns what the win
  /// dialog needs to celebrate.
  WinReward recordWin({
    required WordEntry entry,
    required int livesLeft,
    required int maxLives,
    required bool usedHint,
    required int mistakes,
    required int points,
    required int sessionScore,
  }) {
    final before = state;
    final today = dateKey(ref.read(clockProvider)());
    final streak = before.currentStreak + 1;
    final stars = StarRules.forWin(
      length: entry.length,
      livesLeft: livesLeft,
      maxLives: maxLives,
      usedHint: usedHint,
      firstClear: !before.solvedWordIds.contains(entry.id),
      dailyBonus: before.lastDailyBonusDate != today,
      streak: streak,
    );
    final perfect = !usedHint && mistakes == 0;

    var next = before.copyWith(
      totalStars: before.totalStars + stars.total,
      highScore: sessionScore > before.highScore ? sessionScore : null,
      wins: before.wins + 1,
      currentStreak: streak,
      bestStreak: streak > before.bestStreak ? streak : null,
      winsByLength: {
        ...before.winsByLength,
        entry.length: before.winsFor(entry.length) + 1,
      },
      noHintWins: usedHint ? null : before.noHintWins + 1,
      perfectWins: perfect ? before.perfectWins + 1 : null,
      categoriesWon: {...before.categoriesWon, entry.category},
      solvedWordIds: {...before.solvedWordIds, entry.id},
      lastDailyBonusDate: today,
    );

    final earned = RewardCatalog.earnedIds(next);
    final fresh = earned.difference(before.unlocked);
    next = next.copyWith(unlocked: {...before.unlocked, ...earned});
    _commit(next);

    return WinReward(
      stars: stars,
      points: points,
      newUnlocks: [for (final id in fresh) ?RewardCatalog.byId(id)],
      totalStars: next.totalStars,
      nextReward: nextStarReward(next),
      isNewHighScore: sessionScore > before.highScore,
    );
  }

  /// A loss only resets the streak; stars are never taken away.
  void recordLoss() {
    _commit(state.copyWith(currentStreak: 0, losses: state.losses + 1));
  }

  /// Equip an unlocked theme (or the free classic theme).
  bool equipTheme(String id) {
    final item = RewardCatalog.byId(id);
    final allowed =
        id == ClayPalette.classic.id ||
        (item != null && RewardCatalog.isEarned(item, state));
    if (!allowed) return false;
    _commit(state.copyWith(equippedTheme: id));
    return true;
  }

  Future<void> reset() async {
    await _repo.clear();
    state = const PlayerProgress();
  }

  static RewardItem? nextStarReward(PlayerProgress p) {
    for (final r in RewardCatalog.starUnlocks) {
      if (p.totalStars < r.starsNeeded!) return r;
    }
    return null;
  }

  void _commit(PlayerProgress next) {
    state = next;
    _repo.save(next);
  }
}
