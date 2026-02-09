import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<void> signInWithGoogle() async {
    if (_client == null) {
      throw const AppException(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    await _client.auth.signInWithOAuth(OAuthProvider.google);
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
