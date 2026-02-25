import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/colors.dart';
import '../providers/auth_providers.dart';

/// A modern bottom sheet for email sign-in.
/// Draggable, with proper input fields and loading states.
class EmailSigninSheet extends ConsumerStatefulWidget {
  const EmailSigninSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      routeSettings: const RouteSettings(name: 'email-signin-sheet'),
      builder: (context) => const EmailSigninSheet(),
    );
  }

  @override
  ConsumerState<EmailSigninSheet> createState() => _EmailSigninSheetState();
}

class _EmailSigninSheetState extends ConsumerState<EmailSigninSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate
    setState(() {
      _emailError = _emailController.text.trim().isEmpty
          ? 'Email is required'
          : (!_emailController.text.contains('@'))
              ? 'Please enter a valid email'
              : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'Password is required'
          : _passwordController.text.length < 6
              ? 'Password must be at least 6 characters'
              : null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    // Attempt sign in
    await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final hasError = authState.hasError;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: _sheetDecoration(context),
            child: Column(
              children: [
                // Drag handle
                _DragHandle(),
                // Header
                _SheetHeader(),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Email field
                        _EmailField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          errorText: _emailError,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        _PasswordField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          errorText: _passwordError,
                          obscureText: _obscurePassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 8),
                        // Forgot password link
                        _ForgotPasswordLink(),
                        const SizedBox(height: 24),
                        // Error message
                        if (hasError)
                          _ErrorMessage(
                            error: authState.error.toString(),
                          ),
                        const SizedBox(height: 16),
                        // Submit button
                        _SubmitButton(
                          onPressed: isLoading ? null : _handleSubmit,
                          isLoading: isLoading,
                        ),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _sheetDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          TawakkalColors.surfaceDark,
          TawakkalColors.backgroundMoss,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      border: Border(
        top: BorderSide(
          color: TawakkalColors.accentGold.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: TawakkalColors.surfaceDarkAlt,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: TawakkalColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Sign in with Email',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: TawakkalColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    this.errorText,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: TawakkalColors.surfaceDarkAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText != null
              ? TawakkalColors.danger
              : hasFocus
                  ? TawakkalColors.primary
                  : Colors.transparent,
          width: errorText != null ? 1.5 : hasFocus ? 1.5 : 1,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: TawakkalColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: TawakkalColors.textPrimaryDark,
        ),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            color: TawakkalColors.textSecondary,
          ),
          hintText: 'your@email.com',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: TawakkalColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color: hasFocus ? TawakkalColors.primary : TawakkalColors.textSecondary,
          ),
          errorText: errorText,
          errorStyle: GoogleFonts.inter(
            fontSize: 12,
            color: TawakkalColors.danger,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    this.errorText,
    this.obscureText = true,
    this.onToggleObscure,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: TawakkalColors.surfaceDarkAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText != null
              ? TawakkalColors.danger
              : hasFocus
                  ? TawakkalColors.primary
                  : Colors.transparent,
          width: errorText != null ? 1.5 : hasFocus ? 1.5 : 1,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: TawakkalColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isLoading,
        obscureText: obscureText,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onToggleObscure?.call(),
        style: GoogleFonts.inter(
          fontSize: 16,
          color: TawakkalColors.textPrimaryDark,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            color: TawakkalColors.textSecondary,
          ),
          hintText: '••••••••',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: TawakkalColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: hasFocus ? TawakkalColors.primary : TawakkalColors.textSecondary,
          ),
          suffixIcon: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: TawakkalColors.textSecondary,
            ),
          ),
          errorText: errorText,
          errorStyle: GoogleFonts.inter(
            fontSize: 12,
            color: TawakkalColors.danger,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password flow
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forgot password feature coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        child: Text(
          'Forgot password?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: TawakkalColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TawakkalColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TawakkalColors.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
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
              style: GoogleFonts.inter(
                fontSize: 13,
                color: TawakkalColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getReadableError(String error) {
    // Convert common error messages to user-friendly text
    if (error.contains('Invalid login')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('User not found')) {
      return 'No account found with this email.';
    }
    if (error.contains('wrong password')) {
      return 'Incorrect password. Please try again.';
    }
    return error;
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed != null
                ? [
                    TawakkalColors.primary,
                    TawakkalColors.primaryDark,
                  ]
                : [
                    TawakkalColors.primary.withValues(alpha: 0.5),
                    TawakkalColors.primaryDark.withValues(alpha: 0.5),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: TawakkalColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      TawakkalColors.backgroundDark,
                    ),
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TawakkalColors.backgroundDark,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
