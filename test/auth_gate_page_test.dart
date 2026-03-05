import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/auth/domain/auth_repository.dart';
import 'package:tawakkal_app/features/auth/domain/auth_user.dart';
import 'package:tawakkal_app/features/auth/presentation/pages/auth_gate_page.dart';
import 'package:tawakkal_app/features/auth/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('auth gate shows login and signup tabs with brand wordmark', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final fakeRepo = _FakeAuthRepository();

    await tester.pumpWidget(_buildTestApp(fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Tawakkal'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
    expect(find.byType(RichText), findsAtLeastNWidgets(1));
  });

  testWidgets('signup submits and opens verification code step', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final fakeRepo = _FakeAuthRepository();

    await tester.pumpWidget(_buildTestApp(fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Tester');
    await tester.enterText(find.byType(TextField).at(1), 'tester@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'Password123');
    await tester.enterText(find.byType(TextField).at(3), 'Password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign Up'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(fakeRepo.signUpCalls, 1);
    expect(find.text('Enter Verification Code'), findsOneWidget);
  });

  testWidgets('forgot password sends reset OTP and opens reset code step', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final fakeRepo = _FakeAuthRepository();

    await tester.pumpWidget(_buildTestApp(fakeRepo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'tester@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(fakeRepo.requestResetOtpCalls, 1);
    expect(find.text('Enter Reset Code'), findsOneWidget);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1080, 2200);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Widget _buildTestApp(_FakeAuthRepository fakeRepo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
    child: const MaterialApp(home: AuthGatePage()),
  );
}

class _FakeAuthRepository implements AuthRepository {
  int signUpCalls = 0;
  int requestResetOtpCalls = 0;

  @override
  Stream<TawakkalUser?> authStateChanges() =>
      const Stream<TawakkalUser?>.empty();

  @override
  Future<TawakkalUser> continueAsGuest() async => TawakkalUser.guest();

  @override
  Future<TawakkalUser?> currentUser() async => null;

  @override
  Future<void> requestPasswordResetOtp({required String email}) async {
    requestResetOtpCalls += 1;
  }

  @override
  Future<void> resendSignupOtp({required String email}) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    return true;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {}

  @override
  Future<void> verifySignupOtp({
    required String email,
    required String code,
  }) async {}
}
