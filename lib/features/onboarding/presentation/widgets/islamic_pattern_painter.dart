import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';

/// A custom painter that renders an 8-point Islamic geometric star pattern.
/// This pattern is based on traditional Girih tile systems used in Islamic art.
class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({
    this.opacity = 0.08,
    this.animationProgress = 1.0,
    this.color,
  });

  final double opacity;
  final double animationProgress;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = color ?? TawakkalColors.primary;
    final paint = Paint()
      ..color = baseColor.withValues(alpha: (opacity * animationProgress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    _drawStarPattern(canvas, size, paint);
    _drawConnectingLines(canvas, size, paint);
  }

  /// Draws the 8-point star pattern across the canvas
  void _drawStarPattern(Canvas canvas, Size size, Paint paint) {
    const starSize = 80.0;
    const spacing = 140.0;

    // Calculate offset for parallax effect based on animation
    final animatedOffset = (1 - animationProgress) * spacing;

    for (double y = -starSize + animatedOffset; y < size.height + starSize; y += spacing) {
      for (double x = -starSize; x < size.width + starSize; x += spacing) {
        final offset = Offset(x, y);
        _drawEightPointStar(canvas, offset, starSize, paint);
      }
    }
  }

  /// Draws a single 8-point Islamic star
  void _drawEightPointStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 8;
    final outerRadius = size / 2;
    final innerRadius = size / 3.5;

    for (int i = 0; i < points * 2; i++) {
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
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draws interconnecting geometric lines for tessellation effect
  void _drawConnectingLines(Canvas canvas, Size size, Paint paint) {
    const spacing = 140.0;
    const connectionRadius = 50.0;

    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        final center = Offset(x, y);

        // Draw small connecting circles at intersections
        final circlePaint = Paint()
          ..color = paint.color.withValues(alpha: 0.5 * _getAlphaRatio(paint.color))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(center, 2, circlePaint);

        // Draw octagon around each star
        _drawOctagon(canvas, center, connectionRadius, paint);
      }
    }
  }

  /// Draws an octagon around each star center
  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const sides = 8;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi) / sides - math.pi / 8;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
           oldDelegate.animationProgress != animationProgress ||
           oldDelegate.color != color;
  }

  double _getAlphaRatio(Color color) {
    // Helper to get alpha ratio from Color (0-1 range)
    return color.a / 255.0;
  }
}

/// A corner-only version of the Islamic pattern for card decorations
class IslamicPatternCornerPainter extends CustomPainter {
  const IslamicPatternCornerPainter({
    required this.position,
    this.opacity = 0.12,
    this.color,
  });

  final CornerPosition position;
  final double opacity;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = color ?? TawakkalColors.accentGold;
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final corner = _getCornerOffset(size);
    _drawCornerPattern(canvas, corner, paint);
  }

  Offset _getCornerOffset(Size size) {
    switch (position) {
      case CornerPosition.topLeft:
        return Offset(size.width * 0.15, size.height * 0.15);
      case CornerPosition.topRight:
        return Offset(size.width * 0.85, size.height * 0.15);
      case CornerPosition.bottomLeft:
        return Offset(size.width * 0.15, size.height * 0.85);
      case CornerPosition.bottomRight:
        return Offset(size.width * 0.85, size.height * 0.85);
    }
  }

  void _drawCornerPattern(Canvas canvas, Offset center, Paint paint) {
    const radius = 40.0;

    // Draw 8-point star at corner
    final path = Path();
    const points = 8;
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i % 2 == 0 ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw surrounding arcs
    final arcPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.6 * _getAlphaRatio(paint.color))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 2 + math.pi / 4;
      final arcCenter = Offset(
        center.dx + radius * 1.2 * math.cos(angle),
        center.dy + radius * 1.2 * math.sin(angle),
      );
      canvas.drawCircle(arcCenter, 4, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternCornerPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.opacity != opacity ||
           oldDelegate.color != color;
  }

  double _getAlphaRatio(Color color) {
    return color.a / 255.0;
  }
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }
