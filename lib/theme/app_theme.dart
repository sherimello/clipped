import 'package:flutter/material.dart';

class AppTheme {
  // Core palette
  static const Color accent = Color(0xFF6366F1);       // indigo
  static const Color accentLight = Color(0xFF818CF8);
  static const Color accentBlue = Color(0xFF2997FF);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentOrange = Color(0xFFFB923C);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFFA78BFA);

  static const Color surface = Color(0x0DFFFFFF);       // 5% white
  static const Color surfaceMed = Color(0x1AFFFFFF);    // 10% white
  static const Color surfaceHigh = Color(0x26FFFFFF);   // 15% white
  static const Color border = Color(0x1AFFFFFF);        // 10% white border
  static const Color borderBright = Color(0x33FFFFFF);  // 20% white border

  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0x80FFFFFF);
  static const Color textTertiary = Color(0x4DFFFFFF);

  static const Color windowBg = Color(0xCC0A0A14);

  // Solid dark root background per theme [bgColor, previewDotColor].
  // Semi-transparent surfaces (sidebar 20% black, cards 5% white) are painted
  // on top, so they naturally inherit the bg hue — no extra per-widget wiring.
  static const List<List<Color>> tintThemes = [
    [Color(0xFF0C0C0C), Color(0xFF252525)],   // Void: pure dark
    [Color(0xFF080814), Color(0xFF13133A)],   // Midnight: dark indigo
    [Color(0xFF08140A), Color(0xFF0E2810)],   // Forest: dark green
    [Color(0xFF140810), Color(0xFF2E0F28)],   // Grape: dark purple
  ];
  static const List<String> tintThemeNames = ['Void', 'Midnight', 'Forest', 'Grape'];

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Segoe UI',
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentBlue,
          surface: Color(0xFF0A0A14),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          bodySmall: TextStyle(color: textTertiary, fontSize: 11),
          labelLarge: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        iconTheme: const IconThemeData(color: textSecondary, size: 18),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0x33FFFFFF)),
          radius: const Radius.circular(8),
          thickness: WidgetStateProperty.all(4),
        ),
      );
}
