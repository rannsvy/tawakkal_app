import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tawakkal_app/app/app.dart';
import 'package:tawakkal_app/features/onboarding/data/onboarding_content.dart';
import 'package:tawakkal_app/features/onboarding/data/onboarding_local_store.dart';

Future<void> _pumpToOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TawakkalApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3000));
  await tester.pump(const Duration(milliseconds: 500));
}

List<TextSpan> _wordmarkSpans(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.byKey(const ValueKey('onboarding-brand-wordmark')),
  );
  final span = richText.text as TextSpan;
  return span.children!.cast<TextSpan>();
}

void main() {
  testWidgets('first run shows redesigned onboarding', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await _pumpToOnboarding(tester);

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-brand-wordmark')),
      findsOneWidget,
    );
  });

  test('onboarding content uses two SVG slides', () {
    expect(onboardingSlides.length, 2);
    expect(
      onboardingSlides[0].illustrationAsset,
      'assets/icons/studying_ob_page_1.svg',
    );
    expect(
      onboardingSlides[1].illustrationAsset,
      'assets/icons/brain_ob_page_2.svg',
    );
  });

  testWidgets('onboarding wordmark uses dark-theme color mapping', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await _pumpToOnboarding(tester);

    final spans = _wordmarkSpans(tester);
    expect(spans.length, 3);
    expect(spans[0].text, 'Ta');
    expect(spans[1].text, 'wak');
    expect(spans[2].text, 'kal');
    expect(spans[0].style?.color, const Color(0xFFF2AE8F));
    expect(spans[1].style?.color, Colors.white);
    expect(spans[2].style?.color, const Color(0xFFF2AE8F));
  });

  testWidgets('onboarding wordmark uses light-theme dark green text', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await _pumpToOnboarding(tester);

    final spans = _wordmarkSpans(tester);
    expect(spans.length, 3);
    expect(spans[0].style?.color, const Color(0xFF1F5F44));
    expect(spans[1].style?.color, const Color(0xFF1F5F44));
    expect(spans[2].style?.color, const Color(0xFF1F5F44));
  });

  testWidgets('returning user skips launch flow and sees auth gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      OnboardingLocalStore.completionKey: true,
    });

    await tester.pumpWidget(const ProviderScope(child: TawakkalApp()));
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('Team Up For Success'), findsNothing);
  });
}
