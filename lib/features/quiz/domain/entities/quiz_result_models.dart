import 'package:equatable/equatable.dart';

import 'quiz_models.dart';

class QuizResultArgs extends Equatable {
  const QuizResultArgs({
    required this.quizId,
    required this.surahId,
    required this.surahName,
    required this.difficultyKey,
    required this.language,
    required this.score,
    required this.maxScore,
    required this.xpEarned,
    required this.elapsedSeconds,
    required this.answeredItems,
  });

  final String quizId;
  final int surahId;
  final String surahName;
  final String difficultyKey;
  final String language;
  final int score;
  final int maxScore;
  final int xpEarned;
  final int elapsedSeconds;
  final List<AnsweredQuizItem> answeredItems;

  bool get isEnglish => language.toLowerCase() == 'en';

  double get accuracyRatio {
    if (maxScore <= 0) {
      return 0;
    }
    return score / maxScore;
  }

  int get accuracyPercent => (accuracyRatio * 100).round();

  List<AnsweredQuizItem> get incorrectItems =>
      answeredItems.where((item) => !item.isCorrect).toList(growable: false);

  @override
  List<Object?> get props => [
    quizId,
    surahId,
    surahName,
    difficultyKey,
    language,
    score,
    maxScore,
    xpEarned,
    elapsedSeconds,
    answeredItems,
  ];
}

class AnsweredQuizItem extends Equatable {
  const AnsweredQuizItem({
    required this.questionId,
    required this.type,
    required this.prompt,
    required this.selectedOptionText,
    this.fullSelectedOptionText,
    required this.correctOptionText,
    this.fullCorrectOptionText,
    required this.isCorrect,
    required this.explanation,
    this.fullExplanation,
    required this.feedbackCorrect,
    this.fullFeedbackCorrect,
    required this.feedbackIncorrect,
    this.fullFeedbackIncorrect,
    required this.ayahRefs,
  });

  final String questionId;
  final QuizQuestionType type;
  final String prompt;
  final String selectedOptionText;
  final String? fullSelectedOptionText;
  final String correctOptionText;
  final String? fullCorrectOptionText;
  final bool isCorrect;
  final String explanation;
  final String? fullExplanation;
  final String feedbackCorrect;
  final String? fullFeedbackCorrect;
  final String feedbackIncorrect;
  final String? fullFeedbackIncorrect;
  final List<String> ayahRefs;

  String get feedbackForResult =>
      isCorrect ? feedbackCorrect : feedbackIncorrect;

  String get fullFeedbackForResult => isCorrect
      ? (fullFeedbackCorrect?.trim().isNotEmpty == true
            ? fullFeedbackCorrect!
            : feedbackCorrect)
      : (fullFeedbackIncorrect?.trim().isNotEmpty == true
            ? fullFeedbackIncorrect!
            : feedbackIncorrect);

  String get fullExplanationText => fullExplanation?.trim().isNotEmpty == true
      ? fullExplanation!
      : explanation;

  String get fullCorrectAnswer =>
      fullCorrectOptionText?.trim().isNotEmpty == true
      ? fullCorrectOptionText!
      : correctOptionText;

  String get fullSelectedAnswer =>
      fullSelectedOptionText?.trim().isNotEmpty == true
      ? fullSelectedOptionText!
      : selectedOptionText;

  @override
  List<Object?> get props => [
    questionId,
    type,
    prompt,
    selectedOptionText,
    fullSelectedOptionText,
    correctOptionText,
    fullCorrectOptionText,
    isCorrect,
    explanation,
    fullExplanation,
    feedbackCorrect,
    fullFeedbackCorrect,
    feedbackIncorrect,
    fullFeedbackIncorrect,
    ayahRefs,
  ];
}
