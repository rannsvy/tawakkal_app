import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/app/theme/colors.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_models.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_result_models.dart';
import 'package:tawakkal_app/features/quiz/presentation/pages/quiz_result_page.dart';

void main() {
  QuizResultArgs buildArgs({int mistakeCount = 1}) {
    final firstIsCorrect = mistakeCount == 0;
    final secondIsCorrect = mistakeCount <= 1;

    final answeredItems = [
      AnsweredQuizItem(
        questionId: 'q1',
        type: QuizQuestionType.multipleChoice,
        prompt: 'What is the best meaning?',
        selectedOptionText:
            'Wrong choice with very long wording that should be compacted in the row view for better readability',
        correctOptionText:
            'Right choice with very long wording that should be compacted in the row view for better readability',
        isCorrect: firstIsCorrect,
        explanation:
            'This option aligns with the ayah context and explains why the selected answer is inaccurate. Review the translation carefully and compare each phrase with the prompt wording. Then retry with calmer pacing.',
        feedbackCorrect: 'Strong understanding.',
        feedbackIncorrect:
            'Review the translation and context carefully before selecting the answer. Focus on key wording and compare each option patiently.',
        fullSelectedOptionText:
            'Wrong choice with very long wording that should be compacted in the row view for better readability',
        fullCorrectOptionText:
            'Right choice with very long wording that should be compacted in the row view for better readability',
        fullExplanation:
            'This option aligns with the ayah context and explains why the selected answer is inaccurate. Review the translation carefully and compare each phrase with the prompt wording. Then retry with calmer pacing.',
        fullFeedbackIncorrect:
            'Review the translation and context carefully before selecting the answer. Focus on key wording and compare each option patiently.',
        ayahRefs: ['2:15'],
      ),
      AnsweredQuizItem(
        questionId: 'q2',
        type: QuizQuestionType.multipleChoice,
        prompt: 'Which phrase completes this verse?',
        selectedOptionText: secondIsCorrect ? 'Correct phrase' : 'Wrong phrase',
        correctOptionText: 'Correct phrase',
        isCorrect: secondIsCorrect,
        explanation:
            'This item checks your understanding of context and vocabulary in the verse.',
        feedbackCorrect: 'Good progress.',
        feedbackIncorrect:
            'Review the keyword mapping and compare each option before choosing.',
        ayahRefs: ['2:16'],
      ),
    ];

    final score = answeredItems.where((item) => item.isCorrect).length;

    return QuizResultArgs(
      quizId: 'quiz_1',
      surahId: 2,
      surahName: 'Al-Baqarah',
      difficultyKey: 'medium',
      language: 'en',
      score: score,
      maxScore: answeredItems.length,
      xpEarned: 42,
      elapsedSeconds: 252,
      answeredItems: answeredItems,
    );
  }

  Future<void> pumpResultPage(
    WidgetTester tester, {
    required QuizResultArgs args,
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onBack,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: QuizResultPage(
          args: args,
          onBackToPathTap: onBack ?? () {},
          onCloseTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void setLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
  }

  testWidgets('renders result and opens paged review sheet', (tester) async {
    setLargeViewport(tester);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await pumpResultPage(tester, args: buildArgs(mistakeCount: 1));

    expect(find.text('AI Learning Insights'), findsOneWidget);
    expect(find.text('Focus Area'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Read more'), findsOneWidget);
    expect(find.text('Review Mistakes'), findsOneWidget);
    expect(find.text('Back to Path'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Read more'));
    await tester.pumpAndSettle();

    expect(find.text('Full text view'), findsOneWidget);
    expect(
      find.textContaining('explains why the selected answer is inaccurate'),
      findsAtLeastNWidgets(1),
    );

    Navigator.of(tester.element(find.byType(QuizResultPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 1 Mistakes'), findsOneWidget);
    expect(find.text('All Mistakes'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Correct answer'), findsOneWidget);
    expect(find.text('What is the best meaning?'), findsOneWidget);
    expect(find.text('Read more'), findsAtLeastNWidgets(1));
  });

  testWidgets('next mistake advances pager and finish closes sheet', (
    tester,
  ) async {
    await pumpResultPage(tester, args: buildArgs(mistakeCount: 2));

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 Mistakes'), findsOneWidget);
    expect(find.text('Next Mistake'), findsOneWidget);
    expect(find.text('What is the best meaning?'), findsOneWidget);

    await tester.tap(find.text('Next Mistake'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 Mistakes'), findsOneWidget);
    expect(find.text('Which phrase completes this verse?'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 Mistakes'), findsNothing);
    expect(find.text('Review Mistakes'), findsOneWidget);
  });

  testWidgets('all mistakes index sheet jumps to selected item', (
    tester,
  ) async {
    await pumpResultPage(tester, args: buildArgs(mistakeCount: 2));

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Mistakes'));
    await tester.pumpAndSettle();

    expect(find.text('All Mistakes'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 Mistakes'), findsOneWidget);
    expect(find.text('Which phrase completes this verse?'), findsOneWidget);
  });

  testWidgets('help action opens and closes study tip sheet', (tester) async {
    await pumpResultPage(tester, args: buildArgs(mistakeCount: 1));

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Study Tip'), findsOneWidget);
    expect(find.text('What to review'), findsOneWidget);
    expect(
      find.textContaining('Review the translation and context carefully'),
      findsAtLeastNWidgets(1),
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Study Tip'), findsNothing);
  });

  testWidgets('no-mistake state hides bottom review navbar', (tester) async {
    await pumpResultPage(tester, args: buildArgs(mistakeCount: 0));

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    expect(find.text('No mistakes in this session.'), findsOneWidget);
    expect(find.text('All Mistakes'), findsNothing);
    expect(find.text('Help'), findsNothing);
    expect(find.text('Next Mistake'), findsNothing);
    expect(find.text('Finish'), findsNothing);
  });

  testWidgets('back button calls callback', (tester) async {
    var called = false;

    await pumpResultPage(
      tester,
      args: buildArgs(mistakeCount: 1),
      onBack: () {
        called = true;
      },
    );

    await tester.tap(find.text('Back to Path'));
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('question prompt text uses white tone in dark mode', (
    tester,
  ) async {
    await pumpResultPage(
      tester,
      args: buildArgs(mistakeCount: 1),
      themeMode: ThemeMode.dark,
    );

    await tester.tap(find.text('Review Mistakes'));
    await tester.pumpAndSettle();

    final promptText = tester.widget<Text>(
      find.text('What is the best meaning?'),
    );
    expect(promptText.style?.color, TawakkalColors.textPrimaryDark);
  });
}
