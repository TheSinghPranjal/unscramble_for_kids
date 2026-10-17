import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/features/unscramble/application/rewards_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/rewards.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';
import 'package:unscramble_for_kids/shared/prefs/prefs.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StarRules', () {
    StarBreakdown win(
      int length, {
      int lives = 5,
      bool hint = false,
      bool first = false,
      bool daily = false,
      int streak = 1,
    }) => StarRules.forWin(
      length: length,
      livesLeft: lives,
      maxLives: 5,
      usedHint: hint,
      firstClear: first,
      dailyBonus: daily,
      streak: streak,
    );

    test('performance stars per length: 3→1–3, 4→2–4, 5→3–5', () {
      for (final (n, lo, hi) in [(3, 1, 3), (4, 2, 4), (5, 3, 5)]) {
        expect(win(n).base, hi, reason: 'perfect $n');
        expect(win(n, lives: 2, hint: true).base, lo, reason: 'rough $n');
        expect(win(n, lives: 4).base, hi - 1);
        expect(win(n).baseMax, hi);
      }
    });

    test(
      'bonuses: first clear +1, daily +2, streak +1 per win capped at 5',
      () {
        expect(win(3, first: true).firstClear, 1);
        expect(win(3, daily: true).daily, 2);
        expect(win(3, streak: 1).streak, 0);
        expect(win(3, streak: 2).streak, 1);
        expect(win(3, streak: 6).streak, 5);
        expect(win(3, streak: 40).streak, 5);
        expect(
          win(3, first: true, daily: true, streak: 3).total,
          3 + 1 + 2 + 2,
        );
      },
    );

    test('score: base by length + lives + time + no-hint bonus', () {
      expect(
        StarRules.score(length: 3, livesLeft: 5, usedHint: false),
        10 + 10 + 5,
      );
      expect(
        StarRules.score(
          length: 5,
          livesLeft: 1,
          secondsLeft: 50,
          usedHint: true,
        ),
        30 + 2 + 10,
      );
    });
  });

  group('RewardsController', () {
    final cat = word('CAT', 'Animals');

    WinReward recordWin(
      RewardsController c,
      WordEntry e, {
      bool hint = false,
    }) => c.recordWin(
      entry: e,
      livesLeft: 5,
      maxLives: 5,
      usedHint: hint,
      mistakes: 0,
      points: 25,
      sessionScore: 25,
    );

    test('first win grants stars, Word Rookie and Perfect Round', () async {
      final c = await makeContainer(clock: TestClock());
      final reward = recordWin(c.read(rewardsControllerProvider.notifier), cat);
      // 3 base + 1 first clear + 2 daily.
      expect(reward.stars.total, 6);
      expect(c.read(rewardsControllerProvider).totalStars, 6);
      expect(
        reward.newUnlocks.map((r) => r.id),
        containsAll([
          'badge_word_rookie',
          'badge_perfect_round',
          'sticker_happy_star',
        ]),
      );
      expect(reward.nextReward?.id, 'sticker_rainbow_cat');
      expect(reward.starsToNext, 6);
    });

    test('progress persists across app restarts', () async {
      final prefs = await mockPrefs();
      final c1 = await makeContainer(prefs: prefs, clock: TestClock());
      recordWin(c1.read(rewardsControllerProvider.notifier), cat);
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString(PrefKeys.progress), isNotNull);

      final c2 = await makeContainer(prefs: prefs, clock: TestClock());
      final p = c2.read(rewardsControllerProvider);
      expect(p.totalStars, 6);
      expect(p.wins, 1);
      expect(p.unlocked, contains('badge_word_rookie'));
      expect(p.solvedWordIds, contains(cat.id));
    });

    test(
      'daily bonus once per local date; first-clear once per word',
      () async {
        final clock = TestClock();
        final c = await makeContainer(clock: clock);
        final ctrl = c.read(rewardsControllerProvider.notifier);
        expect(recordWin(ctrl, cat).stars.daily, 2);
        final again = recordWin(ctrl, cat);
        expect(again.stars.daily, 0);
        expect(again.stars.firstClear, 0);
        expect(again.stars.streak, 1);
        clock.now = clock.now.add(const Duration(days: 1));
        expect(recordWin(ctrl, cat).stars.daily, 2);
      },
    );

    test('a loss resets the streak but never removes stars', () async {
      final c = await makeContainer(clock: TestClock());
      final ctrl = c.read(rewardsControllerProvider.notifier);
      recordWin(ctrl, cat);
      recordWin(ctrl, word('DOG', 'Animals'));
      final before = c.read(rewardsControllerProvider);
      expect(before.currentStreak, 2);
      ctrl.recordLoss();
      final after = c.read(rewardsControllerProvider);
      expect(after.currentStreak, 0);
      expect(after.bestStreak, 2);
      expect(after.totalStars, before.totalStars);
    });

    test(
      'Category Explorer unlocks after a win in all 10 categories',
      () async {
        final c = await makeContainer(clock: TestClock());
        final ctrl = c.read(rewardsControllerProvider.notifier);
        final bank = loadRealBank();
        for (final category in bank.categories.take(9)) {
          recordWin(ctrl, bank.wordsFor(length: 3, category: category).first);
        }
        expect(
          c.read(rewardsControllerProvider).unlocked,
          isNot(contains('badge_category_explorer')),
        );
        final last = recordWin(
          ctrl,
          bank.wordsFor(length: 3, category: bank.categories.last).first,
        );
        expect(
          last.newUnlocks.map((r) => r.id),
          contains('badge_category_explorer'),
        );
      },
    );

    test('No-Hint Hero counts only hint-free wins', () async {
      final c = await makeContainer(clock: TestClock());
      final ctrl = c.read(rewardsControllerProvider.notifier);
      for (var i = 0; i < 5; i++) {
        recordWin(ctrl, cat, hint: true);
      }
      expect(c.read(rewardsControllerProvider).noHintWins, 0);
      for (var i = 0; i < 10; i++) {
        recordWin(ctrl, cat);
      }
      expect(
        c.read(rewardsControllerProvider).unlocked,
        contains('badge_no_hint_hero'),
      );
    });

    test('themes equip only once unlocked', () async {
      final c = await makeContainer(clock: TestClock());
      final ctrl = c.read(rewardsControllerProvider.notifier);
      expect(ctrl.equipTheme('sunshine'), isFalse);
      expect(c.read(activePaletteProvider).id, 'classic');
      while (c.read(rewardsControllerProvider).totalStars < 30) {
        recordWin(ctrl, cat);
      }
      expect(ctrl.equipTheme('sunshine'), isTrue);
      expect(c.read(activePaletteProvider).id, 'sunshine');
      expect(
        ctrl.equipTheme('ocean'),
        c.read(rewardsControllerProvider).totalStars >= 50,
      );
    });

    test('reset clears all progress', () async {
      final c = await makeContainer(clock: TestClock());
      final ctrl = c.read(rewardsControllerProvider.notifier);
      recordWin(ctrl, cat);
      await ctrl.reset();
      expect(c.read(rewardsControllerProvider).isFresh, isTrue);
      expect(c.read(rewardsControllerProvider).unlocked, isEmpty);
    });

    test('corrupt saved progress falls back to a fresh start', () async {
      final prefs = await mockPrefs({PrefKeys.progress: '{not json'});
      final c = await makeContainer(prefs: prefs);
      expect(c.read(rewardsControllerProvider).isFresh, isTrue);
    });
  });
}
