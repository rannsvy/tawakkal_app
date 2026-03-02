import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_page.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_view.dart';

void main() {
  const messageKey = Key('universal-loading-message');
  const tipKey = Key('universal-loading-daily-tip');
  const rootKey = Key('universal-loading-root');

  const quizTask = 'Generating quiz and AI feedback...';
  const quizMessages = <String>[
    'Generating quiz and AI feedback...',
    'Building quiz questions from selected ayat...',
    'Preparing relevant AI feedback...',
    'Balancing question flow for better pacing...',
  ];
  const quizTips = <String>[
    'Read the full ayah context before choosing an answer.',
    'Use key terms from the ayah to narrow answer options.',
    'Prioritize answers that best match the ayah context.',
  ];

  const finalizeTask = 'Finalizing result and AI feedback...';
  const finalizeTips = <String>[
    'Review repeated mistakes to choose your next focus area.',
    'Revisit ayat you missed before moving to harder levels.',
    'Short, consistent review sessions build stronger retention.',
  ];

  Future<void> pumpLoading(
    WidgetTester tester, {
    String message = 'Preparing your daily path',
    ThemeMode themeMode = ThemeMode.dark,
    int? randomSeed,
    Widget? child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home:
            child ??
            UniversalLoadingView(message: message, randomSeed: randomSeed),
      ),
    );
    await tester.pump();
  }

  String textByKey(WidgetTester tester, Key key) {
    final textWidget = tester.widget<Text>(find.byKey(key));
    return textWidget.data ?? '';
  }

  testWidgets('removes Tawakkal and Quran Learning legacy headers', (
    tester,
  ) async {
    await pumpLoading(tester);

    expect(find.text('TAWAKKAL'), findsNothing);
    expect(find.text('QURAN LEARNING'), findsNothing);
  });

  testWidgets('shows current background task as first loading message', (
    tester,
  ) async {
    await pumpLoading(tester, message: quizTask);

    expect(find.byKey(messageKey), findsOneWidget);
    expect(textByKey(tester, messageKey), quizTask);
  });

  testWidgets('cycles through task-aware messages for quiz background task', (
    tester,
  ) async {
    await pumpLoading(tester, message: quizTask, randomSeed: 2);

    final initialMessage = textByKey(tester, messageKey);
    expect(quizMessages, contains(initialMessage));

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 350));

    final cycledMessage = textByKey(tester, messageKey);
    expect(quizMessages, contains(cycledMessage));
    expect(cycledMessage, isNot(equals(initialMessage)));
  });

  testWidgets('daily tip is randomized and belongs to the active task set', (
    tester,
  ) async {
    await pumpLoading(tester, message: quizTask, randomSeed: 2);
    final firstTip = textByKey(tester, tipKey);
    expect(quizTips, contains(firstTip));

    await pumpLoading(tester, message: quizTask, randomSeed: 11);
    final secondTip = textByKey(tester, tipKey);
    expect(quizTips, contains(secondTip));

    expect(secondTip, isNot(equals(firstTip)));
  });

  testWidgets('updates message and tip content when background task changes', (
    tester,
  ) async {
    await pumpLoading(tester, message: quizTask, randomSeed: 2);
    expect(textByKey(tester, messageKey), quizTask);
    final quizTip = textByKey(tester, tipKey);
    expect(quizTips, contains(quizTip));

    await pumpLoading(tester, message: finalizeTask, randomSeed: 2);
    expect(textByKey(tester, messageKey), finalizeTask);
    final finalizeTip = textByKey(tester, tipKey);
    expect(finalizeTips, contains(finalizeTip));
  });

  testWidgets('supports dark and light themes', (tester) async {
    await pumpLoading(tester, themeMode: ThemeMode.dark);
    expect(find.byType(UniversalLoadingView), findsOneWidget);

    await pumpLoading(tester, themeMode: ThemeMode.light);
    expect(find.byType(UniversalLoadingView), findsOneWidget);
  });

  testWidgets('fullscreen wrapper page renders loading view', (tester) async {
    await pumpLoading(tester, child: const UniversalLoadingPage(progress: 0.5));

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

    final rootSize = tester.getSize(find.byKey(rootKey));
    expect(rootSize.width, 430);
    expect(rootSize.height, 932);
  });
}
