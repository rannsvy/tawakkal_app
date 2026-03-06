import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SecureStorageService secureStorage,
    required SupabaseClient? client,
  }) : _secureStorage = secureStorage,
       _client = client;

  final SecureStorageService _secureStorage;
  final SupabaseClient? _client;

  @override
  Stream<TawakkalUser?> authStateChanges() async* {
    final guestEnabled = await _secureStorage.isGuestModeEnabled();
    if (guestEnabled) {
      yield TawakkalUser.guest();
    }

    if (_client == null) {
      return;
    }

    yield _toAuthUser(_client.auth.currentUser);
    yield* _client.auth.onAuthStateChange.map(
      (event) => _toAuthUser(event.session?.user),
    );
  }

  @override
  Future<TawakkalUser?> currentUser() async {
    final guestEnabled = await _secureStorage.isGuestModeEnabled();
    if (guestEnabled) {
      return TawakkalUser.guest();
    }
    if (_client == null) {
      return null;
    }
    return _toAuthUser(_client.auth.currentUser);
  }

  @override
  Future<TawakkalUser> continueAsGuest() async {
    await _secureStorage.setGuestMode(true);
    return TawakkalUser.guest();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.signInWithPassword(email: email, password: password);
    await _secureStorage.setGuestMode(false);
  }

  @override
  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kIsWeb ? null : AppConfig.oauthCallbackUrl,
      data: <String, dynamic>{'full_name': fullName},
    );

    final responseEmail = response.user?.email?.trim().toLowerCase();
    final requestedEmail = email.trim().toLowerCase();
    final hasObfuscatedIdentities = response.user?.identities?.isEmpty ?? false;
    final hasEmailMismatch =
        responseEmail != null && responseEmail != requestedEmail;
    final isLikelyRepeatedSignup =
        response.session == null &&
        (hasObfuscatedIdentities || hasEmailMismatch);

    if (isLikelyRepeatedSignup) {
      throw const AppException(
        'This email is already registered. Please login instead.',
      );
    }

    final requiresVerification = response.session == null;
    if (!requiresVerification) {
      await _secureStorage.setGuestMode(false);
    }
    return requiresVerification;
  }

  @override
  Future<void> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.signup,
    );
    await _secureStorage.setGuestMode(false);
  }

  @override
  Future<void> resendSignupOtp({required String email}) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: kIsWeb ? null : AppConfig.oauthCallbackUrl,
    );
  }

  @override
  Future<void> requestPasswordResetOtp({required String email}) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: kIsWeb ? null : AppConfig.oauthCallbackUrl,
    );
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    await _secureStorage.setGuestMode(false);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signInWithGoogle() async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : AppConfig.oauthCallbackUrl,
    );
    await _secureStorage.setGuestMode(false);
  }

  @override
  Future<void> signOut() async {
    await _secureStorage.setGuestMode(false);
    if (_client != null) {
      await _client.auth.signOut();
    }
  }

  TawakkalUser? _toAuthUser(User? user) {
    if (user == null) {
      return null;
    }
    return TawakkalUser(
      id: user.id,
      displayName:
          user.userMetadata?['full_name'] as String? ??
          user.email?.split('@').first ??
          'User',
      email: user.email,
      isGuest: false,
    );
  }
}
