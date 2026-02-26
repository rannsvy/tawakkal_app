import 'dart:math' as math;
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

  late Animation<double> _starPathAnimation;
  late Animation<double> _mosqueScaleAnimation;
  late Animation<double> _mosqueOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _arabicOpacityAnimation;
  late Animation<double> _quoteOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );

    // Star path draws: 0-600ms
    _starPathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.26, curve: Curves.easeOutCubic),
      ),
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

    // Arabic subtitle: 1300-1700ms
    _arabicOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.57, 0.74, curve: Curves.easeOut),
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
            // Star pattern background
            _StarPatternAnimation(progress: _starPathAnimation.value),
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
            const SizedBox(height: 6),
            // Arabic brand name
            Opacity(
              opacity: _arabicOpacityAnimation.value,
              child: const _ArabicName(),
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

class _StarPatternAnimation extends StatelessWidget {
  const _StarPatternAnimation({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(painter: _AnimatedStarPainter(progress: progress)),
    );
  }
}

class _AnimatedStarPainter extends CustomPainter {
  const _AnimatedStarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw outer ring
    final ringPaint = Paint()
      ..color = TawakkalColors.primary.withValues(alpha: 0.2 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 70 * progress, ringPaint);

    // Draw 8-point star
    final starPaint = Paint()
      ..color = TawakkalColors.accentGold.withValues(alpha: 0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const points = 8;
    final outerRadius = 55.0 * progress;
    final innerRadius = 22.0 * progress;

    final segments = (points * 2 * progress).ceil();
    for (int i = 0; i < segments; i++) {
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (segments >= points * 2) {
      path.close();
    }
    canvas.drawPath(path, starPaint);

    // Draw inner glow
    if (progress > 0.5) {
      final glowPaint = Paint()
        ..color = TawakkalColors.accentGold.withValues(
          alpha: 0.15 * (progress - 0.5) * 2,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(center, 40, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedStarPainter oldDelegate) {
    return oldDelegate.progress != progress;
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

class _ArabicName extends StatelessWidget {
  const _ArabicName();

  @override
  Widget build(BuildContext context) {
    return Text(
      'توكل',
      style: GoogleFonts.notoNaskhArabic(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE7CCA4),
        height: 1.2,
      ),
    );
  }
}

class _InspirationalQuote extends StatelessWidget {
  const _InspirationalQuote();

  @override
  Widget build(BuildContext context) {
    final quotes = [
      {
        'arabic': 'تَوَكَّلْتُ عَلَى اللَّهِ',
        'translation': 'I trust in Allah',
      },
      {
        'arabic': 'رَبِّ زِدْنِي عِلْمًا',
        'translation': 'My Lord, increase me in knowledge',
      },
      {
        'arabic': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ',
        'translation': 'And whoever trusts in Allah',
      },
    ];

    // Use a simple modulo based on time for variety
    final index = DateTime.now().millisecond % quotes.length;
    final quote = quotes[index];

    return Column(
      children: [
        Text(
          quote['arabic']!,
          style: GoogleFonts.notoNaskhArabic(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: TawakkalColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          quote['translation']!,
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
