import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/colors.dart';
import '../../data/onboarding_content.dart';

/// A clean onboarding card that follows the new reference layout.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    required this.slide,
    required this.isVisible,
    super.key,
  });

  final OnboardingSlide slide;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? TawakkalColors.surfaceDark.withValues(alpha: 0.92)
        : TawakkalColors.surfaceLight;
    final borderColor = isDark
        ? TawakkalColors.surfaceDarkAlt
        : const Color(0xFFE6EBE8);
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : const Color(0xFF212A28);
    final descriptionColor = isDark
        ? TawakkalColors.textSecondary.withValues(alpha: 0.95)
        : const Color(0xFF6D7774);
    final accentColor = isDark
        ? TawakkalColors.primary
        : const Color(0xFF2F7F55);

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0.08, 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0x1A4C635A),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SvgPicture.asset(
                      slide.illustrationAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: descriptionColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
