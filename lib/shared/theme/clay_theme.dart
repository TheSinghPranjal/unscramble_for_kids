import 'package:flutter/material.dart';

import 'kids_palette.dart';

abstract final class ClayTheme {
  static const fontFamily = 'Fredoka';

  static ThemeData build(ClayPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.primary,
      secondary: palette.secondary,
      surface: KidsColors.cream,
      onSurface: KidsColors.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: palette.bgTop,
    );
    final text = base.textTheme.apply(
      bodyColor: KidsColors.ink,
      displayColor: KidsColors.ink,
      fontFamily: fontFamily,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: KidsColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: KidsColors.ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KidsColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KidsColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidsColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? KidsColors.success
              : KidsColors.locked,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
