import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_models.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_result_models.dart';
import 'package:tawakkal_app/features/quiz/domain/services/quiz_result_insight_builder.dart';

void main() {
  const builder = QuizResultInsightBuilder();

  QuizResultArgs buildArgs({
    required String language,
    required int score,
    required int maxScore,
    required List<AnsweredQuizItem> items,
  }) {
    return QuizResultArgs(
      quizId: 'quiz_1',
      surahId: 2,
      surahName: 'Al-Baqarah',
      difficultyKey: 'medium',
      language: language,
      score: score,
      maxScore: maxScore,
      xpEarned: 45,
      elapsedSeconds: 252,
      answeredItems: items,
    );
  }

  const wrongItem = AnsweredQuizItem(
    questionId: 'q1',
    type: QuizQuestionType.multipleChoice,
    prompt: 'Which meaning is best?',
    selectedOptionText: 'Wrong option',
    correctOptionText: 'Correct option',
    isCorrect: false,
    explanation: 'Review the ayah context and compare all options.',
    feedbackCorrect: 'Great.',
    feedbackIncorrect: 'Read the verse calmly and retry.',
    ayahRefs: ['2:15'],
  );

  const correctItem = AnsweredQuizItem(
    questionId: 'q2',
    type: QuizQuestionType.multipleChoice,
    prompt: 'Select the best answer.',
    selectedOptionText: 'Correct option',
    correctOptionText: 'Correct option',
    isCorrect: true,
    explanation: 'This option matches the translation.',
    feedbackCorrect: 'Great.',
    feedbackIncorrect: 'Retry.',
    ayahRefs: ['2:12'],
  );

  test('builds excellent insight for high score', () {
    final args = buildArgs(
      language: 'en',
      score: 9,
      maxScore: 10,
      items: List<AnsweredQuizItem>.filled(9, correctItem, growable: true)
        ..add(wrongItem),
    );

    final insight = builder.build(args);

    expect(insight.performanceLabel, 'Excellent!');
    expect(insight.strongUnderstandingTitle, 'Strong Understanding');
    expect(insight.focusAreaTitle, 'Focus Area');
    expect(insight.focusAreaBody, contains('2:15'));
  });

  test('builds low-score Indonesian insight bucket', () {
    final args = buildArgs(
      language: 'id',
      score: 2,
      maxScore: 5,
      items: const [wrongItem, wrongItem, wrongItem, correctItem, correctItem],
    );

    final insight = builder.build(args);

    expect(insight.performanceLabel, 'Terus Belajar');
    expect(insight.performanceMessage, contains('Tinjau kesalahan'));
    expect(insight.focusAreaBody, contains('Fokus pada ayat'));
  });

  test('uses no-mistake focus fallback', () {
    final args = buildArgs(
      language: 'en',
      score: 4,
      maxScore: 4,
      items: const [correctItem, correctItem, correctItem, correctItem],
    );

    final insight = builder.build(args);

    expect(insight.focusAreaBody, contains('No major gaps found'));
  });
}
