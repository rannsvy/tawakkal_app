import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/colors.dart';

/// The hero section of the auth gate page, containing:
/// - Animated logo with glow effect
/// - Welcome text (English + Arabic)
/// - Tagline text (English + Arabic)
class AuthHeroSection extends StatefulWidget {
  const AuthHeroSection({super.key});

  @override
  State<AuthHeroSection> createState() => _AuthHeroSectionState();
}

class _AuthHeroSectionState extends State<AuthHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _welcomeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Logo: 0-600ms with easeOutBack
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.67, curve: Curves.easeOutBack),
      ),
    );

    // Welcome text: 150-650ms
    _welcomeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
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
          children: [
            // Animated logo container
            _AnimatedLogoContainer(progress: _logoAnimation.value),
            const SizedBox(height: 32),
            // Welcome text
            Opacity(
              opacity: _welcomeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _welcomeAnimation.value)),
                child: const _WelcomeTitle(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedLogoContainer extends StatelessWidget {
  const _AnimatedLogoContainer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.isFinite
        ? progress.clamp(0.0, 1.0).toDouble()
        : 0.0;
    final scale = _logoScaleCurve(
      normalizedProgress,
    ).clamp(0.0, 1.08).toDouble();
    final opacity = normalizedProgress;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
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
        ),
      ),
    );
  }

  double _logoScaleCurve(double t) {
    // Ease-out-back style curve with a small overshoot near completion.
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final x = t - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Welcome to Tawakkal',
      style: GoogleFonts.newsCycle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF7D98A),
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }
}
