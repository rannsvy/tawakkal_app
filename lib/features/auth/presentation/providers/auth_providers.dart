import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(secureStorage: secureStorage, client: client);
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, TawakkalUser?>(AuthController.new);

final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.asData?.value?.id ?? 'guest';
});

class AuthController extends AsyncNotifier<TawakkalUser?> {
  StreamSubscription<TawakkalUser?>? _subscription;

  @override
  Future<TawakkalUser?> build() async {
    final repository = ref.read(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = repository.authStateChanges().listen((user) {
      state = AsyncData(user);
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return repository.currentUser();
  }

  Future<void> continueAsGuest() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.continueAsGuest);
  }

  Future<void> signInWithGoogle() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signInWithGoogle();
      return repository.currentUser();
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signInWithEmail(email: email, password: password);
      return repository.currentUser();
    });
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    state = const AsyncData(null);
  }
}
