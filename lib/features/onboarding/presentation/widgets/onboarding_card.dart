import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/colors.dart';
import '../../data/onboarding_content.dart';
import 'islamic_pattern_painter.dart';

/// An enhanced onboarding card with glassmorphism, Islamic pattern corners,
/// and improved visual hierarchy.
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
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TawakkalColors.surfaceDark.withValues(alpha: 0.95),
                TawakkalColors.surfaceDarkAlt.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: TawakkalColors.accentGold.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TawakkalColors.primary.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Islamic pattern corner accents
                Positioned(
                  top: 0,
                  left: 0,
                  child: _PatternCorner(
                    position: CornerPosition.topLeft,
                    size: 100,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _PatternCorner(
                    position: CornerPosition.bottomRight,
                    size: 100,
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconContainer(icon: slide.icon),
                      const SizedBox(height: 24),
                      _Title(text: slide.title),
                      const SizedBox(height: 12),
                      _Description(text: slide.description),
                      const SizedBox(height: 24),
                      _HighlightCard(text: slide.highlight),
                      const SizedBox(height: 20),
                      _VerseCard(
                        verse: slide.verse,
                        translation: slide.verseTranslation,
                      ),
                    ],
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

class _IconContainer extends StatelessWidget {
  const _IconContainer({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TawakkalColors.accentGold.withValues(alpha: 0.20),
            TawakkalColors.accentGold.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: TawakkalColors.accentGold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: TawakkalColors.accentGold.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: TawakkalColors.accentGold,
        size: 32,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: TawakkalColors.textPrimaryDark,
        height: 1.2,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: TawakkalColors.textSecondary,
        height: 1.5,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TawakkalColors.primary.withValues(alpha: 0.12),
            TawakkalColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TawakkalColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: TawakkalColors.textPrimaryDark,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.translation,
  });

  final String verse;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TawakkalColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse,
            style: GoogleFonts.notoNaskhArabic(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: TawakkalColors.textAccentGold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translation,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TawakkalColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCorner extends StatelessWidget {
  const _PatternCorner({
    required this.position,
    this.size = 80,
  });

  final CornerPosition position;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: IslamicPatternCornerPainter(
          position: position,
          opacity: 0.12,
        ),
      ),
    );
  }
}
