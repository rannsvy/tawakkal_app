import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import 'email_signin_button.dart';
import 'google_signin_button.dart';
import 'guest_link_button.dart';

/// A glassmorphism card containing authentication options.
/// Provides clear visual hierarchy with email as primary option.
class AuthOptionsCard extends StatelessWidget {
  const AuthOptionsCard({
    required this.onEmailTap,
    required this.onGoogleTap,
    required this.onGuestTap,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onEmailTap;
  final VoidCallback onGoogleTap;
  final VoidCallback onGuestTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _glassmorphismDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary: Email
            EmailSigninButton(
              onPressed: isLoading ? null : onEmailTap,
              isLoading: isLoading,
            ),
            const SizedBox(height: 12),
            // Secondary: Google
            GoogleSigninButton(
              onPressed: isLoading ? null : onGoogleTap,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            // Divider
            Divider(
              color: TawakkalColors.surfaceDarkAlt,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
            // Tertiary: Guest
            GuestLinkButton(
              onPressed: isLoading ? null : onGuestTap,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _glassmorphismDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          TawakkalColors.surfaceDark.withValues(alpha: 0.95),
          TawakkalColors.surfaceDarkAlt.withValues(alpha: 0.98),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: TawakkalColors.accentGold.withValues(alpha: 0.12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: TawakkalColors.primary.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }
}
