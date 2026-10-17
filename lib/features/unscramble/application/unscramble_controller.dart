import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/feedback/sfx.dart';
import '../../../shared/prefs/app_settings.dart';
import '../data/word_repository.dart';
import '../domain/game_state.dart';
import '../domain/rewards.dart';
import '../domain/word_entry.dart';
import 'rewards_controller.dart';
import 'word_deck.dart';

/// Randomness seam (seeded in tests).
final randomProvider = Provider<Random>((ref) => Random());

final unscrambleControllerProvider =
    NotifierProvider<UnscrambleController, GameState>(UnscrambleController.new);

class UnscrambleController extends Notifier<GameState> {
  WordDeck? _deck;
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(_stopTimer);
    return const GameState();
  }

  Sfx get _sfx => ref.read(sfxProvider);

  /// Starts a session for [config]. Deals only words of the selected length
  /// (and category, when one is chosen).
  void start(GameConfig config) {
    _stopTimer();
    final bank = ref.read(wordBankProvider).value;
    final words =
        bank?.wordsFor(
          length: config.length.length,
          category: config.category,
        ) ??
        const <WordEntry>[];
    if (words.isEmpty) {
      _deck = null;
      state = GameState(config: config, emptyDeck: true);
      return;
    }
    _deck = WordDeck(
      words,
      random: ref.read(randomProvider),
      easyFirst: ref.read(settingsProvider).easyFirst,
    );
    state = GameState(config: config);
    _deal(_deck!.next());
  }

  /// Deals the next word in the deck (reshuffles after exhaustion).
  void nextWord() {
    final deck = _deck;
    if (deck == null || deck.isEmpty) return;
    _deal(deck.next());
  }

  /// Replays the same word from scratch ("Try Again").
  void retry() {
    final entry = state.entry;
    if (entry != null) _deal(entry);
  }

  void _deal(WordEntry entry) {
    _stopTimer();
    final letters = scrambleLetters(entry.word, ref.read(randomProvider));
    final timerOn = ref.read(settingsProvider).timerFor(entry.length);
    state = state.copyWith(
      status: RoundStatus.playing,
      entry: entry,
      tiles: [
        for (var i = 0; i < letters.length; i++) LetterTile(i, letters[i]),
      ],
      slots: List<int?>.filled(entry.length, null),
      lives: GameState.maxLives,
      mistakes: 0,
      hintUsed: false,
      hintFlash: false,
      secondsLeft: () => timerOn ? GameState.timeLimitFor(entry.length) : null,
      roundsPlayed: state.roundsPlayed + 1,
      selectedSlot: () => null,
      lastWrongTileId: () => null,
      lastLockedSlot: () => null,
      loseReason: () => null,
      lastWin: () => null,
    );
    _startTimer();
  }

  /// Tap-a-slot-then-a-letter support. Tapping the selected slot again
  /// clears the selection.
  void selectSlot(int slot) {
    if (!state.isPlaying || state.slots[slot] != null) return;
    state = state.copyWith(
      selectedSlot: () => state.selectedSlot == slot ? null : slot,
    );
  }

  /// Places [tileId] into [slot] (drag target), else the selected slot,
  /// else the next empty slot. Correct → locks; wrong → life lost, tile
  /// stays in the tray.
  void placeTile(int tileId, {int? slot}) {
    final s = state;
    final entry = s.entry;
    if (!s.isPlaying || entry == null) return;
    final tile = s.tileById(tileId);
    if (tile == null || s.placedTileIds.contains(tileId)) return;

    var target = slot ?? s.selectedSlot ?? s.nextEmptySlot;
    if (target == null) return;
    if (s.slots[target] != null) {
      target = s.nextEmptySlot;
      if (target == null) return;
    }

    if (entry.word[target] == tile.letter) {
      _lock(tileId, target);
    } else {
      _wrong(tileId);
    }
  }

  void _lock(int tileId, int slot, {bool viaHint = false}) {
    final slots = [...state.slots]..[slot] = tileId;
    state = state.copyWith(
      slots: slots,
      selectedSlot: () => null,
      correctTick: state.correctTick + 1,
      lastLockedSlot: () => slot,
      hintUsed: viaHint ? true : null,
      hintFlash: viaHint ? true : null,
    );
    _sfx.correct();
    if (state.isComplete) _win();
  }

  void _wrong(int tileId) {
    final lives = state.lives - 1;
    state = state.copyWith(
      lives: lives,
      mistakes: state.mistakes + 1,
      wrongTick: state.wrongTick + 1,
      lastWrongTileId: () => tileId,
      selectedSlot: () => null,
    );
    _sfx.wrong();
    if (lives <= 0) _lose(LoseReason.outOfLives);
  }

  /// One free hint per round, unlocked after a few mistakes: reveals the
  /// next correct letter and flashes the picture + hint text.
  void useHint() {
    final s = state;
    final entry = s.entry;
    if (!s.canUseHint || entry == null) return;
    final slot = s.nextEmptySlot;
    if (slot == null) return;
    final placed = s.placedTileIds;
    final tile = s.tiles.firstWhere(
      (t) => !placed.contains(t.id) && t.letter == entry.word[slot],
    );
    _lock(tile.id, slot, viaHint: true);
  }

  void dismissHintFlash() {
    if (state.hintFlash) state = state.copyWith(hintFlash: false);
  }

  void pause() {
    if (!state.isPlaying) return;
    _stopTimer();
    state = state.copyWith(status: RoundStatus.paused);
  }

  void resume() {
    if (state.status != RoundStatus.paused) return;
    state = state.copyWith(status: RoundStatus.playing);
    _startTimer();
  }

  /// Called when the game screen goes away: stop the clock, keep the round.
  void leave() {
    _stopTimer();
    if (ref.mounted && state.isPlaying) {
      // Deferred: may be called while the widget tree is being torn down.
      scheduleMicrotask(() {
        if (ref.mounted) pause();
      });
    }
  }

  void _win() {
    _stopTimer();
    final s = state;
    final entry = s.entry!;
    final points = StarRules.score(
      length: entry.length,
      livesLeft: s.lives,
      secondsLeft: s.secondsLeft,
      usedHint: s.hintUsed,
    );
    final sessionScore = s.sessionScore + points;
    final reward = ref
        .read(rewardsControllerProvider.notifier)
        .recordWin(
          entry: entry,
          livesLeft: s.lives,
          maxLives: GameState.maxLives,
          usedHint: s.hintUsed,
          mistakes: s.mistakes,
          points: points,
          sessionScore: sessionScore,
        );
    state = s.copyWith(
      status: RoundStatus.won,
      sessionScore: sessionScore,
      lastWin: () => reward,
    );
    _sfx.win();
  }

  void _lose(LoseReason reason) {
    _stopTimer();
    ref.read(rewardsControllerProvider.notifier).recordLoss();
    state = state.copyWith(
      status: RoundStatus.lost,
      loseReason: () => reason,
      selectedSlot: () => null,
    );
  }

  void _startTimer() {
    if (!state.timerEnabled || !state.isPlaying) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// One second of the round clock (public for tests).
  void tick() {
    final left = state.secondsLeft;
    if (!state.isPlaying || left == null) return;
    final next = left - 1;
    state = state.copyWith(secondsLeft: () => next < 0 ? 0 : next);
    if (next <= 0) _lose(LoseReason.timeUp);
  }
}
