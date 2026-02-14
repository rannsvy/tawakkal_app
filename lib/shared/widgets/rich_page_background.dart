import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class RichPageBackground extends StatelessWidget {
  const RichPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Colors.black, Colors.black]
              : const [TawakkalColors.backgroundLight, Color(0xFFEEF4F2)],
        ),
      ),
      child: CustomPaint(
        painter: _PatternPainter(
          color: TawakkalColors.primary.withValues(
            alpha: isDark ? 0.055 : 0.04,
          ),
          gap: isDark ? 40.0 : 42.0,
          armHalfLength: isDark ? 3.6 : 4.0,
          strokeWidth: isDark ? 1.15 : 1.2,
        ),
        child: child,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.color,
    required this.gap,
    required this.armHalfLength,
    required this.strokeWidth,
  });

  final Color color;
  final double gap;
  final double armHalfLength;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (double y = 16; y < size.height; y += gap) {
      for (double x = 16; x < size.width; x += gap) {
        canvas.drawLine(
          Offset(x - armHalfLength, y),
          Offset(x + armHalfLength, y),
          paint,
        );
        canvas.drawLine(
          Offset(x, y - armHalfLength),
          Offset(x, y + armHalfLength),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.gap != gap ||
        oldDelegate.armHalfLength != armHalfLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
