import 'package:flutter/foundation.dart';

import 'rewards.dart';
import 'word_entry.dart';

/// A letter in the tray. Ids are unique per round so words with repeated
/// letters (BOOK, BALL, APPLE) work with drag/tap.
@immutable
class LetterTile {
  const LetterTile(this.id, this.letter);

  final int id;
  final String letter;
}

enum RoundStatus { idle, playing, paused, won, lost }

enum LoseReason { outOfLives, timeUp }

@immutable
class GameConfig {
  const GameConfig({this.length = LengthMode.three, this.category});

  final LengthMode length;

  /// `null` = All Categories.
  final String? category;

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.length == length &&
      other.category == category;

  @override
  int get hashCode => Object.hash(length, category);
}

@immutable
class GameState {
  const GameState({
    this.status = RoundStatus.idle,
    this.config = const GameConfig(),
    this.entry,
    this.tiles = const [],
    this.slots = const [],
    this.lives = maxLives,
    this.mistakes = 0,
    this.hintUsed = false,
    this.hintFlash = false,
    this.secondsLeft,
    this.sessionScore = 0,
    this.roundsPlayed = 0,
    this.selectedSlot,
    this.wrongTick = 0,
    this.lastWrongTileId,
    this.correctTick = 0,
    this.lastLockedSlot,
    this.loseReason,
    this.lastWin,
    this.emptyDeck = false,
  });

  /// 5 soft heart lives (kids mode).
  static const maxLives = 5;

  /// Free hint unlocks after this many mistakes in a round.
  static const hintUnlockMistakes = 2;

  /// Timer length per word size, in seconds.
  static int timeLimitFor(int length) => switch (length) {
    3 => 60,
    4 => 90,
    _ => 120,
  };

  final RoundStatus status;
  final GameConfig config;
  final WordEntry? entry;
  final List<LetterTile> tiles;

  /// Slot index → id of the tile locked there (`null` = empty).
  final List<int?> slots;
  final int lives;
  final int mistakes;
  final bool hintUsed;

  /// True right after a hint: picture pulses and hint text is shown.
  final bool hintFlash;

  /// `null` when the timer is turned off.
  final int? secondsLeft;
  final int sessionScore;
  final int roundsPlayed;
  final int? selectedSlot;

  /// Increments on every wrong letter (drives the shake animation).
  final int wrongTick;
  final int? lastWrongTileId;

  /// Increments on every correct letter (drives the bounce animation).
  final int correctTick;
  final int? lastLockedSlot;
  final LoseReason? loseReason;
  final WinReward? lastWin;

  /// The chosen length/category filter has no words.
  final bool emptyDeck;

  bool get timerEnabled => secondsLeft != null;
  bool get isPlaying => status == RoundStatus.playing;
  bool get hintUnlocked => mistakes >= hintUnlockMistakes;
  bool get canUseHint => isPlaying && hintUnlocked && !hintUsed;
  int get mistakesUntilHint =>
      (hintUnlockMistakes - mistakes).clamp(0, hintUnlockMistakes);

  Set<int> get placedTileIds => {...slots.whereType<int>()};

  List<LetterTile> get trayTiles => [
    for (final t in tiles)
      if (!placedTileIds.contains(t.id)) t,
  ];

  LetterTile? tileById(int id) {
    for (final t in tiles) {
      if (t.id == id) return t;
    }
    return null;
  }

  String? letterAt(int slot) {
    final id = slots[slot];
    return id == null ? null : tileById(id)?.letter;
  }

  int? get nextEmptySlot {
    final i = slots.indexOf(null);
    return i < 0 ? null : i;
  }

  bool get isComplete => slots.isNotEmpty && !slots.contains(null);

  GameState copyWith({
    RoundStatus? status,
    GameConfig? config,
    WordEntry? entry,
    List<LetterTile>? tiles,
    List<int?>? slots,
    int? lives,
    int? mistakes,
    bool? hintUsed,
    bool? hintFlash,
    int? Function()? secondsLeft,
    int? sessionScore,
    int? roundsPlayed,
    int? Function()? selectedSlot,
    int? wrongTick,
    int? Function()? lastWrongTileId,
    int? correctTick,
    int? Function()? lastLockedSlot,
    LoseReason? Function()? loseReason,
    WinReward? Function()? lastWin,
    bool? emptyDeck,
  }) {
    return GameState(
      status: status ?? this.status,
      config: config ?? this.config,
      entry: entry ?? this.entry,
      tiles: tiles ?? this.tiles,
      slots: slots ?? this.slots,
      lives: lives ?? this.lives,
      mistakes: mistakes ?? this.mistakes,
      hintUsed: hintUsed ?? this.hintUsed,
      hintFlash: hintFlash ?? this.hintFlash,
      secondsLeft: secondsLeft != null ? secondsLeft() : this.secondsLeft,
      sessionScore: sessionScore ?? this.sessionScore,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      wrongTick: wrongTick ?? this.wrongTick,
      lastWrongTileId: lastWrongTileId != null
          ? lastWrongTileId()
          : this.lastWrongTileId,
      correctTick: correctTick ?? this.correctTick,
      lastLockedSlot: lastLockedSlot != null
          ? lastLockedSlot()
          : this.lastLockedSlot,
      loseReason: loseReason != null ? loseReason() : this.loseReason,
      lastWin: lastWin != null ? lastWin() : this.lastWin,
      emptyDeck: emptyDeck ?? this.emptyDeck,
    );
  }
}
