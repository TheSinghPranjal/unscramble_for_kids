import 'package:flutter/material.dart';

/// Design tokens for the kids claymorphism look.
abstract final class KidsColors {
  static const bgTop = Color(0xFFFFF6E8);
  static const bgBottom = Color(0xFFE8F9F5);
  static const coral = Color(0xFFFF8A7A);
  static const yellow = Color(0xFFFFD66B);
  static const mint = Color(0xFF7DE2C5);
  static const sky = Color(0xFF7EC8FF);
  static const peach = Color(0xFFFFC4A3);
  static const lilac = Color(0xFFC9B6FF);
  static const ink = Color(0xFF2D2A32);
  static const inkSoft = Color(0xFF5C5666);
  static const success = Color(0xFF3DCF8E);
  static const wrong = Color(0xFFFF6B6B);
  static const star = Color(0xFFFFC93C);
  static const cream = Color(0xFFFFFBF4);
  static const slot = Color(0xFFF3EDE4);
  static const locked = Color(0xFFD9D4DE);

  /// Rotating fills for letter tiles so the tray feels playful.
  static const tileFills = [yellow, sky, peach, mint, lilac, coral];

  static const categoryColors = <String, Color>{
    'Animals': peach,
    'Food': yellow,
    'Nature': mint,
    'Home': coral,
    'Colors': lilac,
    'Body': Color(0xFFFFB0BE),
    'Toys': sky,
    'Transport': Color(0xFF96D6F0),
    'Weather': Color(0xFFB4DEFF),
    'School': Color(0xFFBEEC96),
  };

  static const categoryEmoji = <String, String>{
    'Animals': '🐾',
    'Food': '🍎',
    'Nature': '🌳',
    'Home': '🏠',
    'Colors': '🎨',
    'Body': '🖐️',
    'Toys': '🧸',
    'Transport': '🚗',
    'Weather': '🌦️',
    'School': '🎒',
  };

  static Color forCategory(String category) => categoryColors[category] ?? sky;
}

/// A swappable clay color pack. Extra packs are unlocked as rewards.
@immutable
class ClayPalette {
  const ClayPalette({
    required this.id,
    required this.name,
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final String id;
  final String name;
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;

  /// Main call-to-action fill (Play, Next Word).
  final Color primary;
  final Color secondary;
  final Color accent;

  static const classic = ClayPalette(
    id: 'classic',
    name: 'Classic Clay',
    bgTop: KidsColors.bgTop,
    bgMid: Color(0xFFEAF5FF),
    bgBottom: KidsColors.bgBottom,
    primary: KidsColors.coral,
    secondary: KidsColors.sky,
    accent: KidsColors.yellow,
  );

  static const sunshine = ClayPalette(
    id: 'sunshine',
    name: 'Sunshine Clay',
    bgTop: Color(0xFFFFF4C9),
    bgMid: Color(0xFFFFE9D6),
    bgBottom: Color(0xFFFFF0E0),
    primary: Color(0xFFFFA94D),
    secondary: KidsColors.yellow,
    accent: KidsColors.coral,
  );

  static const ocean = ClayPalette(
    id: 'ocean',
    name: 'Ocean Clay',
    bgTop: Color(0xFFE3F4FF),
    bgMid: Color(0xFFDDF7FF),
    bgBottom: Color(0xFFD8FFF4),
    primary: Color(0xFF4FB3F6),
    secondary: KidsColors.mint,
    accent: KidsColors.lilac,
  );

  static const all = [classic, sunshine, ocean];

  static ClayPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classic);
}
