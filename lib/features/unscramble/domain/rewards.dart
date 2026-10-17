import 'package:flutter/foundation.dart';

enum RewardKind { sticker, badge, theme }

/// A collectible. Stickers and themes unlock when the player's lifetime
/// stars reach [starsNeeded] (stars are never spent, so kids never "lose"
/// stars). Badges unlock from play milestones.
@immutable
class RewardItem {
  const RewardItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.description,
    this.starsNeeded,
    this.assetPath,
  });

  final String id;
  final String name;
  final String emoji;
  final RewardKind kind;
  final String description;
  final int? starsNeeded;

  /// Optional final art under assets/images/rewards/. When the asset is not
  /// bundled the UI draws [emoji] on a clay badge instead.
  final String? assetPath;
}

/// Badge rule: unlocked once `current(progress) >= target`.
class BadgeRule {
  const BadgeRule(this.item, this.target, this.current);

  final RewardItem item;
  final int target;
  final int Function(PlayerProgress p) current;

  BadgeProgress progressFor(PlayerProgress p) =>
      BadgeProgress(item: item, current: current(p), target: target);
}

@immutable
class BadgeProgress {
  const BadgeProgress({
    required this.item,
    required this.current,
    required this.target,
  });

  final RewardItem item;
  final int current;
  final int target;

  bool get earned => current >= target;
  double get fraction => target == 0 ? 1 : (current / target).clamp(0.0, 1.0);
}

abstract final class RewardCatalog {
  static const categoryCount = 10;

  static const stickers = [
    RewardItem(
      id: 'sticker_happy_star',
      name: 'Happy Star',
      emoji: '🌟',
      kind: RewardKind.sticker,
      description: 'Your very first sticker!',
      starsNeeded: 5,
      assetPath: 'assets/images/rewards/stickers/happy_star.png',
    ),
    RewardItem(
      id: 'sticker_rainbow_cat',
      name: 'Rainbow Cat',
      emoji: '🐱',
      kind: RewardKind.sticker,
      description: 'A cat who loves every color.',
      starsNeeded: 12,
      assetPath: 'assets/images/rewards/stickers/rainbow_cat.png',
    ),
    RewardItem(
      id: 'sticker_sunny_day',
      name: 'Sunny Day',
      emoji: '🌞',
      kind: RewardKind.sticker,
      description: 'Smiles all day long.',
      starsNeeded: 20,
      assetPath: 'assets/images/rewards/stickers/sunny_day.png',
    ),
    RewardItem(
      id: 'sticker_cupcake',
      name: 'Party Cupcake',
      emoji: '🧁',
      kind: RewardKind.sticker,
      description: 'Sprinkles on top!',
      starsNeeded: 40,
      assetPath: 'assets/images/rewards/stickers/cupcake.png',
    ),
    RewardItem(
      id: 'sticker_rainbow',
      name: 'Rainbow',
      emoji: '🌈',
      kind: RewardKind.sticker,
      description: 'All the colors at once.',
      starsNeeded: 60,
      assetPath: 'assets/images/rewards/stickers/rainbow.png',
    ),
    RewardItem(
      id: 'sticker_rocket',
      name: 'Zoom Rocket',
      emoji: '🚀',
      kind: RewardKind.sticker,
      description: 'Blast off to word space!',
      starsNeeded: 80,
      assetPath: 'assets/images/rewards/stickers/rocket.png',
    ),
    RewardItem(
      id: 'sticker_dino',
      name: 'Dino Pal',
      emoji: '🦕',
      kind: RewardKind.sticker,
      description: 'A gentle, word-loving dino.',
      starsNeeded: 110,
      assetPath: 'assets/images/rewards/stickers/dino.png',
    ),
    RewardItem(
      id: 'sticker_unicorn',
      name: 'Magic Unicorn',
      emoji: '🦄',
      kind: RewardKind.sticker,
      description: 'The rarest sticker of all!',
      starsNeeded: 150,
      assetPath: 'assets/images/rewards/stickers/unicorn.png',
    ),
  ];

  static const themes = [
    RewardItem(
      id: 'sunshine',
      name: 'Sunshine Clay',
      emoji: '🌻',
      kind: RewardKind.theme,
      description: 'Warm yellow and orange clay.',
      starsNeeded: 30,
    ),
    RewardItem(
      id: 'ocean',
      name: 'Ocean Clay',
      emoji: '🐬',
      kind: RewardKind.theme,
      description: 'Cool blue and mint clay.',
      starsNeeded: 50,
    ),
  ];

  static final badges = <BadgeRule>[
    BadgeRule(
      const RewardItem(
        id: 'badge_word_rookie',
        name: 'Word Rookie',
        emoji: '🎉',
        kind: RewardKind.badge,
        description: 'Win your first word.',
        assetPath: 'assets/images/rewards/badges/word_rookie.png',
      ),
      1,
      (p) => p.wins,
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_ten_wins',
        name: 'Ten Wins',
        emoji: '🔟',
        kind: RewardKind.badge,
        description: 'Win 10 words.',
      ),
      10,
      (p) => p.wins,
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_perfect_round',
        name: 'Perfect Round',
        emoji: '💯',
        kind: RewardKind.badge,
        description: 'Win a word with no oopsies and no hint.',
      ),
      1,
      (p) => p.perfectWins,
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_streak_5',
        name: 'Streak 5',
        emoji: '🔥',
        kind: RewardKind.badge,
        description: 'Win 5 words in a row.',
      ),
      5,
      (p) => p.bestStreak,
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_no_hint_hero',
        name: 'No-Hint Hero',
        emoji: '🦸',
        kind: RewardKind.badge,
        description: 'Win 10 words without a hint.',
      ),
      10,
      (p) => p.noHintWins,
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_triple_champ',
        name: 'Triple Champ',
        emoji: '🥉',
        kind: RewardKind.badge,
        description: 'Win 25 three-letter words.',
      ),
      25,
      (p) => p.winsFor(3),
    ),
    BadgeRule(
      const RewardItem(
        id: 'badge_category_explorer',
        name: 'Category Explorer',
        emoji: '🧭',
        kind: RewardKind.badge,
        description: 'Win a word in all 10 categories.',
      ),
      categoryCount,
      (p) => p.categoriesWon.length,
    ),
  ];

  /// Things that unlock with stars, in order.
  static List<RewardItem> get starUnlocks =>
      [...stickers, ...themes]
        ..sort((a, b) => a.starsNeeded!.compareTo(b.starsNeeded!));

  static RewardItem? byId(String id) {
    for (final r in [...stickers, ...themes, ...badges.map((b) => b.item)]) {
      if (r.id == id) return r;
    }
    return null;
  }

  static bool isEarned(RewardItem item, PlayerProgress p) {
    if (item.kind == RewardKind.badge) {
      final rule = badges.firstWhere((b) => b.item.id == item.id);
      return rule.current(p) >= rule.target;
    }
    return p.totalStars >= (item.starsNeeded ?? 0);
  }

  static Set<String> earnedIds(PlayerProgress p) => {
    for (final r in starUnlocks)
      if (isEarned(r, p)) r.id,
    for (final b in badges)
      if (b.current(p) >= b.target) b.item.id,
  };
}

@immutable
class PlayerProgress {
  const PlayerProgress({
    this.totalStars = 0,
    this.highScore = 0,
    this.wins = 0,
    this.losses = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.winsByLength = const {},
    this.noHintWins = 0,
    this.perfectWins = 0,
    this.categoriesWon = const {},
    this.solvedWordIds = const {},
    this.unlocked = const {},
    this.equippedTheme = 'classic',
    this.lastDailyBonusDate,
  });

  factory PlayerProgress.fromJson(Map<String, dynamic> j) => PlayerProgress(
    totalStars: j['totalStars'] as int? ?? 0,
    highScore: j['highScore'] as int? ?? 0,
    wins: j['wins'] as int? ?? 0,
    losses: j['losses'] as int? ?? 0,
    currentStreak: j['currentStreak'] as int? ?? 0,
    bestStreak: j['bestStreak'] as int? ?? 0,
    winsByLength: {
      for (final e in (j['winsByLength'] as Map? ?? const {}).entries)
        int.parse(e.key as String): e.value as int,
    },
    noHintWins: j['noHintWins'] as int? ?? 0,
    perfectWins: j['perfectWins'] as int? ?? 0,
    categoriesWon: {...(j['categoriesWon'] as List? ?? const []).cast()},
    solvedWordIds: {...(j['solvedWordIds'] as List? ?? const []).cast()},
    unlocked: {...(j['unlocked'] as List? ?? const []).cast()},
    equippedTheme: j['equippedTheme'] as String? ?? 'classic',
    lastDailyBonusDate: j['lastDailyBonusDate'] as String?,
  );

  /// Lifetime stars earned (never spent).
  final int totalStars;
  final int highScore;
  final int wins;
  final int losses;
  final int currentStreak;
  final int bestStreak;
  final Map<int, int> winsByLength;
  final int noHintWins;
  final int perfectWins;
  final Set<String> categoriesWon;
  final Set<String> solvedWordIds;
  final Set<String> unlocked;
  final String equippedTheme;

  /// `yyyy-mm-dd` of the last daily first-play bonus.
  final String? lastDailyBonusDate;

  int winsFor(int length) => winsByLength[length] ?? 0;

  bool get isFresh => wins == 0 && totalStars == 0;

  Map<String, dynamic> toJson() => {
    'totalStars': totalStars,
    'highScore': highScore,
    'wins': wins,
    'losses': losses,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'winsByLength': {for (final e in winsByLength.entries) '${e.key}': e.value},
    'noHintWins': noHintWins,
    'perfectWins': perfectWins,
    'categoriesWon': categoriesWon.toList(),
    'solvedWordIds': solvedWordIds.toList(),
    'unlocked': unlocked.toList(),
    'equippedTheme': equippedTheme,
    'lastDailyBonusDate': lastDailyBonusDate,
  };

  PlayerProgress copyWith({
    int? totalStars,
    int? highScore,
    int? wins,
    int? losses,
    int? currentStreak,
    int? bestStreak,
    Map<int, int>? winsByLength,
    int? noHintWins,
    int? perfectWins,
    Set<String>? categoriesWon,
    Set<String>? solvedWordIds,
    Set<String>? unlocked,
    String? equippedTheme,
    String? lastDailyBonusDate,
  }) {
    return PlayerProgress(
      totalStars: totalStars ?? this.totalStars,
      highScore: highScore ?? this.highScore,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      winsByLength: winsByLength ?? this.winsByLength,
      noHintWins: noHintWins ?? this.noHintWins,
      perfectWins: perfectWins ?? this.perfectWins,
      categoriesWon: categoriesWon ?? this.categoriesWon,
      solvedWordIds: solvedWordIds ?? this.solvedWordIds,
      unlocked: unlocked ?? this.unlocked,
      equippedTheme: equippedTheme ?? this.equippedTheme,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
    );
  }
}

@immutable
class StarBreakdown {
  const StarBreakdown({
    required this.base,
    required this.baseMax,
    this.firstClear = 0,
    this.daily = 0,
    this.streak = 0,
  });

  /// Performance stars for this round (3-letter: 1–3, 4: 2–4, 5: 3–5).
  final int base;
  final int baseMax;
  final int firstClear;
  final int daily;
  final int streak;

  int get total => base + firstClear + daily + streak;
}

/// Pure star & score math (unit tested).
abstract final class StarRules {
  static const maxStreakBonus = 5;
  static const dailyBonus = 2;
  static const firstClearBonus = 1;

  /// Lowest star count for a word length: 3→1, 4→2, 5→3.
  static int baseMin(int length) => (length - 2).clamp(1, 3);

  /// 0..2 performance tier: +1 no hint, +1 no lives lost.
  static int tier({required bool usedHint, required bool fullLives}) =>
      (usedHint ? 0 : 1) + (fullLives ? 1 : 0);

  static StarBreakdown forWin({
    required int length,
    required int livesLeft,
    required int maxLives,
    required bool usedHint,
    required bool firstClear,
    required bool dailyBonus,
    required int streak,
  }) {
    final min = baseMin(length);
    return StarBreakdown(
      base: min + tier(usedHint: usedHint, fullLives: livesLeft >= maxLives),
      baseMax: min + 2,
      firstClear: firstClear ? firstClearBonus : 0,
      daily: dailyBonus ? StarRules.dailyBonus : 0,
      streak: (streak - 1).clamp(0, maxStreakBonus),
    );
  }

  /// Points: 3→10, 4→20, 5→30 base; +2 per life left; +1 per 5s left;
  /// +5 for a no-hint clear.
  static int score({
    required int length,
    required int livesLeft,
    int? secondsLeft,
    required bool usedHint,
  }) {
    final base = switch (length) {
      3 => 10,
      4 => 20,
      _ => 30,
    };
    return base + livesLeft * 2 + (secondsLeft ?? 0) ~/ 5 + (usedHint ? 0 : 5);
  }
}

/// Result of a win handed to the win dialog.
@immutable
class WinReward {
  const WinReward({
    required this.stars,
    required this.points,
    required this.newUnlocks,
    required this.totalStars,
    required this.nextReward,
    required this.isNewHighScore,
  });

  final StarBreakdown stars;
  final int points;
  final List<RewardItem> newUnlocks;
  final int totalStars;
  final RewardItem? nextReward;
  final bool isNewHighScore;

  /// 0..1 progress from the previous star unlock to [nextReward].
  double get progressToNext {
    final next = nextReward?.starsNeeded;
    if (next == null) return 1;
    final prev = RewardCatalog.starUnlocks
        .map((r) => r.starsNeeded!)
        .where((s) => s < next)
        .fold<int>(0, (a, b) => b > a ? b : a);
    return ((totalStars - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  int get starsToNext =>
      nextReward == null ? 0 : (nextReward!.starsNeeded! - totalStars);
}
