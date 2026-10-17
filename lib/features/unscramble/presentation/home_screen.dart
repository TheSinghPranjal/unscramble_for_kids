import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/prefs/app_settings.dart';
import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../application/rewards_controller.dart';
import '../application/unscramble_controller.dart';
import '../data/word_repository.dart';
import '../domain/game_state.dart';
import '../domain/word_entry.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

/// Home: brand, progress, length + category pickers and the big Play button.
/// Rendered inside the boot screen once words are loaded.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    // Warm the image cache lightly: the first few pictures of the deck.
    final settings = ref.read(settingsProvider);
    final bank = ref.read(wordBankProvider).value;
    for (final w
        in bank?.wordsFor(length: settings.defaultLength).take(6) ??
            const <WordEntry>[]) {
      precacheImage(AssetImage(w.imagePath), context, onError: (_, _) {});
    }
  }

  Future<void> _play(GameConfig config) async {
    final settings = ref.read(settingsProvider);
    final nav = Navigator.of(context);
    if (!settings.coachSeen) {
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const HowToPlayScreen(firstRun: true),
        ),
      );
      if (!mounted) return;
    }
    ref.read(unscrambleControllerProvider.notifier).start(config);
    await nav.push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(rewardsControllerProvider);
    final palette = ref.watch(activePaletteProvider);
    final bank = ref.watch(wordBankProvider).value;
    final length = LengthMode.fromLength(settings.defaultLength);
    final category = settings.defaultCategory;
    final count =
        bank?.wordsFor(length: length.length, category: category).length ?? 0;

    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _CloudsPainter())),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
              children: [
                const _Brand(),
                const SizedBox(height: 17.6),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        emoji: '🏆',
                        label: 'High score',
                        value: '${progress.highScore}',
                        color: KidsColors.peach,
                      ),
                    ),
                    const SizedBox(width: 9.6),
                    Expanded(
                      child: _StatCard(
                        emoji: '⭐',
                        label: 'Stars',
                        value: '${progress.totalStars}',
                        color: KidsColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 9.6),
                    Expanded(
                      child: _StatCard(
                        emoji: '🔥',
                        label: 'Streak',
                        value: '${progress.currentStreak}',
                        color: KidsColors.mint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.8),
                const _Heading('How many letters?'),
                Row(
                  children: [
                    for (final mode in LengthMode.values) ...[
                      if (mode != LengthMode.three) const SizedBox(width: 9.6),
                      Expanded(
                        child: _LengthCard(
                          mode: mode,
                          selected: mode == length,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setDefaultLength(mode.length);
                            final n =
                                bank
                                    ?.wordsFor(
                                      length: mode.length,
                                      category: category,
                                    )
                                    .length ??
                                0;
                            if (n == 0) _toastEmpty(mode, category);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 19.2),
                const _Heading('Pick a topic'),
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _CategoryPill(
                        label: 'All',
                        emoji: '🌈',
                        selected: category == null,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setDefaultCategory(null),
                      ),
                      for (final c in bank?.categories ?? const <String>[])
                        _CategoryPill(
                          label: c,
                          emoji: KidsColors.categoryEmoji[c] ?? '✨',
                          selected: category == c,
                          color: KidsColors.forCategory(c),
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setDefaultCategory(c);
                            if (bank!
                                .wordsFor(length: length.length, category: c)
                                .isEmpty) {
                              _toastEmpty(length, c);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 17.6),
                _PlayButton(
                  color: palette.primary,
                  onPressed: count == 0
                      ? null
                      : () => _play(
                          GameConfig(length: length, category: category),
                        ),
                ),
                const SizedBox(height: 9.6),
                Text(
                  count == 0
                      ? 'No words here yet — pick another topic!'
                      : '$count ${length.length}-letter words ready',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w500,
                    color: KidsColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 20.8),
                Row(
                  children: [
                    Expanded(
                      child: _HomeAction(
                        label: 'Rewards',
                        icon: const Text('🏆', style: TextStyle(fontSize: 32)),
                        color: KidsColors.yellow,
                        onTap: () => _push(const RewardsScreen()),
                      ),
                    ),
                    const SizedBox(width: 9.6),
                    Expanded(
                      child: _HomeAction(
                        label: 'How to Play',
                        icon: const _HelpBadge(),
                        color: KidsColors.sky,
                        onTap: () => _push(const HowToPlayScreen()),
                      ),
                    ),
                    const SizedBox(width: 9.6),
                    Expanded(
                      child: _HomeAction(
                        label: 'Settings',
                        icon: const Icon(
                          Icons.settings_rounded,
                          size: 36.8,
                          color: _settingsInk,
                          shadows: [
                            Shadow(
                              color: Colors.white54,
                              offset: Offset(-1, -1),
                            ),
                          ],
                        ),
                        color: KidsColors.lilac,
                        onTap: () => _push(const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _toastEmpty(LengthMode mode, String? category) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'No ${mode.length}-letter ${category ?? ''} words yet. '
            'Try another topic!',
          ),
        ),
      );
  }
}

const _helpBlue = Color(0xFF1E4FA3);
const _settingsInk = Color(0xFF3A2E73);
const _checkBlue = Color(0xFF2F86EB);

Color _darken(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Soft white clouds up top and pastel bushes along the bottom edge.
class _CloudsPainter extends CustomPainter {
  const _CloudsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void cloud(Offset c, double r, Color color, {double blur = 8}) {
      final p = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      for (final (dx, dy, k) in const [
        (-1.1, 0.25, 0.7),
        (-0.4, -0.15, 0.95),
        (0.45, -0.05, 0.85),
        (1.15, 0.3, 0.65),
        (0.0, 0.35, 0.9),
      ]) {
        canvas.drawCircle(c + Offset(dx * r, dy * r), r * k, p);
      }
    }

    final w = size.width;
    final h = size.height;
    final white = Colors.white.withValues(alpha: 0.7);
    cloud(Offset(w * 0.15, h * 0.05), 36.8, white);
    cloud(Offset(w * 0.85, h * 0.08), 41.6, white);
    cloud(Offset(w * 0.95, h * 0.42), 40, white);
    cloud(Offset(w * 0.05, h * 0.6), 35.2, white);
    cloud(Offset(w * 0.9, h * 0.64), 32, white);
    // Bottom bushes peeking up behind the action buttons.
    cloud(
      Offset(w * 0.05, h * 0.99),
      46.4,
      KidsColors.mint.withValues(alpha: 0.45),
      blur: 6,
    );
    cloud(
      Offset(w * 0.5, h * 1.02),
      48,
      KidsColors.lilac.withValues(alpha: 0.35),
      blur: 6,
    );
    cloud(
      Offset(w * 0.95, h * 0.99),
      46.4,
      const Color(0xFFBEEC96).withValues(alpha: 0.5),
      blur: 6,
    );
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => false;
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    const word = 'UNSCRAMBLE';
    return Semantics(
      header: true,
      label: 'Unscramble for Kids',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              const SizedBox(height: 14.4),
              LayoutBuilder(
                builder: (context, c) {
                  // Each tile carries 4px of horizontal padding.
                  final size = ((c.maxWidth - word.length * 4) / word.length)
                      .clamp(20.0, 42.0);
                  final lift = size * 0.42;
                  final last = word.length - 1;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.only(top: lift),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final (i, l) in word.split('').indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              // Tiles ride a gentle arch, tilting with it.
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  -lift * math.sin(math.pi * i / last),
                                ),
                                child: Transform.rotate(
                                  angle:
                                      (i / last - 0.5) * 0.45 +
                                      (i.isEven ? -0.04 : 0.04),
                                  child: ClayLetterTile(
                                    letter: l,
                                    size: size,
                                    color:
                                        KidsColors.tileFills[i %
                                            KidsColors.tileFills.length],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 11.2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17.6,
                  vertical: 8,
                ),
                decoration: clayDecoration(
                  KidsColors.cream,
                  radius: 999,
                  depth: 0.6,
                ),
                child: const Text(
                  'Look at the picture. Spell the word!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w600,
                    color: KidsColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 3.2,
            top: -3.2,
            child: SparkleBurst(angle: -2.2),
          ),
          const Positioned(
            left: 51.2,
            top: -4.8,
            child: ClayStar(size: 24, angle: 0.2),
          ),
          const Positioned(
            right: 57.6,
            top: -8,
            child: ClayStar(size: 19.2, angle: -0.2),
          ),
          const Positioned(right: 24, top: -2, child: ClayStar(size: 17.6)),
          const Positioned(
            right: 0,
            top: -4.8,
            child: SparkleBurst(angle: -0.9),
          ),
          const Positioned(
            left: 0,
            bottom: -4.8,
            child: ClayStar(size: 22.4, angle: -0.25),
          ),
          const Positioned(
            right: 0,
            bottom: -4.8,
            child: ClayStar(size: 22.4, angle: 0.25),
          ),
        ],
      ),
    );
  }
}

class _HelpBadge extends StatelessWidget {
  const _HelpBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 35.2,
    height: 35.2,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3C74D0), _helpBlue],
      ),
      boxShadow: [
        BoxShadow(
          color: _helpBlue.withValues(alpha: 0.35),
          offset: const Offset(0, 3),
          blurRadius: 6,
        ),
      ],
    ),
    child: const Text(
      '?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
      ),
    ),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayButton(
      onPressed: onTap,
      color: color,
      radius: 24,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(vertical: 12.8, horizontal: 4.8),
      child: Column(
        children: [
          SizedBox(height: 38.4, child: Center(child: icon)),
          const SizedBox(height: 4.8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15.2,
                fontWeight: FontWeight.w700,
                color: KidsColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3.2, bottom: 9.6),
    child: Row(
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20.8,
              fontWeight: FontWeight.w700,
              color: KidsColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 4.8),
        const SparkleBurst(angle: -0.6, size: 19.2, count: 2),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rays = _darken(color, 0.12);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: ClayCard(
        color: color,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(5, 13, 5, 11),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SparkleBurst(angle: math.pi, color: rays, size: 14.4),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 33.6, height: 1.15),
                ),
                SparkleBurst(angle: 0, color: rays, size: 14.4),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 30.4,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.ink,
                  height: 1.15,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.6,
                fontWeight: FontWeight.w500,
                color: KidsColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LengthCard extends StatelessWidget {
  const _LengthCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final LengthMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClayButton(
            key: Key('length-${mode.length}'),
            onPressed: onTap,
            color: selected ? KidsColors.sky : KidsColors.cream,
            radius: 22.4,
            expand: true,
            semanticLabel: '${mode.shortLabel}, ${mode.label}',
            padding: const EdgeInsets.symmetric(
              vertical: 12.8,
              horizontal: 4.8,
            ),
            child: Column(
              children: [
                Text(
                  '${mode.length}',
                  style: const TextStyle(
                    fontSize: 38.4,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.ink,
                    height: 1.05,
                  ),
                ),
                const Text(
                  'letters',
                  style: TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.ink,
                  ),
                ),
                Text(
                  mode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: KidsColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          // Check badge so the choice is never shown by color alone.
          if (selected)
            Positioned(
              top: 6.4,
              right: 6.4,
              child: IgnorePointer(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _checkBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _checkBlue.withValues(alpha: 0.35),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.color = KidsColors.yellow,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 9.6, bottom: 9.6),
      child: Semantics(
        selected: selected,
        child: ClayButton(
          onPressed: onTap,
          color: selected ? color : KidsColors.cream,
          radius: 999,
          semanticLabel: label == 'All' ? 'All categories' : label,
          padding: const EdgeInsets.symmetric(horizontal: 17.6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20.8)),
              const SizedBox(width: 6.4),
              Text(
                label,
                style: TextStyle(
                  fontSize: selected ? 17.6 : 15.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: KidsColors.ink,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4.8),
                const Icon(
                  Icons.check_rounded,
                  size: 19.2,
                  color: KidsColors.ink,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Big glossy Play pill with sparkle fans on either side.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shade = _darken(color, 0.2);
    final glyphShadow = [
      Shadow(color: shade, offset: const Offset(0, 3)),
      Shadow(color: shade.withValues(alpha: 0.4), blurRadius: 6),
    ];
    return Row(
      children: [
        const SparkleBurst(angle: math.pi, size: 24),
        const SizedBox(width: 3.2),
        Expanded(
          child: ClayButton(
            key: const Key('play-button'),
            onPressed: onPressed,
            color: color,
            radius: 999,
            expand: true,
            semanticLabel: 'Play',
            padding: const EdgeInsets.symmetric(vertical: 17.6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 51.2,
                  color: Colors.white,
                  shadows: glyphShadow,
                ),
                const SizedBox(width: 4.8),
                Text(
                  'Play!',
                  style: TextStyle(
                    fontSize: 38.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    shadows: glyphShadow,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 3.2),
        const SparkleBurst(angle: 0, size: 24),
      ],
    );
  }
}
