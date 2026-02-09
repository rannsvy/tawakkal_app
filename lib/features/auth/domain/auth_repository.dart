import 'auth_user.dart';

abstract class AuthRepository {
  Future<TawakkalUser?> currentUser();
  Stream<TawakkalUser?> authStateChanges();
  Future<TawakkalUser> continueAsGuest();
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
}
