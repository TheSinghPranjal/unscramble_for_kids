import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kids_palette.dart';

/// Lightweight confetti burst (no package needed). Skips itself when the
/// platform asks for reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _pieces = List.generate(widget.pieces, (_) {
      return _Piece(
        x: rnd.nextDouble(),
        vx: (rnd.nextDouble() - 0.5) * 0.5,
        vy: 0.6 + rnd.nextDouble() * 0.6,
        spin: (rnd.nextDouble() - 0.5) * 10,
        size: 6 + rnd.nextDouble() * 8,
        color: KidsColors.tileFills[rnd.nextInt(KidsColors.tileFills.length)],
        delay: rnd.nextDouble() * 0.25,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _c.value),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
    required this.delay,
  });

  final double x, vx, vy, spin, size, delay;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final dx = (p.x + p.vx * local) * size.width;
      final dy = (-0.1 + p.vy * local * 1.2) * size.height;
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - local).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Horizontal shake used for wrong-letter feedback (motion + icon, never
/// color alone). Shakes whenever [trigger] changes.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final dx = math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Soft bounce / "pop" used when a letter locks or a reward unlocks.
class Bounce extends StatefulWidget {
  const Bounce({
    super.key,
    required this.trigger,
    required this.child,
    this.from = 0.8,
    this.playOnMount = false,
  });

  final int trigger;
  final Widget child;
  final double from;
  final bool playOnMount;

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  void _play() {
    if (!mounted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(Bounce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: widget.from,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut)),
      child: widget.child,
    );
  }
}
