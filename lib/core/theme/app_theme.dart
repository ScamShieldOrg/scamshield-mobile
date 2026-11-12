import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF0B132B);
  static const ink = Color(0xFF131B2E);
  static const blue = Color(0xFF008CC7);
  static const shieldBlue = Color(0xFF89CEFF);
  static const page = Color(0xFFFAF8FF);
  static const muted = Color(0xFFEEF1F6);
  static const mutedInk = Color(0xFF565E6B);
  static const border = Color(0xFFE2E8F0);

  static final ThemeData light = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: navy,
      secondary: blue,
      secondaryContainer: muted,
      onSecondaryContainer: ink,
      surface: Colors.white,
      surfaceTint: Colors.transparent,
      onSurface: ink,
      onSurfaceVariant: mutedInk,
      outline: border,
      outlineVariant: border,
      error: Color(0xFFDC2626),
    ),
    fontFamily: 'serif',
    scaffoldBackgroundColor: page,
    dividerColor: border,
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: border)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
  );
}
