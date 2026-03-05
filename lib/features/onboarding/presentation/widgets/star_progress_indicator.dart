import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// A compact pill/dot indicator for onboarding progress.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? TawakkalColors.primary
        : const Color(0xFF2F7F55);
    final inactiveColor = isDark
        ? TawakkalColors.textSecondary.withValues(alpha: 0.35)
        : const Color(0xFFCCD8D3);

    return SizedBox(
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount, (index) {
          final isActive = index == currentIndex;
          final isPast = index < currentIndex;
          final dotColor = isActive
              ? activeColor
              : isPast
              ? activeColor.withValues(alpha: 0.55)
              : inactiveColor;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 16 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }
}
