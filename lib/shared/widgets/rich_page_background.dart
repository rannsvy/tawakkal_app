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
              ? const [TawakkalColors.backgroundDark, Color(0xFF141F1C)]
              : const [TawakkalColors.backgroundLight, Color(0xFFEEF4F2)],
        ),
      ),
      child: CustomPaint(
        painter: _PatternPainter(
          color: TawakkalColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
        ),
        child: child,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const gap = 42.0;
    for (double y = 16; y < size.height; y += gap) {
      for (double x = 16; x < size.width; x += gap) {
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), paint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
