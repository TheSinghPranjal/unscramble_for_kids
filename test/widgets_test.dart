import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/app.dart';
import 'package:unscramble_for_kids/features/unscramble/application/boot.dart';
import 'package:unscramble_for_kids/features/unscramble/application/unscramble_controller.dart';
import 'package:unscramble_for_kids/features/unscramble/data/image_assets.dart';
import 'package:unscramble_for_kids/features/unscramble/data/word_repository.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/game_state.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';
import 'package:unscramble_for_kids/features/unscramble/presentation/game_screen.dart';
import 'package:unscramble_for_kids/features/unscramble/presentation/rewards_screen.dart';
import 'package:unscramble_for_kids/features/unscramble/presentation/word_library_screen.dart';
import 'package:unscramble_for_kids/features/unscramble/presentation/widgets/word_picture.dart';
import 'package:unscramble_for_kids/shared/prefs/prefs.dart';

import 'helpers.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    Widget home, {
    Map<String, Object> prefs = const {},
    List<WordEntry>? words,
    Size size = const Size(430, 932),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = await mockPrefs(prefs);
    final bank = words == null ? loadRealBank() : smallBank(words);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        wordBankProvider.overrideWith((ref) async => bank),
        randomProvider.overrideWithValue(Random(1)),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(wordBankProvider.future);
      await container.read(assetKeysProvider.future);
      // Reads every image's bytes for real, outside fake async; this also
      // fills the placeholder cache used by WordPicture.
      await container.read(imageAuditProvider.future);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: home),
    );
    // Futures created during runAsync complete in the real zone; give them
    // one real tick, then a frame.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    return container;
  }

  testWidgets('app boots to the clay home with 3 letters selected', (
    tester,
  ) async {
    final c = await pumpApp(tester, const UnscrambleApp());
    await tester.pump();
    expect(c.read(bootProvider).hasValue, isTrue);

    expect(find.byKey(const Key('play-button')), findsOneWidget);
    expect(find.text('100 3-letter words ready'), findsOneWidget);
    final three = tester.getSemantics(find.byKey(const Key('length-3')));
    expect(three.label, contains('3 Letters'));

    await tester.tap(find.byKey(const Key('length-5')));
    await tester.pump();
    expect(find.text('100 5-letter words ready'), findsOneWidget);
  });

  testWidgets('game screen shows the picture clue, slots and tray', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      const MaterialApp(home: GameScreen()),
      words: [word('CAT', 'Animals', hint: 'Says meow')],
    );
    c.read(unscrambleControllerProvider.notifier).start(const GameConfig());
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('picture-clue')), findsOneWidget);
    expect(find.byType(WordPicture), findsOneWidget);
    expect(find.bySemanticsLabel('Picture of a cat'), findsOneWidget);
    expect(find.textContaining('Says meow'), findsOneWidget);
    expect(find.text('Animals'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('slot-$i')), findsOneWidget);
      expect(find.byKey(Key('tile-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('timer-pill')), findsNothing);
  });

  testWidgets('solving by tapping letters shows the win dialog', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      const MaterialApp(home: GameScreen()),
      words: [word('CAT', 'Animals'), word('DOG', 'Animals')],
      prefs: {PrefKeys.coachSeen: true},
    );
    final ctrl = c.read(unscrambleControllerProvider.notifier)
      ..start(const GameConfig());
    await tester.pump();

    final s = c.read(unscrambleControllerProvider);
    for (final letter in s.entry!.word.split('')) {
      final tile = c
          .read(unscrambleControllerProvider)
          .trayTiles
          .firstWhere((t) => t.letter == letter);
      await tester.tap(find.byKey(Key('tile-${tile.id}')));
      await tester.pump();
    }
    expect(c.read(unscrambleControllerProvider).status, RoundStatus.won);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('win-dialog')), findsOneWidget);
    expect(find.text('You did it! 🎉'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('next-word')));
    await tester.tap(find.byKey(const Key('next-word')));
    // The exit transition needs several frames to run.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const Key('win-dialog')), findsNothing);
    expect(c.read(unscrambleControllerProvider).isPlaying, isTrue);
    expect(ctrl.state.entry!.word, isNot(s.entry!.word));
  });

  testWidgets('pause shows the break overlay and resume hides it', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      const MaterialApp(home: GameScreen()),
      words: [word('CAT', 'Animals')],
    );
    c.read(unscrambleControllerProvider.notifier).start(const GameConfig());
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause-button')));
    await tester.pump();
    expect(find.byKey(const Key('paused-overlay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume-button')));
    await tester.pump();
    expect(find.byKey(const Key('paused-overlay')), findsNothing);
  });

  testWidgets('game layout fits a small landscape phone', (tester) async {
    final c = await pumpApp(
      tester,
      const MaterialApp(home: GameScreen()),
      words: [word('APPLE', 'Food')],
      size: const Size(640, 360),
    );
    c
        .read(unscrambleControllerProvider.notifier)
        .start(const GameConfig(length: LengthMode.five));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('picture-clue')), findsOneWidget);
  });

  testWidgets('Word & Image Library lists all 300 words with status', (
    tester,
  ) async {
    await pumpApp(tester, const MaterialApp(home: WordLibraryScreen()));
    await tester.pump();

    expect(find.textContaining('Showing 300 of 300 words'), findsOneWidget);
    expect(find.textContaining('300 placeholder'), findsOneWidget);
    expect(find.byKey(const Key('word-row-CAT')), findsOneWidget);
    expect(find.text('assets/images/words/3_letter/cat.png'), findsOneWidget);

    await tester.tap(find.text('4 letters'));
    await tester.pump();
    expect(find.textContaining('Showing 100 of 300'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('library-search')), 'frog');
    await tester.pump();
    expect(find.textContaining('Showing 1 of 300'), findsOneWidget);
    expect(find.byKey(const Key('word-row-FROG')), findsOneWidget);

    await tester.tap(find.byKey(const Key('word-row-FROG')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('frog.png'), findsOneWidget);
  });

  testWidgets('rewards shows the empty state for a new player', (tester) async {
    await pumpApp(tester, const MaterialApp(home: RewardsScreen()));
    await tester.pump();
    expect(find.byKey(const Key('rewards-empty')), findsOneWidget);
    expect(find.text('Play to earn your first star!'), findsOneWidget);
    expect(find.text('Happy Star'), findsOneWidget);
  });
}
