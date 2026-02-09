import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TawakkalTypography {
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
    return GoogleFonts.notoSansArabic(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.7,
    );
  }
}
