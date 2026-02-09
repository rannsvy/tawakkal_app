import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

class TawakkalTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: TawakkalColors.primary,
      brightness: Brightness.light,
      primary: TawakkalColors.primary,
      secondary: TawakkalColors.accentGold,
      surface: TawakkalColors.surfaceLight,
      error: TawakkalColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TawakkalColors.backgroundLight,
      textTheme: TawakkalTypography.textTheme(TawakkalColors.textPrimaryLight),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: TawakkalColors.textPrimaryLight,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: TawakkalColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x12000000)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TawakkalColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x18000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x18000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: TawakkalColors.primary,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: TawakkalColors.primary,
          foregroundColor: TawakkalColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: TawakkalColors.primary,
          foregroundColor: TawakkalColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TawakkalColors.surfaceDark,
        contentTextStyle: TawakkalTypography.textTheme(
          TawakkalColors.textPrimaryDark,
        ).bodyMedium,
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0x18000000)),
        selectedColor: TawakkalColors.primary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: TawakkalColors.primary,
      brightness: Brightness.dark,
      primary: TawakkalColors.primary,
      secondary: TawakkalColors.accentGold,
      surface: TawakkalColors.surfaceDark,
      error: TawakkalColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TawakkalColors.backgroundDark,
      textTheme: TawakkalTypography.textTheme(TawakkalColors.textPrimaryDark),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: TawakkalColors.textPrimaryDark,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: TawakkalColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x16FFFFFF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TawakkalColors.surfaceDarkAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: TawakkalColors.primary,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: TawakkalColors.primary,
          foregroundColor: TawakkalColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: TawakkalColors.primary,
          foregroundColor: TawakkalColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TawakkalColors.surfaceDarkAlt,
        contentTextStyle: TawakkalTypography.textTheme(
          TawakkalColors.textPrimaryDark,
        ).bodyMedium,
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0x22FFFFFF)),
        selectedColor: TawakkalColors.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
