import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Primary email sign-in button with gradient fill.
/// Visually prominent to encourage secure account creation.
class EmailSigninButton extends StatefulWidget {
  const EmailSigninButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<EmailSigninButton> createState() => _EmailSigninButtonState();
}

class _EmailSigninButtonState extends State<EmailSigninButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _handlePressDown() : null,
      onTapUp: isEnabled ? (_) => _handlePressUp() : null,
      onTapCancel: isEnabled ? _handlePressUp : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isLoading
                      ? [
                          TawakkalColors.primary.withValues(alpha: 0.6),
                          TawakkalColors.primaryDark.withValues(alpha: 0.6),
                        ]
                      : [
                          TawakkalColors.primary,
                          TawakkalColors.primaryDark,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: TawakkalColors.primary.withValues(alpha: 0.3),
                          blurRadius: _isPressed ? 8 : 16,
                          offset: Offset(0, _isPressed ? 4 : 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? _LoadingIndicator()
                    : _ButtonContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePressDown() {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handlePressUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.email_outlined,
          color: TawakkalColors.backgroundDark,
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          'Sign in with Email',
          style: TextStyle(
            color: TawakkalColors.backgroundDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          TawakkalColors.backgroundDark,
        ),
      ),
    );
  }
}
