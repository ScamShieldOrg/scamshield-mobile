import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData dark = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9ACCFF),
      onPrimary: Color(0xFF0B2545),
      secondary: Color(0xFF89CEFF),
      secondaryContainer: Color(0xFF253B58),
      onSecondaryContainer: Color(0xFFE2EEFF),
      surface: Color(0xFF171F30),
      onSurface: Color(0xFFEAF1FF),
      onSurfaceVariant: Color(0xFFAFBDD3),
      outline: Color(0xFF465671),
      outlineVariant: Color(0xFF35435A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1523),
  );

  static const navy = Color(0xFF0B132B);
  static const navyMid = Color(0xFF111C3D);
  static const navyLight = Color(0xFF1C2A4A);
  static const ink = Color(0xFF131B2E);
  static const blue = Color(0xFF008CC7);
  static const shieldBlue = Color(0xFF89CEFF);
  static const page = Color(0xFFFAF8FF);
  static const muted = Color(0xFFEEF1F6);
  static const mutedInk = Color(0xFF565E6B);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFBA1A1A);
  static const errorSurface = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);
  static const accentAmber = Color(0xFFF59E0B);

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
      error: error,
    ),
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
