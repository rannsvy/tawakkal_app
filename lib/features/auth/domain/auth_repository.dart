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
  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> verifySignupOtp({required String email, required String code});
  Future<void> resendSignupOtp({required String email});
  Future<void> requestPasswordResetOtp({required String email});
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String code,
  });
  Future<void> updatePassword({required String newPassword});
  Future<void> signOut();
}
