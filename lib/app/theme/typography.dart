import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TawakkalTypography {
  static const String quranAssetFontFamily = 'HafsQuran';

  static TextTheme textTheme(Color color) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: color,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: color,
        fontSize: 15,
        height: 1.35,
      ),
      bodySmall: base.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
    );
  }

  static TextStyle arabicStyle({required Color color, double size = 30}) {
    return _quranArabicStyle(
      color: color,
      size: size,
      height: 1.9,
      weight: FontWeight.w400,
    );
  }

  static TextStyle arabicLabelStyle({
    required Color color,
    double size = 22,
    FontWeight weight = FontWeight.w500,
  }) {
    return _quranArabicStyle(
      color: color,
      size: size,
      height: 1.35,
      weight: weight,
      letterSpacing: 0.05,
    );
  }

  static TextStyle _quranArabicStyle({
    required Color color,
    required double size,
    required double height,
    required FontWeight weight,
    double letterSpacing = 0,
  }) {
    final naskhStyle = GoogleFonts.notoNaskhArabic(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
    final fallbackFamilies = <String>[
      if (naskhStyle.fontFamily case final String family) family,
      'Noto Sans Arabic',
    ];

    return naskhStyle.copyWith(
      // Prefer local Hafs/Uthmani family if added in pubspec.
      // Fallback keeps diacritics monochrome and theme-consistent.
      fontFamily: quranAssetFontFamily,
      fontFamilyFallback: fallbackFamilies,
    );
  }
}
