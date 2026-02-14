import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_page.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_view.dart';

void main() {
  Future<void> pumpLoading(
    WidgetTester tester, {
    String message = 'Preparing your daily path',
    double? progress,
    bool showPercentage = true,
    ThemeMode themeMode = ThemeMode.dark,
    Widget? child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home:
            child ??
            UniversalLoadingView(
              message: message,
              progress: progress,
              showPercentage: showPercentage,
            ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders default icon progress bar and message', (tester) async {
    await pumpLoading(tester);

    expect(find.byIcon(Icons.bedtime_rounded), findsOneWidget);
    expect(
      find.byKey(const Key('universal-loading-progress-track')),
      findsOneWidget,
    );
    expect(find.text('Preparing your daily path'), findsOneWidget);
  });

  testWidgets('loading bar is above message', (tester) async {
    await pumpLoading(tester);

    final barY = tester
        .getTopLeft(find.byKey(const Key('universal-loading-progress-track')))
        .dy;
    final messageY = tester
        .getTopLeft(find.byKey(const Key('universal-loading-message')))
        .dy;
    expect(barY, lessThan(messageY));
  });

  testWidgets('simulated mode uses determinate fill and percentage', (
    tester,
  ) async {
    await pumpLoading(tester, progress: null, showPercentage: true);

    expect(
      find.byKey(const Key('universal-loading-determinate-fill')),
      findsOneWidget,
    );
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('determinate mode shows progress fill and percentage', (
    tester,
  ) async {
    await pumpLoading(tester, progress: 0.84);

    expect(
      find.byKey(const Key('universal-loading-determinate-fill')),
      findsOneWidget,
    );
    final fill = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    expect(fill.widthFactor, closeTo(0.84, 0.0001));
    expect(find.text('84%'), findsOneWidget);
  });

  testWidgets('custom message override works', (tester) async {
    await pumpLoading(tester, message: 'Syncing lesson assets');

    expect(find.text('Syncing lesson assets'), findsOneWidget);
    expect(find.text('Preparing your daily path'), findsNothing);
  });

  testWidgets('supports dark and light themes', (tester) async {
    await pumpLoading(tester, themeMode: ThemeMode.dark);
    expect(find.byType(UniversalLoadingView), findsOneWidget);

    await pumpLoading(tester, themeMode: ThemeMode.light);
    expect(find.byType(UniversalLoadingView), findsOneWidget);
  });

  testWidgets('fullscreen wrapper page renders scaffold', (tester) async {
    await pumpLoading(tester, child: const UniversalLoadingPage(progress: 0.5));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(UniversalLoadingView), findsOneWidget);
  });

  testWidgets('loader root expands to full viewport', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await pumpLoading(tester);

    final rootSize = tester.getSize(
      find.byKey(const Key('universal-loading-root')),
    );
    expect(rootSize.width, 430);
    expect(rootSize.height, 932);
  });

  testWidgets('loading bar block width is capped at 320 on wide viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await pumpLoading(tester);

    final barBlockSize = tester.getSize(
      find.byKey(const Key('universal-loading-bar-block')),
    );
    expect(barBlockSize.width, lessThanOrEqualTo(320));
  });

  testWidgets(
    'loading bar block does not exceed available width on narrow viewport',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(260, 700);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await pumpLoading(tester);

      final barBlockSize = tester.getSize(
        find.byKey(const Key('universal-loading-bar-block')),
      );
      expect(barBlockSize.width, lessThanOrEqualTo(212));
    },
  );

  testWidgets('simulated progress increases monotonically', (tester) async {
    await pumpLoading(tester, progress: null, showPercentage: true);

    final firstFill = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    final firstProgress = firstFill.widthFactor!;

    await tester.pump(const Duration(seconds: 2));
    final secondFill = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    final secondProgress = secondFill.widthFactor!;

    await tester.pump(const Duration(seconds: 2));
    final thirdFill = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    final thirdProgress = thirdFill.widthFactor!;

    expect(secondProgress, greaterThanOrEqualTo(firstProgress));
    expect(thirdProgress, greaterThanOrEqualTo(secondProgress));
    expect(thirdProgress, lessThan(1));
  });

  testWidgets('simulated progress does not reset after long waits', (
    tester,
  ) async {
    await pumpLoading(tester, progress: null, showPercentage: true);

    await tester.pump(const Duration(seconds: 10));
    final progressAfterTenSeconds = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );

    await tester.pump(const Duration(seconds: 5));
    final progressAfterFifteenSeconds = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );

    expect(progressAfterTenSeconds.widthFactor, greaterThan(0.9));
    expect(
      progressAfterFifteenSeconds.widthFactor!,
      greaterThanOrEqualTo(progressAfterTenSeconds.widthFactor!),
    );
    expect(progressAfterFifteenSeconds.widthFactor, lessThan(0.99));
  });
}
