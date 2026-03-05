import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_providers.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  static const routeName = 'auth-gate';

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

enum _AuthTab { login, signUp }

enum _AuthStep { credentials, signupCode, resetCode, setNewPassword }

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  static const _otpLength = 6;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetConfirmController = TextEditingController();
  final _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirm = true;
  bool _obscureResetPassword = true;
  bool _obscureResetConfirm = true;
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  _AuthTab _tab = _AuthTab.login;
  _AuthStep _step = _AuthStep.credentials;

  String? _pendingEmail;
  String? _globalError;
  String? _loginEmailError;
  String? _loginPasswordError;
  String? _signupNameError;
  String? _signupEmailError;
  String? _signupPasswordError;
  String? _signupConfirmError;
  String? _otpError;
  String? _resetPasswordError;
  String? _resetConfirmError;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageTop =>
      _isDark ? const Color(0xFF121513) : const Color(0xFFF1F1F1);
  Color get _pageBottom =>
      _isDark ? const Color(0xFF1A1F1B) : const Color(0xFFE8E8E8);
  Color get _cardBg => _isDark ? const Color(0xFF202623) : Colors.white;
  Color get _cardBorder =>
      _isDark ? const Color(0xFF2D3531) : const Color(0xFFE5E8E5);
  Color get _titleColor =>
      _isDark ? const Color(0xFFF2F4F3) : const Color(0xFF2A2F2B);
  Color get _subtitleColor =>
      _isDark ? const Color(0xFFB2BBB6) : const Color(0xFF7A7F7C);
  Color get _tabActive =>
      _isDark ? const Color(0xFF67B486) : const Color(0xFF2A6E4B);
  Color get _tabInactive =>
      _isDark ? const Color(0xFF2C3430) : const Color(0xFFE4E7E5);
  Color get _fieldBg =>
      _isDark ? const Color(0xFF2A312E) : const Color(0xFFF6F7F6);
  Color get _fieldBorder =>
      _isDark ? const Color(0xFF39433E) : const Color(0xFFE6E9E7);
  Color get _fieldFocus =>
      _isDark ? const Color(0xFF7FCF99) : const Color(0xFF5EA378);
  Color get _fieldText =>
      _isDark ? const Color(0xFFF3F5F4) : const Color(0xFF2F3431);
  Color get _fieldHint =>
      _isDark ? const Color(0xFF8D9892) : const Color(0xFFA3A8A5);
  Color get _primaryButton => const Color(0xFFB7DE72);
  Color get _primaryButtonText =>
      _isDark ? const Color(0xFF1A3121) : const Color(0xFF2C5B3D);
  Color get _linkColor =>
      _isDark ? const Color(0xFF9EDAA5) : const Color(0xFF2A6E4B);

  @override
  void dispose() {
    _resendTimer?.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    _resetPasswordController.dispose();
    _resetConfirmController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
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

    return Scaffold(
      backgroundColor: _pageTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageTop, _pageBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: switch (_step) {
                    _AuthStep.credentials => _buildCredentialsCard(),
                    _AuthStep.signupCode => _buildCodeCard(
                      key: const ValueKey('signup-code'),
                      title: 'Enter Verification Code',
                      subtitle:
                          'We have sent a code to ${_maskEmail(_pendingEmail ?? '')}',
                      onVerify: _handleVerifySignupCode,
                    ),
                    _AuthStep.resetCode => _buildCodeCard(
                      key: const ValueKey('reset-code'),
                      title: 'Enter Reset Code',
                      subtitle:
                          'We have sent a code to ${_maskEmail(_pendingEmail ?? '')}',
                      onVerify: _handleVerifyResetCode,
                    ),
                    _AuthStep.setNewPassword => _buildResetPasswordCard(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return _buildCard(
      key: const ValueKey('auth-credentials'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandWordmark(),
          const SizedBox(height: 16),
          Text(
            'Welcome to Tawakkal',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _titleColor,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign up or login below to manage your learning, Quran reading, and productivity.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _subtitleColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _buildTabSwitcher(),
          const SizedBox(height: 14),
          if (_tab == _AuthTab.login)
            ..._buildLoginChildren()
          else
            ..._buildSignupChildren(),
          if (_globalError != null) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(_globalError!),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : _continueAsGuest,
              child: Text(
                'Continue as Guest',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLoginChildren() {
    return [
      _buildGoogleButton(),
      const SizedBox(height: 14),
      _buildDividerLabel('or continue with email'),
      const SizedBox(height: 14),
      _buildTextField(
        controller: _loginEmailController,
        hint: 'Enter your email',
        prefixIcon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        errorText: _loginEmailError,
        onChanged: (_) => setState(() {
          _loginEmailError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _loginPasswordController,
        hint: 'Enter your password',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: _obscureLoginPassword,
        errorText: _loginPasswordError,
        suffixIcon: IconButton(
          onPressed: _isSubmitting
              ? null
              : () => setState(
                  () => _obscureLoginPassword = !_obscureLoginPassword,
                ),
          icon: Icon(
            _obscureLoginPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: _fieldHint,
          ),
        ),
        onChanged: (_) => setState(() {
          _loginPasswordError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _isSubmitting ? null : _handleSendResetCode,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _linkColor,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _buildPrimaryButton(
        label: 'Login',
        onPressed: _isSubmitting ? null : _handleEmailLogin,
      ),
      const SizedBox(height: 14),
      Text(
        'By signing up, you agree to our Terms of Service and Privacy Policy.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: _subtitleColor,
          height: 1.4,
        ),
      ),
    ];
  }

  List<Widget> _buildSignupChildren() {
    return [
      _buildTextField(
        controller: _signupNameController,
        hint: 'Your name',
        prefixIcon: Icons.person_outline_rounded,
        errorText: _signupNameError,
        onChanged: (_) => setState(() {
          _signupNameError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _signupEmailController,
        hint: 'Enter your email',
        prefixIcon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        errorText: _signupEmailError,
        onChanged: (_) => setState(() {
          _signupEmailError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _signupPasswordController,
        hint: 'Enter your password',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: _obscureSignupPassword,
        errorText: _signupPasswordError,
        suffixIcon: IconButton(
          onPressed: _isSubmitting
              ? null
              : () => setState(
                  () => _obscureSignupPassword = !_obscureSignupPassword,
                ),
          icon: Icon(
            _obscureSignupPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: _fieldHint,
          ),
        ),
        onChanged: (_) => setState(() {
          _signupPasswordError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _signupConfirmController,
        hint: 'Confirm your password',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: _obscureSignupConfirm,
        errorText: _signupConfirmError,
        suffixIcon: IconButton(
          onPressed: _isSubmitting
              ? null
              : () => setState(
                  () => _obscureSignupConfirm = !_obscureSignupConfirm,
                ),
          icon: Icon(
            _obscureSignupConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: _fieldHint,
          ),
        ),
        onChanged: (_) => setState(() {
          _signupConfirmError = null;
          _globalError = null;
        }),
      ),
      const SizedBox(height: 12),
      _buildPasswordRules(),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptTerms,
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _acceptTerms = value ?? false),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: _fieldBorder),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'By agreeing to the terms and conditions, you are entering into a legally binding contract with the service provider.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _subtitleColor,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _buildPrimaryButton(
        label: 'Sign Up',
        onPressed: _isSubmitting ? null : _handleSignUp,
      ),
    ];
  }

  Widget _buildCodeCard({
    required Key key,
    required String title,
    required String subtitle,
    required Future<void> Function() onVerify,
  }) {
    return _buildCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _isSubmitting ? null : _backToCredentials,
                icon: Icon(Icons.arrow_back_rounded, color: _titleColor),
              ),
              const Expanded(child: _BrandWordmark(compact: true)),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _titleColor,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: _subtitleColor),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, _buildOtpField),
          ),
          if (_otpError != null) ...[
            const SizedBox(height: 10),
            Text(
              _otpError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFE36D6D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_globalError != null) ...[
            const SizedBox(height: 10),
            _buildErrorBanner(_globalError!),
          ],
          const SizedBox(height: 18),
          _buildPrimaryButton(
            label: 'Verify Now',
            onPressed: _isSubmitting ? null : onVerify,
          ),
          const SizedBox(height: 12),
          Center(
            child: _resendCountdown > 0
                ? Text(
                    'Resend code in ${_resendCountdown}s',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _subtitleColor,
                    ),
                  )
                : TextButton(
                    onPressed: _isSubmitting ? null : _resendCode,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _linkColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordCard() {
    return _buildCard(
      key: const ValueKey('set-new-password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _isSubmitting ? null : _backToCredentials,
                icon: Icon(Icons.arrow_back_rounded, color: _titleColor),
              ),
              const Expanded(child: _BrandWordmark(compact: true)),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set New Password',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _titleColor,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use a strong password with at least 8 characters, 1 number, and upper/lowercase letters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: _subtitleColor),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _resetPasswordController,
            hint: 'New password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureResetPassword,
            errorText: _resetPasswordError,
            suffixIcon: IconButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(
                      () => _obscureResetPassword = !_obscureResetPassword,
                    ),
              icon: Icon(
                _obscureResetPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _fieldHint,
              ),
            ),
            onChanged: (_) => setState(() {
              _resetPasswordError = null;
              _globalError = null;
            }),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _resetConfirmController,
            hint: 'Confirm new password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureResetConfirm,
            errorText: _resetConfirmError,
            suffixIcon: IconButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(
                      () => _obscureResetConfirm = !_obscureResetConfirm,
                    ),
              icon: Icon(
                _obscureResetConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _fieldHint,
              ),
            ),
            onChanged: (_) => setState(() {
              _resetConfirmError = null;
              _globalError = null;
            }),
          ),
          if (_globalError != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_globalError!),
          ],
          const SizedBox(height: 16),
          _buildPrimaryButton(
            label: 'Update Password',
            onPressed: _isSubmitting ? null : _handleUpdatePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Key key, required Widget child}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _isDark ? const Color(0x55000000) : const Color(0x1E1A1A1A),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: child,
      ),
    );
  }

  Widget _buildTabSwitcher() {
    Widget buildTab(_AuthTab value, String label) {
      final selected = _tab == value;
      return Expanded(
        child: InkWell(
          onTap: _isSubmitting
              ? null
              : () => setState(() {
                  _tab = value;
                  _clearCredentialErrors();
                  _globalError = null;
                }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? _tabActive : _tabInactive,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _tabActive : _subtitleColor,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildTab(_AuthTab.login, 'Login'),
        buildTab(_AuthTab.signUp, 'Sign Up'),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return InkWell(
      onTap: _isSubmitting ? null : _handleGoogleLogin,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF2A312E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _fieldBorder),
        ),
        child: Center(
          child: _isSubmitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _linkColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/google.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Login with Google',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDividerLabel(String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: _fieldBorder)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: _subtitleColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: _fieldBorder)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isSubmitting,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: _fieldText),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBg,
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _fieldHint),
        prefixIcon: Icon(prefixIcon, size: 20, color: _fieldHint),
        suffixIcon: suffixIcon,
        errorText: errorText,
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFFE36D6D),
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _fieldFocus, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: onPressed == null
            ? _primaryButton.withValues(alpha: 0.65)
            : _primaryButton,
        foregroundColor: _primaryButtonText,
        textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSubmitting
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: _primaryButtonText,
              ),
            )
          : Text(label),
    );
  }

  Widget _buildPasswordRules() {
    final password = _signupPasswordController.text;

    Widget buildRule(bool met, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: met ? _linkColor : _fieldHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 12, color: _subtitleColor),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRule(password.length >= 8, 'At least 8 characters'),
        buildRule(RegExp(r'\d').hasMatch(password), 'At least 1 number'),
        buildRule(
          RegExp(r'[A-Z]').hasMatch(password) &&
              RegExp(r'[a-z]').hasMatch(password),
          'Both upper and lower case letters',
        ),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 46,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        enabled: !_isSubmitting,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _fieldText,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (_otpError != null || _globalError != null) {
            setState(() {
              _otpError = null;
              _globalError = null;
            });
          }
          if (value.isNotEmpty && index < _otpLength - 1) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _fieldBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _fieldFocus, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE36D6D).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE36D6D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE36D6D),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isDark
                    ? const Color(0xFFFFC5C5)
                    : const Color(0xFF9A2E2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _globalError = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(authControllerProvider.notifier).continueAsGuest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _globalError = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogleDirect();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    setState(() {
      _loginEmailError = _validateEmail(email);
      _loginPasswordError = _validatePassword(password, strict: false);
      _globalError = null;
    });
    if (_loginEmailError != null || _loginPasswordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmailDirect(email: email, password: password);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    final fullName = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirm = _signupConfirmController.text;

    setState(() {
      _signupNameError = fullName.isEmpty ? 'Name is required.' : null;
      _signupEmailError = _validateEmail(email);
      _signupPasswordError = _validatePassword(password, strict: true);
      _signupConfirmError = confirm == password
          ? null
          : 'Password confirmation does not match.';
      _globalError = null;
    });

    if (!_acceptTerms) {
      setState(() {
        _globalError = 'Please accept the terms and conditions to continue.';
      });
      return;
    }

    if (_signupNameError != null ||
        _signupEmailError != null ||
        _signupPasswordError != null ||
        _signupConfirmError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final requiresVerification = await ref
          .read(authControllerProvider.notifier)
          .signUpWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          );
      if (!mounted) {
        return;
      }
      if (requiresVerification) {
        _prepareCodeStep(_AuthStep.signupCode, email);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleSendResetCode() async {
    final email = _loginEmailController.text.trim();
    setState(() {
      _loginEmailError = _validateEmail(email);
      _globalError = null;
    });
    if (_loginEmailError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordResetOtp(email: email);
      if (!mounted) {
        return;
      }
      _prepareCodeStep(_AuthStep.resetCode, email);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleVerifySignupCode() async {
    final email = _pendingEmail;
    if (email == null || email.isEmpty) {
      setState(() => _globalError = 'Missing email for verification.');
      return;
    }
    if (_otpCode.length != _otpLength) {
      setState(() => _otpError = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _otpError = null;
      _globalError = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifySignupOtp(email: email, code: _otpCode);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleVerifyResetCode() async {
    final email = _pendingEmail;
    if (email == null || email.isEmpty) {
      setState(() => _globalError = 'Missing email for verification.');
      return;
    }
    if (_otpCode.length != _otpLength) {
      setState(() => _otpError = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _otpError = null;
      _globalError = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyPasswordResetOtp(email: email, code: _otpCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _AuthStep.setNewPassword;
        _clearResetPasswordErrors();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isSubmitting) {
      return;
    }
    final email = _pendingEmail;
    if (email == null || email.isEmpty) {
      setState(() => _globalError = 'Missing email for resend.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });
    try {
      final notifier = ref.read(authControllerProvider.notifier);
      if (_step == _AuthStep.signupCode) {
        await notifier.resendSignupOtp(email: email);
      } else if (_step == _AuthStep.resetCode) {
        await notifier.requestPasswordResetOtp(email: email);
      }
      _startResendCountdown();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleUpdatePassword() async {
    final password = _resetPasswordController.text;
    final confirm = _resetConfirmController.text;
    setState(() {
      _resetPasswordError = _validatePassword(password, strict: true);
      _resetConfirmError = confirm == password
          ? null
          : 'Password confirmation does not match.';
      _globalError = null;
    });
    if (_resetPasswordError != null || _resetConfirmError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updatePassword(newPassword: password);
      if (!mounted) {
        return;
      }
      context.go('/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalError = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _prepareCodeStep(_AuthStep step, String email) {
    _clearOtpFields();
    _clearCredentialErrors();
    _clearResetPasswordErrors();
    _startResendCountdown();
    setState(() {
      _pendingEmail = email;
      _step = step;
      _otpError = null;
      _globalError = null;
    });
    FocusScope.of(context).requestFocus(_otpFocusNodes.first);
  }

  void _backToCredentials() {
    _resendTimer?.cancel();
    setState(() {
      _step = _AuthStep.credentials;
      _resendCountdown = 0;
      _otpError = null;
      _globalError = null;
      _clearOtpFields();
      _clearResetPasswordErrors();
    });
  }

  void _startResendCountdown([int seconds = 30]) {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendCountdown <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendCountdown -= 1);
    });
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  void _clearCredentialErrors() {
    _loginEmailError = null;
    _loginPasswordError = null;
    _signupNameError = null;
    _signupEmailError = null;
    _signupPasswordError = null;
    _signupConfirmError = null;
  }

  void _clearResetPasswordErrors() {
    _resetPasswordError = null;
    _resetConfirmError = null;
  }

  String get _otpCode =>
      _otpControllers.map((controller) => controller.text).join();

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email is required.';
    }
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value, {required bool strict}) {
    if (value.isEmpty) {
      return 'Password is required.';
    }
    if (!strict && value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (strict) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters.';
      }
      if (!RegExp(r'\d').hasMatch(value)) {
        return 'Password must contain at least one number.';
      }
      if (!RegExp(r'[A-Z]').hasMatch(value) ||
          !RegExp(r'[a-z]').hasMatch(value)) {
        return 'Password must contain upper and lower case letters.';
      }
    }
    return null;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return email;
    }
    final local = parts.first;
    if (local.length <= 2) {
      return email;
    }
    return '${local.substring(0, 2)}${'*' * (local.length - 2)}@${parts.last}';
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (normalized.contains('email not confirmed') ||
        normalized.contains('email_not_confirmed')) {
      return 'Email is not verified yet. Please check your code and verify first.';
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already been registered')) {
      return 'This email is already registered. Please login instead.';
    }
    if (normalized.contains('expired') && normalized.contains('token')) {
      return 'The verification code has expired. Please request a new one.';
    }
    if (normalized.contains('token') && normalized.contains('invalid')) {
      return 'Invalid verification code. Please check and try again.';
    }
    if (normalized.contains('network') || normalized.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (normalized.contains('supabase is not configured')) {
      return 'Authentication is not configured yet. Please contact support.';
    }
    return raw.replaceFirst('Exception: ', '').trim();
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentOrange = Color(0xFFF2AE8F);
    const lightThemeGreen = Color(0xFF1F5F44);
    final baseColor = isDark ? accentOrange : lightThemeGreen;
    final wordSize = compact ? 28.0 : 32.0;
    final iconSize = compact ? 26.0 : 30.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/tawakkal_logo.svg',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Ta',
                style: GoogleFonts.inter(
                  fontSize: wordSize,
                  fontWeight: FontWeight.w700,
                  color: baseColor,
                ),
              ),
              TextSpan(
                text: 'wak',
                style: GoogleFonts.inter(
                  fontSize: wordSize,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : baseColor,
                ),
              ),
              TextSpan(
                text: 'kal',
                style: GoogleFonts.inter(
                  fontSize: wordSize,
                  fontWeight: FontWeight.w700,
                  color: baseColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
