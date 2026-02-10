import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tawakkal_app/app/app.dart';
import 'package:tawakkal_app/features/onboarding/data/onboarding_local_store.dart';

void main() {
  testWidgets('first run shows onboarding then opens auth gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const ProviderScope(child: TawakkalApp()));
    await tester.pump();

    expect(find.text('Loading your journey...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Master Your Faith'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Mulai sebagai Guest'), findsOneWidget);
  });

  testWidgets('returning user skips launch flow and sees auth gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      OnboardingLocalStore.completionKey: true,
    });

    await tester.pumpWidget(const ProviderScope(child: TawakkalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mulai sebagai Guest'), findsOneWidget);
  });
}
