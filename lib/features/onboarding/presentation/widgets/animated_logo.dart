import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/colors.dart';

/// An animated logo widget with multi-stage animation:
/// Stage 1: Star pattern draws from center
/// Stage 2: Mosque icon fades in with scale
/// Stage 3: Text reveals letter-by-letter
/// Stage 4: Arabic subtitle fades in
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key, this.onAnimationComplete});

  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _mosqueScaleAnimation;
  late Animation<double> _mosqueOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _quoteOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );

    // Mosque fades in: 500-1000ms
    _mosqueScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.43, curve: Curves.easeOutBack),
      ),
    );
    _mosqueOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.43, curve: Curves.easeOut),
      ),
    );

    // Text reveals: 900-1400ms
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.39, 0.61, curve: Curves.easeOut),
      ),
    );

    // Quote fades in: 1600-2000ms
    _quoteOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.87, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Notify parent when animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // Mosque icon with glow
            Transform.scale(
              scale: _mosqueScaleAnimation.value,
              child: Opacity(
                opacity: _mosqueOpacityAnimation.value,
                child: const _MosqueIcon(),
              ),
            ),
            const SizedBox(height: 28),
            // English brand name
            Opacity(
              opacity: _textOpacityAnimation.value,
              child: const _BrandName(),
            ),

            const SizedBox(height: 32),
            // Inspirational quote
            Opacity(
              opacity: _quoteOpacityAnimation.value,
              child: const _InspirationalQuote(),
            ),
          ],
        );
      },
    );
  }
}

class _MosqueIcon extends StatelessWidget {
  const _MosqueIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            TawakkalColors.primary.withValues(alpha: 0.25),
            TawakkalColors.accentGold.withValues(alpha: 0.18),
            TawakkalColors.primary.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: TawakkalColors.accentGold.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Image.asset(
          'assets/images/tawakkal_transparent.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tawakkal',
      style: GoogleFonts.newsreader(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF7D98A),
        letterSpacing: -0.8,
        height: 1.1,
      ),
    );
  }
}

class _InspirationalQuote extends StatelessWidget {
  const _InspirationalQuote();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'رَبِّ زِدْنِي عِلْمًا',
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: TawakkalColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'My Lord, increase me in knowledge',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: TawakkalColors.textSecondary.withValues(alpha: 0.7),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
