import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class DiamondIndexBadge extends StatelessWidget {
  const DiamondIndexBadge({
    super.key,
    required this.number,
    this.highlighted = false,
    this.size = 38,
  });

  final int number;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = highlighted
        ? TawakkalColors.accentGold
        : TawakkalColors.primary;
    final diamondSize = size * 0.74;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: diamondSize,
              height: diamondSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: baseColor.withValues(alpha: isDark ? 0.16 : 0.12),
                border: Border.all(
                  color: baseColor.withValues(alpha: isDark ? 0.45 : 0.28),
                ),
              ),
            ),
          ),
          Text(
            '$number',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
