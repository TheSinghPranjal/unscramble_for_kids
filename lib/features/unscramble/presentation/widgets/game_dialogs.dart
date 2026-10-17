import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../shared/theme/kids_palette.dart';
import '../../../../shared/widgets/clay.dart';
import '../../../../shared/widgets/confetti.dart';
import '../../domain/game_state.dart';
import '../../domain/rewards.dart';
import '../../domain/word_entry.dart';
import 'word_picture.dart';

enum WinAction { next, rewards, home }

enum LoseAction { retry, newWord, home }

Future<T?> _showClayDialog<T>(
  BuildContext context, {
  required Widget child,
  bool confetti = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: KidsColors.ink.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (context, _, _) => Stack(
      children: [
        // Soft frosted blur over the game board behind the card.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ),
          ),
        ),
        if (confetti) const Positioned.fill(child: ConfettiBurst()),
      ],
    ),
  );
}

Widget _wordTiles(String word, {double size = 44}) => Wrap(
  alignment: WrapAlignment.center,
  spacing: 6,
  children: [
    for (final l in word.split(''))
      ClayLetterTile(letter: l, size: size, color: KidsColors.mint),
  ],
);

Future<WinAction?> showWinDialog(
  BuildContext context, {
  required WordEntry entry,
  required WinReward reward,
}) {
  final s = reward.stars;
  return _showClayDialog<WinAction>(
    context,
    confetti: true,
    child: ClayCard(
      key: const Key('win-dialog'),
      padding: const EdgeInsets.all(20),
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You did it! 🎉',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          WordPicture(entry: entry, size: 120),
          const SizedBox(height: 12),
          _wordTiles(entry.word),
          const SizedBox(height: 14),
          Bounce(
            trigger: 1,
            playOnMount: true,
            from: 0.5,
            child: StarRow(filled: s.base, total: s.baseMax, size: 44),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (s.firstClear > 0)
                ClayChip(label: '+${s.firstClear} new word', fontSize: 14),
              if (s.daily > 0)
                ClayChip(label: '+${s.daily} daily bonus', fontSize: 14),
              if (s.streak > 0)
                ClayChip(
                  label: '+${s.streak} streak',
                  leading: const Text('🔥'),
                  fontSize: 14,
                ),
              ClayChip(
                label: '+${s.total} stars',
                color: KidsColors.yellow,
                leading: const Icon(Icons.star_rounded, size: 18),
                fontSize: 14,
              ),
              ClayChip(label: '+${reward.points} points', fontSize: 14),
              if (reward.isNewHighScore)
                const ClayChip(
                  label: 'New high score!',
                  leading: Text('🏆'),
                  color: KidsColors.peach,
                  fontSize: 14,
                ),
            ],
          ),
          if (reward.newUnlocks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              '✨ New rewards!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final item in reward.newUnlocks) _UnlockPop(item: item),
              ],
            ),
          ],
          if (reward.nextReward case final next?) ...[
            const SizedBox(height: 14),
            Text(
              '${reward.starsToNext} more ⭐ for ${next.emoji} ${next.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: KidsColors.inkSoft),
            ),
            const SizedBox(height: 6),
            ClayProgressBar(
              value: reward.progressToNext,
              color: KidsColors.star,
            ),
          ],
          const SizedBox(height: 18),
          ClayButton.label(
            key: const Key('next-word'),
            onPressed: () => Navigator.of(context).pop(WinAction.next),
            label: 'Next Word',
            icon: Icons.arrow_forward_rounded,
            color: KidsColors.mint,
            expand: true,
            fontSize: 24,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClayButton.label(
                  onPressed: () => Navigator.of(context).pop(WinAction.rewards),
                  label: 'Rewards',
                  icon: Icons.emoji_events_rounded,
                  color: KidsColors.yellow,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClayButton.label(
                  onPressed: () => Navigator.of(context).pop(WinAction.home),
                  label: 'Home',
                  icon: Icons.home_rounded,
                  color: KidsColors.cream,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _UnlockPop extends StatelessWidget {
  const _UnlockPop({required this.item});

  final RewardItem item;

  @override
  Widget build(BuildContext context) {
    final kind = switch (item.kind) {
      RewardKind.sticker => 'sticker',
      RewardKind.badge => 'badge',
      RewardKind.theme => 'theme',
    };
    return Semantics(
      label: 'New $kind: ${item.name}',
      excludeSemantics: true,
      child: Bounce(
        trigger: 1,
        playOnMount: true,
        from: 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: clayDecoration(KidsColors.lilac, radius: 999, depth: 0.6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 6),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _tryGreen = Color(0xFF34C77B);
const _revealGreen = Color(0xFF7BE3A6);

Future<LoseAction?> showLoseDialog(
  BuildContext context, {
  required WordEntry entry,
  required LoseReason reason,
}) {
  const heroSize = 96.0;
  final timeUp = reason == LoseReason.timeUp;
  return _showClayDialog<LoseAction>(
    context,
    child: Stack(
      key: const Key('lose-dialog'),
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: heroSize * 0.62),
          child: Container(
            // Glassy white rim around the clay card.
            decoration: clayDecoration(KidsColors.cream, radius: 34).copyWith(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: CustomPaint(
                painter: const _DreamyCardPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    heroSize * 0.48,
                    20,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeUp ? 'Time’s up!' : 'Almost!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: KidsColors.ink,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Want to try again?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: KidsColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: clayDecoration(
                          KidsColors.forCategory(entry.category),
                          radius: 30,
                          depth: 0.8,
                        ),
                        child: WordPicture(entry: entry, size: 128, radius: 24),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SparkleBurst(angle: math.pi * 1.15, size: 26),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final l in entry.word.split(''))
                                  ClayLetterTile(
                                    letter: l,
                                    size: 46,
                                    color: _revealGreen,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const SparkleBurst(angle: -0.15 * math.pi, size: 26),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClayButton(
                        key: const Key('try-again'),
                        onPressed: () =>
                            Navigator.of(context).pop(LoseAction.retry),
                        color: _tryGreen,
                        radius: 999,
                        expand: true,
                        semanticLabel: 'Try Again',
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              size: 32,
                              color: Colors.white,
                              shadows: _whiteGlyphShadow,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: _whiteGlyphShadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClayButton.label(
                              onPressed: () =>
                                  Navigator.of(context).pop(LoseAction.newWord),
                              label: 'New Word',
                              icon: Icons.shuffle_rounded,
                              color: KidsColors.sky,
                              radius: 999,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClayButton.label(
                              onPressed: () =>
                                  Navigator.of(context).pop(LoseAction.home),
                              label: 'Home',
                              icon: Icons.home_rounded,
                              color: Colors.white,
                              radius: 999,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Hero emoji bursting out of the top of the card.
        SizedBox(
          width: heroSize * 2,
          height: heroSize * 1.25,
          child: CustomPaint(
            painter: const _HeroRaysPainter(),
            child: Center(
              child: Text(
                timeUp ? '⏰' : '💪',
                style: const TextStyle(fontSize: heroSize * 0.8, height: 1),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 22,
          top: heroSize * 0.95,
          child: ClayStar(size: 28, angle: -0.2),
        ),
        const Positioned(
          right: 22,
          top: heroSize * 0.85,
          child: ClayStar(size: 30, angle: 0.2),
        ),
        const Positioned(
          left: 6,
          top: heroSize * 1.6,
          child: ClayStar(size: 22, angle: 0.15),
        ),
        const Positioned(
          right: 8,
          top: heroSize * 3.3,
          child: ClayStar(size: 26, angle: -0.15),
        ),
      ],
    ),
  );
}

const _whiteGlyphShadow = [
  Shadow(color: Color(0x5520804F), offset: Offset(0, 2), blurRadius: 3),
];

/// Yellow sunburst dashes fanning out above the hero emoji.
class _HeroRaysPainter extends CustomPainter {
  const _HeroRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.height * 0.48;
    final paint = Paint()
      ..color = KidsColors.star
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // Upper half only, from left to right; skip straight up.
    for (final deg in const [-175, -145, -115, -65, -35, -5]) {
      final a = deg * math.pi / 180;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * r, c + d * (r + 22), paint);
    }
  }

  @override
  bool shouldRepaint(_HeroRaysPainter old) => false;
}

/// Pastel sky wash with soft candy clouds drifting along the sides.
class _DreamyCardPainter extends CustomPainter {
  const _DreamyCardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDEBFF), Color(0xFFFFF8F1), Color(0xFFFFF1E6)],
          stops: [0, 0.4, 1],
        ).createShader(Offset.zero & size),
    );
    void puff(Offset c, double r, Color color) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    const pink = Color(0x66FFC2DD);
    const peach = Color(0x66FFD9B0);
    const blue = Color(0x66B9DDFF);
    const lilac = Color(0x66D9C8FF);
    final white = Colors.white.withValues(alpha: 0.85);
    puff(Offset(w * 0.9, h * 0.04), 58, lilac);
    puff(Offset(w * 0.08, h * 0.06), 48, blue);
    puff(Offset(0, h * 0.28), 54, pink);
    puff(Offset(w, h * 0.3), 50, blue);
    puff(Offset(-10, h * 0.5), 60, peach);
    puff(Offset(w + 6, h * 0.48), 62, peach);
    puff(Offset(10, h * 0.62), 50, pink);
    puff(Offset(w - 6, h * 0.6), 46, blue);
    puff(Offset(w + 4, h * 0.4), 52, lilac);
    puff(Offset(-6, h * 0.42), 44, lilac);
    puff(Offset(w * 0.15, h * 0.68), 56, white);
    puff(Offset(w * 0.85, h * 0.66), 56, white);
    // Central cream panel so text stays crisp over the clouds.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.06, w * 0.76, h * 0.42),
        const Radius.circular(34),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_DreamyCardPainter old) => false;
}

Future<bool> confirmQuit(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this puzzle?'),
      content: const Text(
        'You can start a new word any time.',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep playing', style: TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Go home', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
