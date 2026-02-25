import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../onboarding/presentation/widgets/islamic_pattern_painter.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_hero_section.dart';
import '../widgets/auth_options_card.dart';
import '../widgets/email_signin_sheet.dart';

/// The authentication gate page.
/// Features:
/// - Islamic geometric pattern background
/// - Staggered entrance animations
/// - Clear visual hierarchy (Email primary, Google secondary, Guest tertiary)
/// - Glassmorphism auth container
class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  static const routeName = 'auth-gate';

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _containerAnimation;

  @override
  void initState() {
    super.initState();
    _containerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Start container animation after hero section (450ms delay)
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        _containerAnimation.forward();
      }
    });
  }

  @override
  void dispose() {
    _containerAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(authControllerProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null && context.mounted) {
        context.go('/home');
      }
    });

    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Islamic pattern background
          _buildPatternBackground(),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Hero section with animated logo
                  const AuthHeroSection(),
                  const Spacer(flex: 3),
                  // Auth options card with staggered animation
                  AnimatedBuilder(
                    animation: _containerAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - _containerAnimation.value)),
                        child: Opacity(
                          opacity: _containerAnimation.value,
                          child: AuthOptionsCard(
                            onEmailTap: _showEmailSignInSheet,
                            onGoogleTap: _handleGoogleSignIn,
                            onGuestTap: _handleGuestAccess,
                            isLoading: isLoading,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 1),
                  // Error message (if any)
                  if (state.hasError) _buildErrorMessage(state.error.toString()),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: IslamicPatternPainter(
          opacity: 0.06,
          color: TawakkalColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TawakkalColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TawakkalColors.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: TawakkalColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getReadableError(error),
              style: const TextStyle(
                fontSize: 13,
                color: TawakkalColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailSignInSheet() async {
    await EmailSigninSheet.show(context);
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  Future<void> _handleGuestAccess() async {
    await ref.read(authControllerProvider.notifier).continueAsGuest();
  }

  String _getReadableError(String error) {
    if (error.contains('Invalid') || error.contains('credentials')) {
      return 'Authentication failed. Please try again.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (error.contains('cancelled') || error.contains('aborted')) {
      return 'Sign in was cancelled.';
    }
    return 'An error occurred. Please try again.';
  }
}
