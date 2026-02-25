import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';

/// Secondary Google sign-in button with outlined style.
/// Less prominent than email button but still accessible.
class GoogleSigninButton extends StatefulWidget {
  const GoogleSigninButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<GoogleSigninButton> createState() => _GoogleSigninButtonState();
}

class _GoogleSigninButtonState extends State<GoogleSigninButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: isEnabled ? _controller.reverse : null,
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isLoading
                      ? TawakkalColors.surfaceDarkAlt.withValues(alpha: 0.5)
                      : TawakkalColors.surfaceDarkAlt,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: widget.isLoading ? _ShimmerLoading() : _ButtonContent(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset('assets/icons/google.svg', width: 22, height: 22),
        const SizedBox(width: 12),
        Text(
          'Continue with Google',
          style: TextStyle(
            color: TawakkalColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Base content (dimmed)
              Opacity(opacity: 0.3, child: _ButtonContent()),
              // Shimmer overlay
              Positioned.fill(
                child: _ShimmerEffect(progress: _shimmerAnimation.value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerEffect extends StatelessWidget {
  const _ShimmerEffect({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            TawakkalColors.primary.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: [
            progress.clamp(0.0, 1.0),
            (progress + 0.3).clamp(0.0, 1.0),
            (progress + 0.6).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
