import 'package:equatable/equatable.dart';

import '../../../learning/domain/entities/difficulty.dart';

enum QuizQuestionType {
  multipleChoice,
  matching,
  ordering,
  reflection;

  static QuizQuestionType fromKey(String key) {
    return QuizQuestionType.values.firstWhere(
      (value) => value.name == key,
      orElse: () => QuizQuestionType.multipleChoice,
    );
  }
}

class QuizOption extends Equatable {
  const QuizOption({required this.id, required this.text});

  final String id;
  final String text;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'text': text};
  }

  @override
  List<Object?> get props => [id, text];
}

class QuizFeedback extends Equatable {
  const QuizFeedback({required this.correct, required this.incorrect});

  final String correct;
  final String incorrect;

  factory QuizFeedback.fromJson(Map<String, dynamic> json) {
    return QuizFeedback(
      correct: json['correct'] as String? ?? '',
      incorrect: json['incorrect'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'correct': correct, 'incorrect': incorrect};
  }

  @override
  List<Object?> get props => [correct, incorrect];
}

class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.ayahRefs,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
    required this.feedback,
    required this.groundingRefs,
  });

  final String id;
  final QuizQuestionType type;
  final String prompt;
  final List<String> ayahRefs;
  final List<QuizOption> options;
  final String correctOptionId;
  final String explanation;
  final QuizFeedback feedback;
  final List<Map<String, String>> groundingRefs;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions =
        json['choices'] as List<dynamic>? ??
        json['options'] as List<dynamic>? ??
        const [];
    final rawGrounding = json['grounding_refs'] as List<dynamic>? ?? const [];

    return QuizQuestion(
      id: json['id'] as String? ?? '',
      type: QuizQuestionType.fromKey(
        json['type'] as String? ?? QuizQuestionType.multipleChoice.name,
      ),
      prompt: json['prompt'] as String? ?? '',
      ayahRefs: (json['ayah_refs'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toList(),
      options: rawOptions
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (option) => QuizOption.fromJson(
              option.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      correctOptionId:
          json['correct_choice_id'] as String? ??
          json['correct_option_id'] as String? ??
          '',
      explanation: json['explanation'] as String? ?? '',
      feedback: QuizFeedback.fromJson(
        (json['feedback'] as Map<String, dynamic>?) ?? const {},
      ),
      groundingRefs: rawGrounding
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                item.map((key, value) => MapEntry(key.toString(), '$value')),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'prompt': prompt,
      'ayah_refs': ayahRefs,
      'choices': options.map((option) => option.toJson()).toList(),
      'correct_choice_id': correctOptionId,
      'explanation': explanation,
      'feedback': feedback.toJson(),
      'grounding_refs': groundingRefs,
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    prompt,
    ayahRefs,
    options,
    correctOptionId,
    explanation,
    feedback,
    groundingRefs,
  ];
}

class QuizScoring extends Equatable {
  const QuizScoring({
    required this.xpPerCorrect,
    required this.completionBonus,
  });

  final int xpPerCorrect;
  final int completionBonus;

  factory QuizScoring.fromJson(Map<String, dynamic> json) {
    return QuizScoring(
      xpPerCorrect: json['xp_per_correct'] as int? ?? 10,
      completionBonus: json['completion_bonus'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xp_per_correct': xpPerCorrect,
      'completion_bonus': completionBonus,
    };
  }

  @override
  List<Object?> get props => [xpPerCorrect, completionBonus];
}

class QuizPayload extends Equatable {
  const QuizPayload({
    required this.quizId,
    required this.surahId,
    required this.surahName,
    required this.difficulty,
    required this.language,
    required this.version,
    required this.questions,
    required this.scoring,
  });

  final String quizId;
  final int surahId;
  final String surahName;
  final Difficulty difficulty;
  final String language;
  final int version;
  final List<QuizQuestion> questions;
  final QuizScoring scoring;

  factory QuizPayload.fromJson(Map<String, dynamic> json) {
    return QuizPayload(
      quizId: json['quiz_id'] as String? ?? '',
      surahId: json['surah_id'] as int? ?? 0,
      surahName: json['surah_name'] as String? ?? '',
      difficulty: Difficulty.fromKey(json['difficulty'] as String? ?? 'easy'),
      language: json['language'] as String? ?? 'id',
      version: json['version'] as int? ?? 1,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => QuizQuestion.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      scoring: QuizScoring.fromJson(
        (json['scoring'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quiz_id': quizId,
      'surah_id': surahId,
      'surah_name': surahName,
      'difficulty': difficulty.name,
      'language': language,
      'version': version,
      'questions': questions.map((question) => question.toJson()).toList(),
      'scoring': scoring.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    quizId,
    surahId,
    surahName,
    difficulty,
    language,
    version,
    questions,
    scoring,
  ];
}
