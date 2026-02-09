import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class RichInfoCard extends StatelessWidget {
  const RichInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.gradient,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: gradient == null
            ? (color ??
                  (isDark
                      ? TawakkalColors.surfaceDark.withValues(alpha: 0.8)
                      : TawakkalColors.surfaceLight))
            : null,
        border: Border.all(
          color: isDark ? const Color(0x18FFFFFF) : const Color(0x12000000),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return Material(color: Colors.transparent, child: card);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
