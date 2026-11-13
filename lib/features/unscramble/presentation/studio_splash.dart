import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../application/rewards_controller.dart';
import 'boot_screen.dart';

/// Opening splash: the app name, then "by" / "The Lazy Bear Club".
///
/// Held for [hold] and faded for [fade] — about two seconds — then the
/// existing boot screen (the app's first screen) is revealed. Word loading
/// runs underneath, so a fast boot does not add a second wait.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key});

  static const hold = Duration(milliseconds: 1700);
  static const fade = Duration(milliseconds: 300);

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

enum _Phase { show, fading, gone }

class _SplashGateState extends ConsumerState<SplashGate> {
  var _phase = _Phase.show;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    await Future<void>.delayed(SplashGate.hold);
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _phase = _Phase.gone);
      return;
    }
    setState(() => _phase = _Phase.fading);
    await Future<void>.delayed(SplashGate.fade);
    if (!mounted) return;
    setState(() => _phase = _Phase.gone);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activePaletteProvider);
    final cover = _phase != _Phase.gone;
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: cover,
          child: IgnorePointer(ignoring: cover, child: const BootScreen()),
        ),
        if (cover)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _phase != _Phase.show,
              child: AnimatedOpacity(
                opacity: _phase == _Phase.show ? 1 : 0,
                duration: SplashGate.fade,
                curve: Curves.easeOut,
                child: StudioSplash(palette: palette),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kid-friendly splash painted with the clay palette and Fredoka.
class StudioSplash extends StatefulWidget {
  const StudioSplash({super.key, this.palette = ClayPalette.classic});

  final ClayPalette palette;

  @override
  State<StudioSplash> createState() => _StudioSplashState();
}

class _StudioSplashState extends State<StudioSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      if (_intro.status != AnimationStatus.completed) _intro.value = 1;
      return;
    }
    if (_intro.status == AnimationStatus.dismissed) _intro.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      key: const Key('studio-splash'),
      color: dark ? _darkStops(widget.palette).last : widget.palette.bgTop,
      child: _SplashFill(
        dark: dark,
        palette: widget.palette,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: _SplashLayout(palette: widget.palette),
          ),
        ),
      ),
    );
  }
}

class _SplashFill extends StatelessWidget {
  const _SplashFill({
    required this.dark,
    required this.palette,
    required this.child,
  });

  final bool dark;
  final ClayPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!dark) {
      return KidsBackground(palette: palette, child: child);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _darkStops(palette),
        ),
      ),
      child: child,
    );
  }
}

/// Darkened clay washes so the byline stays light-on-dark and readable.
List<Color> _darkStops(ClayPalette palette) {
  const night = Color(0xFF1A1522);
  const deep = Color(0xFF121816);
  return [
    Color.lerp(night, palette.bgTop, 0.20)!,
    Color.lerp(night, palette.bgMid, 0.14)!,
    Color.lerp(deep, palette.bgBottom, 0.18)!,
  ];
}

class _SplashLayout extends StatelessWidget {
  const _SplashLayout({required this.palette});

  final ClayPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final shortest = math.min(w, h);
        final short = h < 520;
        final iconSize = short
            ? (shortest < 340 ? 48.0 : 56.0)
            : (shortest >= 700 ? 88.0 : 72.0);
        final lockupWidth = math.min(w, shortest >= 700 ? 460.0 : 400.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(20, short ? 8 : 16, 20, short ? 10 : 18),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: math.max(220, lockupWidth),
                      child: _NameLockup(palette: palette),
                    ),
                  ),
                ),
              ),
              _StudioByline(
                iconSize: iconSize,
                colors: _BylineColors.of(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NameLockup extends StatelessWidget {
  const _NameLockup({required this.palette});

  final ClayPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Unscramble for Kids',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClayCard(
              color: KidsColors.cream,
              radius: 32,
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Unscramble',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: KidsColors.ink,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: clayDecoration(
                        palette.accent,
                        radius: 999,
                        depth: 0.65,
                      ),
                      child: Text(
                        'for Kids',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: KidsColors.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(right: -2, top: -14, child: ClayStar(size: 32)),
            const Positioned(
              left: 6,
              top: -10,
              child: ClayStar(size: 18, angle: -0.45),
            ),
            const Positioned(
              left: -6,
              bottom: 10,
              child: ClayStar(size: 22, angle: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _BylineColors {
  const _BylineColors({required this.primary, required this.soft});

  final Color primary;
  final Color soft;

  static _BylineColors of(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const _BylineColors(
        primary: KidsColors.ink,
        soft: KidsColors.inkSoft,
      );
    }
    return const _BylineColors(
      primary: Color(0xFFFFF6E8),
      soft: Color(0xFFE4D7C4),
    );
  }
}

class _StudioByline extends StatelessWidget {
  const _StudioByline({required this.iconSize, required this.colors});

  final double iconSize;
  final _BylineColors colors;

  static const _asset = 'assets/branding/lazy_bear_club.png';

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final bySize = scaler.scale(16).clamp(14.0, 26.0);
    final nameSize = scaler.scale(20).clamp(16.0, 32.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.22),
          child: Image.asset(
            _asset,
            key: const Key('lazy-bear-club-icon'),
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
        SizedBox(height: iconSize < 60 ? 6 : 10),
        Text(
          'by',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: bySize,
            fontWeight: FontWeight.w600,
            color: colors.soft,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'The Lazy Bear Club',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: nameSize,
                fontWeight: FontWeight.w700,
                color: colors.primary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
