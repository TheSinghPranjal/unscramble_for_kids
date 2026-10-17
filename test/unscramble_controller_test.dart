import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/features/unscramble/application/rewards_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/application/unscramble_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/game_state.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';
import 'package:unscramble_for_kids/shared/prefs/prefs.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(UnscrambleController, GameState Function())> startGame({
    GameConfig config = const GameConfig(),
    List<WordEntry>? words,
    Map<String, Object> prefs = const {},
  }) async {
    final c = await makeContainer(
      bank: words == null ? null : smallBank(words),
      prefs: await mockPrefs(prefs),
      clock: TestClock(),
    );
    final ctrl = c.read(unscrambleControllerProvider.notifier)..start(config);
    return (ctrl, () => c.read(unscrambleControllerProvider));
  }

  test('deals only the selected length', () async {
    for (final mode in LengthMode.values) {
      final (ctrl, read) = await startGame(config: GameConfig(length: mode));
      for (var i = 0; i < 30; i++) {
        expect(read().entry!.length, mode.length);
        expect(read().slots, hasLength(mode.length));
        expect(read().tiles, hasLength(mode.length));
        ctrl.nextWord();
      }
    }
  });

  test('category filter deals only that category', () async {
    final (ctrl, read) = await startGame(
      config: const GameConfig(length: LengthMode.five, category: 'Food'),
    );
    for (var i = 0; i < 25; i++) {
      expect(read().entry!.category, 'Food');
      ctrl.nextWord();
    }
  });

  test('deck reshuffles after exhaustion with no immediate repeat', () async {
    final (ctrl, read) = await startGame(
      config: const GameConfig(length: LengthMode.four, category: 'Colors'),
    );
    final seen = <String>[];
    for (var i = 0; i < 30; i++) {
      seen.add(read().entry!.word);
      ctrl.nextWord();
    }
    expect(seen.take(10).toSet(), hasLength(10));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], isNot(seen[i - 1]));
    }
  });

  test('empty filter → emptyDeck, no crash', () async {
    final (_, read) = await startGame(
      config: const GameConfig(category: 'Food'),
      words: [word('CAT', 'Animals')],
    );
    expect(read().emptyDeck, isTrue);
    expect(read().entry, isNull);
  });

  test('round state carries the mapped image path', () async {
    final (_, read) = await startGame();
    final e = read().entry!;
    expect(e.imagePath, WordEntry.expectedImagePath(e.word));
  });

  test(
    'correct letter locks; wrong letter costs a life and stays in tray',
    () async {
      final (ctrl, read) = await startGame(words: [word('CAT', 'Animals')]);
      final c = read().trayTiles.firstWhere((t) => t.letter == 'C');
      ctrl.placeTile(c.id);
      expect(read().letterAt(0), 'C');
      expect(read().correctTick, 1);

      final t = read().trayTiles.firstWhere((t) => t.letter == 'T');
      ctrl.placeTile(t.id);
      expect(read().lives, GameState.maxLives - 1);
      expect(read().mistakes, 1);
      expect(read().letterAt(1), isNull);
      expect(read().trayTiles.map((x) => x.id), contains(t.id));
      expect(read().lastWrongTileId, t.id);
    },
  );

  test('drag onto a specific slot / tap slot then letter', () async {
    final (ctrl, read) = await startGame(words: [word('CAT', 'Animals')]);
    final t = read().trayTiles.firstWhere((x) => x.letter == 'T');
    ctrl.placeTile(t.id, slot: 2);
    expect(read().letterAt(2), 'T');

    ctrl.selectSlot(1);
    expect(read().selectedSlot, 1);
    final a = read().trayTiles.firstWhere((x) => x.letter == 'A');
    ctrl.placeTile(a.id);
    expect(read().letterAt(1), 'A');
    expect(read().selectedSlot, isNull);
  });

  test('duplicate-letter words (BOOK, APPLE) accept either copy', () async {
    for (final w in ['BOOK', 'APPLE', 'BALL']) {
      final (ctrl, read) = await startGame(
        config: GameConfig(length: LengthMode.fromLength(w.length)),
        words: [word(w, 'Toys')],
      );
      final ids = read().tiles.map((t) => t.id).toSet();
      expect(ids, hasLength(w.length), reason: 'unique tile ids');
      // Place the LAST matching tile first for each slot.
      while (read().isPlaying) {
        final s = read();
        final want = s.entry!.word[s.nextEmptySlot!];
        ctrl.placeTile(s.trayTiles.lastWhere((t) => t.letter == want).id);
      }
      expect(read().status, RoundStatus.won, reason: w);
      expect(read().mistakes, 0);
    }
  });

  test('win grants stars, badges and score', () async {
    final (ctrl, read) = await startGame(words: [word('CAT', 'Animals')]);
    solve(ctrl, read);
    final s = read();
    expect(s.status, RoundStatus.won);
    expect(s.lastWin, isNotNull);
    expect(s.lastWin!.stars.base, 3);
    expect(s.sessionScore, s.lastWin!.points);
    expect(
      s.lastWin!.newUnlocks.map((r) => r.id),
      contains('badge_word_rookie'),
    );
  });

  test('hint unlocks after 2 mistakes and works once per round', () async {
    final (ctrl, read) = await startGame(
      words: [word('FROG', 'Animals')],
      config: const GameConfig(length: LengthMode.four),
    );
    expect(read().canUseHint, isFalse);
    ctrl.useHint();
    expect(read().hintUsed, isFalse);

    tapWrong(ctrl, read());
    expect(read().canUseHint, isFalse);
    tapWrong(ctrl, read());
    expect(read().canUseHint, isTrue);

    ctrl.useHint();
    expect(read().hintUsed, isTrue);
    expect(read().hintFlash, isTrue);
    expect(read().letterAt(0), 'F');

    tapWrong(ctrl, read());
    ctrl.useHint();
    expect(read().letterAt(1), isNull, reason: 'second hint ignored');

    ctrl.retry();
    expect(read().hintUsed, isFalse, reason: 'new round, new hint');
    expect(read().mistakes, 0);
  });

  test('5 mistakes → kind lose state, streak reset', () async {
    final (ctrl, read) = await startGame(words: [word('CAT', 'Animals')]);
    for (var i = 0; i < GameState.maxLives; i++) {
      tapWrong(ctrl, read());
    }
    expect(read().status, RoundStatus.lost);
    expect(read().loseReason, LoseReason.outOfLives);
    ctrl.placeTile(read().trayTiles.first.id);
    expect(read().status, RoundStatus.lost, reason: 'input ignored');

    ctrl.retry();
    expect(read().status, RoundStatus.playing);
    expect(read().lives, GameState.maxLives);
    expect(read().entry!.word, 'CAT');
  });

  test('timer is off for 3 letters by default and on for 4/5', () async {
    final (_, r3) = await startGame();
    expect(r3().timerEnabled, isFalse);
    expect(r3().secondsLeft, isNull);

    final (_, r4) = await startGame(
      config: const GameConfig(length: LengthMode.four),
    );
    expect(r4().secondsLeft, GameState.timeLimitFor(4));
  });

  test('disabled timer: ticking does nothing', () async {
    final (ctrl, read) = await startGame(
      config: const GameConfig(length: LengthMode.five),
      prefs: {'${PrefKeys.timerPrefix}5': false},
    );
    ctrl.tick();
    expect(read().secondsLeft, isNull);
    expect(read().status, RoundStatus.playing);
  });

  test('timer running out → time-up lose', () async {
    final (ctrl, read) = await startGame(
      config: const GameConfig(length: LengthMode.four),
    );
    for (var i = 0; i < GameState.timeLimitFor(4); i++) {
      ctrl.tick();
    }
    expect(read().status, RoundStatus.lost);
    expect(read().loseReason, LoseReason.timeUp);
  });

  test('pause freezes the clock and input; resume continues', () async {
    final (ctrl, read) = await startGame(
      config: const GameConfig(length: LengthMode.four),
    );
    ctrl.pause();
    expect(read().status, RoundStatus.paused);
    final left = read().secondsLeft;
    ctrl.tick();
    expect(read().secondsLeft, left);
    ctrl.placeTile(read().trayTiles.first.id);
    expect(read().placedTileIds, isEmpty);
    ctrl.resume();
    ctrl.tick();
    expect(read().secondsLeft, left! - 1);
  });

  test('leaving the game screen pauses the round', () async {
    final (ctrl, read) = await startGame();
    ctrl.leave();
    await Future<void>.delayed(Duration.zero);
    expect(read().status, RoundStatus.paused);
  });

  test('wins update the shared rewards state and streak', () async {
    final c = await makeContainer(clock: TestClock());
    final ctrl = c.read(unscrambleControllerProvider.notifier)
      ..start(const GameConfig());
    GameState read() => c.read(unscrambleControllerProvider);
    solve(ctrl, read);
    ctrl.nextWord();
    solve(ctrl, read);
    final p = c.read(rewardsControllerProvider);
    expect(p.wins, 2);
    expect(p.currentStreak, 2);
    expect(p.winsFor(3), 2);
    expect(p.highScore, read().sessionScore);
  });
}
