import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kids_palette.dart';

Color _shift(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// Outer "extruded clay" decoration: matte fill, soft drop shadow and a
/// light top-left lift shadow.
BoxDecoration clayDecoration(
  Color color, {
  double radius = 24,
  double depth = 1,
  bool pressed = false,
}) {
  final d = pressed ? depth * 0.45 : depth;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_shift(color, 0.06), color, _shift(color, -0.04)],
      stops: const [0, 0.55, 1],
    ),
    boxShadow: [
      BoxShadow(
        color: _shift(color, -0.32).withValues(alpha: 0.38),
        offset: Offset(0, 9 * d),
        blurRadius: 18 * d,
        spreadRadius: -3,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.75),
        offset: Offset(-3 * d, -3 * d),
        blurRadius: 8 * d,
      ),
    ],
  );
}

/// Foreground pass that fakes clay inner light: highlight top-left,
/// gentle inner shade bottom-right.
BoxDecoration clayInnerDecoration({double radius = 24}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.38),
      Colors.white.withValues(alpha: 0),
      Colors.black.withValues(alpha: 0),
      Colors.black.withValues(alpha: 0.07),
    ],
    stops: const [0, 0.35, 0.7, 1],
  ),
);

/// Recessed well (used for empty answer slots).
BoxDecoration clayInsetDecoration(Color color, {double radius = 20}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_shift(color, -0.07), color, _shift(color, 0.04)],
        stops: const [0, 0.4, 1],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
    );

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.color = KidsColors.cream,
    this.radius = 26,
    this.padding = const EdgeInsets.all(16),
    this.depth = 1,
    this.width,
    this.height,
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: clayDecoration(color, radius: radius, depth: depth),
      foregroundDecoration: clayInnerDecoration(radius: radius),
      padding: padding,
      child: child,
    );
  }
}

/// Big squishy clay button. Scales 1.0 → 0.96 while pressed.
class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = KidsColors.yellow,
    this.radius = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.semanticLabel,
    this.minSize = const Size(48, 48),
    this.expand = false,
  });

  /// Text + optional icon convenience constructor.
  factory ClayButton.label({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Color color = KidsColors.yellow,
    double radius = 24,
    double fontSize = 20,
    bool expand = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
  }) {
    return ClayButton(
      key: key,
      onPressed: onPressed,
      color: color,
      radius: radius,
      expand: expand,
      padding: padding,
      semanticLabel: label,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: KidsColors.ink, size: fontSize + 6),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: KidsColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Size minSize;
  final bool expand;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onPressed == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : KidsColors.locked;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.6,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: BoxConstraints(
                minWidth: widget.minSize.width,
                minHeight: widget.minSize.height,
              ),
              width: widget.expand ? double.infinity : null,
              padding: widget.padding,
              decoration: clayDecoration(
                color,
                radius: widget.radius,
                pressed: _pressed,
              ),
              foregroundDecoration: clayInnerDecoration(radius: widget.radius),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round clay icon button (pause, back, settings).
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = KidsColors.cream,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClayButton(
        onPressed: onPressed,
        color: color,
        radius: size / 2,
        padding: EdgeInsets.zero,
        semanticLabel: tooltip,
        minSize: Size(size, size),
        child: Icon(icon, color: KidsColors.ink, size: size * 0.5),
      ),
    );
  }
}

/// Chunky clay letter block.
class ClayLetterTile extends StatelessWidget {
  const ClayLetterTile({
    super.key,
    required this.letter,
    required this.size,
    this.color = KidsColors.yellow,
    this.badge,
  });

  final String letter;
  final double size;
  final Color color;

  /// Small corner icon (e.g. check mark on a locked slot) so success is
  /// never shown by color alone.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: clayDecoration(color, radius: radius, depth: 0.8),
              foregroundDecoration: clayInnerDecoration(radius: radius),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.ink,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (badge != null) Positioned(right: -4, top: -4, child: badge!),
        ],
      ),
    );
  }
}

class ClayChip extends StatelessWidget {
  const ClayChip({
    super.key,
    required this.label,
    this.leading,
    this.color = KidsColors.cream,
    this.fontSize = 16,
  });

  final String label;
  final Widget? leading;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: clayDecoration(color, radius: 999, depth: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: KidsColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clay progress bar.
class ClayProgressBar extends StatelessWidget {
  const ClayProgressBar({
    super.key,
    required this.value,
    this.color = KidsColors.mint,
    this.height = 16,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: clayInsetDecoration(KidsColors.slot, radius: height),
      child: LayoutBuilder(
        builder: (context, c) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: c.maxWidth * value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastel gradient wash with soft floating clay blobs.
class KidsBackground extends StatelessWidget {
  const KidsBackground({super.key, required this.palette, required this.child});

  final ClayPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgTop, palette.bgMid, palette.bgBottom],
        ),
      ),
      child: CustomPaint(painter: _BlobPainter(palette), child: child),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.palette);

  final ClayPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (Offset(size.width * 0.08, size.height * 0.12), 70.0, palette.accent),
      (Offset(size.width * 0.95, size.height * 0.28), 90.0, palette.secondary),
      (Offset(size.width * 0.05, size.height * 0.78), 80.0, KidsColors.mint),
      (Offset(size.width * 0.9, size.height * 0.92), 100.0, palette.primary),
    ];
    for (final (center, r, color) in blobs) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    // Tiny sprinkle dots.
    final rnd = math.Random(7);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 24; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        2 + rnd.nextDouble() * 3,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.palette != palette;
}

/// Row of stars (filled up to [filled]).
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.filled,
    required this.total,
    this.size = 36,
  });

  final int filled;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled of $total stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < filled ? KidsColors.star : KidsColors.locked,
              size: size,
            ),
        ],
      ),
    );
  }
}

/// Little fan of rounded dashes — the "sparkle" accent used around the
/// title, emojis, headings and big buttons. [angle] is the direction the
/// fan points (0 = right, pi = left).
class SparkleBurst extends StatelessWidget {
  const SparkleBurst({
    super.key,
    required this.angle,
    this.color = KidsColors.star,
    this.size = 17.6,
    this.count = 3,
  });

  final double angle;
  final Color color;
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SparkleBurstPainter(angle, color, count)),
  );
}

class _SparkleBurstPainter extends CustomPainter {
  _SparkleBurstPainter(this.angle, this.color, this.count);

  final double angle;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final origin = size.center(Offset.zero) - dir * (s * 0.5);
    final paint = Paint()
      ..color = color
      ..strokeWidth = s * 0.16
      ..strokeCap = StrokeCap.round;
    const spread = 0.7;
    for (var i = 0; i < count; i++) {
      final a = angle + spread * (i - (count - 1) / 2);
      final d = Offset(math.cos(a), math.sin(a));
      // The middle dash reaches furthest, like a little sunburst.
      final reach = i == (count - 1) / 2 ? 0.95 : 0.8;
      canvas.drawLine(origin + d * (s * 0.35), origin + d * (s * reach), paint);
    }
  }

  @override
  bool shouldRepaint(_SparkleBurstPainter old) =>
      old.angle != angle || old.color != color || old.count != count;
}

class ClayStar extends StatelessWidget {
  const ClayStar({super.key, this.size = 22.4, this.angle = 0});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Icon(
      Icons.star_rounded,
      size: size,
      color: KidsColors.star,
      shadows: [
        Shadow(
          color: const Color(0xFFE0A21A).withValues(alpha: 0.55),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
      ],
    ),
  );
}
