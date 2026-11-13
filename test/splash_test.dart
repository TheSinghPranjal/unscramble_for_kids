import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/app.dart';
import 'package:unscramble_for_kids/features/unscramble/data/image_assets.dart';
import 'package:unscramble_for_kids/features/unscramble/data/word_repository.dart';
import 'package:unscramble_for_kids/features/unscramble/presentation/studio_splash.dart';
import 'package:unscramble_for_kids/shared/prefs/prefs.dart';
import 'package:unscramble_for_kids/shared/theme/clay_theme.dart';
import 'package:unscramble_for_kids/shared/theme/kids_palette.dart';
import 'package:unscramble_for_kids/shared/widgets/clay.dart';

import 'helpers.dart';

void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    required Size size,
    ThemeData? theme,
    double textScale = 1,
    ClayPalette palette = ClayPalette.classic,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ClayTheme.build(palette),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: StudioSplash(palette: palette),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: ClayTheme.fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1A1522),
        onSurface: Color(0xFFFFF6E8),
      ),
    );
  }

  testWidgets('splash shows the app name and Lazy Bear Club byline', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpSplash(tester, size: const Size(390, 844));

    expect(find.byKey(const Key('studio-splash')), findsOneWidget);
    expect(find.text('Unscramble'), findsOneWidget);
    expect(find.text('for Kids'), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.byKey(const Key('lazy-bear-club-icon')), findsOneWidget);
    expect(find.byType(KidsBackground), findsOneWidget);

    final icon = tester.widget<Image>(
      find.byKey(const Key('lazy-bear-club-icon')),
    );
    expect(
      (icon.image as AssetImage).assetName,
      'assets/branding/lazy_bear_club.png',
    );

    expect(
      tester.widget<Text>(find.text('The Lazy Bear Club')).style?.color,
      KidsColors.ink,
    );
    expect(
      tester.widget<Text>(find.text('by')).style?.color,
      KidsColors.inkSoft,
    );
    expect(
      tester.widget<Text>(find.text('Unscramble')).style?.color,
      KidsColors.ink,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.bySemanticsLabel('Unscramble for Kids'), findsOneWidget);
    expect(find.bySemanticsLabel('The Lazy Bear Club'), findsOneWidget);
  });

  testWidgets('byline stays on screen for phones, tablets, and large text', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(768, 1024),
      Size(1024, 1366),
      Size(667, 375),
      Size(900, 400),
    ];
    for (final size in sizes) {
      await pumpSplash(tester, size: size);
      expect(find.text('The Lazy Bear Club'), findsOneWidget);
      expect(find.text('by'), findsOneWidget);
      expect(find.text('Unscramble'), findsOneWidget);
    }

    await pumpSplash(tester, size: const Size(320, 568), textScale: 2);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('byline uses light text on the dark theme', (tester) async {
    addTearDown(tester.view.reset);
    const sizes = <Size>[Size(320, 568), Size(390, 844), Size(1024, 768)];
    for (final size in sizes) {
      await pumpSplash(tester, size: size, theme: darkTheme());
      expect(
        tester.widget<Text>(find.text('The Lazy Bear Club')).style?.color,
        const Color(0xFFFFF6E8),
      );
      expect(
        tester.widget<Text>(find.text('by')).style?.color,
        const Color(0xFFE4D7C4),
      );
      // The name sits on a cream clay card, so it stays dark in both themes.
      expect(
        tester.widget<Text>(find.text('Unscramble')).style?.color,
        KidsColors.ink,
      );
      expect(find.byType(KidsBackground), findsNothing);
    }
  });

  testWidgets('splash holds, then reveals the home screen', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;

    final prefs = await mockPrefs();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        wordBankProvider.overrideWith((ref) async => loadRealBank()),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(wordBankProvider.future);
      await container.read(assetKeysProvider.future);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const UnscrambleApp(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();

    expect(find.byKey(const Key('studio-splash')), findsOneWidget);
    expect(find.byKey(const Key('play-button')).hitTestable(), findsNothing);

    await tester.pump(SplashGate.hold);
    expect(find.byKey(const Key('studio-splash')), findsOneWidget);

    await tester.pump(SplashGate.fade);
    expect(find.byKey(const Key('studio-splash')), findsNothing);
    expect(find.byKey(const Key('play-button')).hitTestable(), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsNothing);
  });
}
