import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Tertiary guest access option as a text link.
/// Minimal visual weight to indicate lowest commitment.
class GuestLinkButton extends StatefulWidget {
  const GuestLinkButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback? onPressed;

  @override
  State<GuestLinkButton> createState() => _GuestLinkButtonState();
}

class _GuestLinkButtonState extends State<GuestLinkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _underlineAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _underlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return MouseRegion(
      onEnter: isEnabled ? (_) => _handleHover(true) : null,
      onExit: isEnabled ? (_) => _handleHover(false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedBuilder(
            animation: _underlineAnimation,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: _isHovered
                            ? TawakkalColors.textAccentGold
                            : TawakkalColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: _isHovered
                              ? TawakkalColors.textAccentGold
                              : TawakkalColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '·',
                        style: TextStyle(
                          color: _isHovered
                              ? TawakkalColors.textAccentGold.withValues(alpha: 0.7)
                              : TawakkalColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Limited access',
                        style: TextStyle(
                          color: _isHovered
                              ? TawakkalColors.textAccentGold.withValues(alpha: 0.8)
                              : TawakkalColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Animated underline
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _underlineAnimation.value,
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TawakkalColors.accentGold.withValues(alpha: 0.0),
                              TawakkalColors.accentGold.withValues(alpha: 0.8),
                              TawakkalColors.accentGold.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleHover(bool hovered) {
    setState(() => _isHovered = hovered);
    if (hovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
}
