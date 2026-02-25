import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';

/// A star-shaped progress indicator that illuminates points as user progresses.
/// Instead of generic dots, uses segments of an 8-point star pattern.
class StarProgressIndicator extends StatelessWidget {
  const StarProgressIndicator({
    required this.currentIndex,
    required this.totalCount,
    super.key,
  });

  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount, (index) {
          return _StarPoint(
            isActive: index == currentIndex,
            isPast: index < currentIndex,
          );
        }),
      ),
    );
  }
}

class _StarPoint extends StatelessWidget {
  const _StarPoint({
    required this.isActive,
    required this.isPast,
  });

  final bool isActive;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (isActive) {
        return TawakkalColors.primary;
      }
      if (isPast) {
        return TawakkalColors.primary.withValues(alpha: 0.5);
      }
      return TawakkalColors.textSecondary.withValues(alpha: 0.3);
    }

    final color = getColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedScale(
        scale: isActive ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: CustomPaint(
          size: const Size(20, 20),
          painter: _StarPointPainter(color: color, isActive: isActive),
        ),
      ),
    );
  }
}

class _StarPointPainter extends CustomPainter {
  const _StarPointPainter({
    required this.color,
    required this.isActive,
  });

  final Color color;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    // Draw diamond/star shape (simplified 4-point star)
    final outerRadius = size.width / 2;
    final innerRadius = size.width / 5;

    const points = 4;
    for (int i = 0; i < points * 2; i++) {
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 4;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill the star
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Add glow effect for active state
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPointPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}
