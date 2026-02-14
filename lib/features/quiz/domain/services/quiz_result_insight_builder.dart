import 'package:equatable/equatable.dart';

import '../entities/quiz_result_models.dart';

class QuizResultInsight extends Equatable {
  const QuizResultInsight({
    required this.performanceLabel,
    required this.performanceMessage,
    required this.strongUnderstandingTitle,
    required this.strongUnderstandingBody,
    required this.focusAreaTitle,
    required this.focusAreaBody,
  });

  final String performanceLabel;
  final String performanceMessage;
  final String strongUnderstandingTitle;
  final String strongUnderstandingBody;
  final String focusAreaTitle;
  final String focusAreaBody;

  @override
  List<Object?> get props => [
    performanceLabel,
    performanceMessage,
    strongUnderstandingTitle,
    strongUnderstandingBody,
    focusAreaTitle,
    focusAreaBody,
  ];
}

class QuizResultInsightBuilder {
  const QuizResultInsightBuilder();

  QuizResultInsight build(QuizResultArgs args) {
    final isEnglish = args.isEnglish;
    final correctItems = args.answeredItems
        .where((item) => item.isCorrect)
        .toList(growable: false);
    final incorrectItems = args.incorrectItems;
    final percent = args.accuracyPercent;

    final performanceLabel = _buildPerformanceLabel(
      percent: percent,
      isEnglish: isEnglish,
    );
    final performanceMessage = _buildPerformanceMessage(
      percent: percent,
      isEnglish: isEnglish,
    );

    final strongTitle = isEnglish ? 'Strong Understanding' : 'Pemahaman Kuat';
    final focusTitle = isEnglish ? 'Focus Area' : 'Area Fokus';

    final strongBody = _buildStrongUnderstandingBody(
      correctItems: correctItems,
      isEnglish: isEnglish,
    );
    final focusBody = _buildFocusAreaBody(
      incorrectItems: incorrectItems,
      isEnglish: isEnglish,
    );

    return QuizResultInsight(
      performanceLabel: performanceLabel,
      performanceMessage: performanceMessage,
      strongUnderstandingTitle: strongTitle,
      strongUnderstandingBody: strongBody,
      focusAreaTitle: focusTitle,
      focusAreaBody: focusBody,
    );
  }

  String _buildPerformanceLabel({
    required int percent,
    required bool isEnglish,
  }) {
    if (percent >= 85) {
      return isEnglish ? 'Excellent!' : 'Excellent!';
    }
    if (percent >= 65) {
      return isEnglish ? 'Good Progress' : 'Progress Bagus';
    }
    return isEnglish ? 'Keep Learning' : 'Terus Belajar';
  }

  String _buildPerformanceMessage({
    required int percent,
    required bool isEnglish,
  }) {
    if (percent >= 85) {
      return isEnglish
          ? 'Your understanding is consistent and strong.'
          : 'Pemahaman Anda konsisten dan kuat.';
    }
    if (percent >= 65) {
      return isEnglish
          ? 'You are on track, keep refining weak points.'
          : 'Anda sudah di jalur tepat, tinggal menguatkan bagian lemah.';
    }
    return isEnglish
        ? 'Review your mistakes calmly, then try again.'
        : 'Tinjau kesalahan dengan tenang, lalu coba lagi.';
  }

  String _buildStrongUnderstandingBody({
    required List<AnsweredQuizItem> correctItems,
    required bool isEnglish,
  }) {
    if (correctItems.isEmpty) {
      return isEnglish
          ? 'You completed the quiz with good effort. Keep practicing to build stronger understanding.'
          : 'Anda menyelesaikan kuis dengan usaha yang baik. Terus berlatih agar pemahaman semakin kuat.';
    }

    final sample = correctItems.first;
    final ref = _firstReference(sample.ayahRefs);
    if (ref != null) {
      return isEnglish
          ? 'You showed solid understanding on ayah $ref. Keep this consistency in your next sessions.'
          : 'Anda menunjukkan pemahaman yang baik pada ayat $ref. Pertahankan konsistensi ini di sesi berikutnya.';
    }

    final cue = _clip(sample.prompt, maxLength: 110);
    return isEnglish
        ? 'You consistently answered correctly in key items, especially around "$cue".'
        : 'Anda konsisten menjawab benar pada beberapa soal penting, terutama di topik "$cue".';
  }

  String _buildFocusAreaBody({
    required List<AnsweredQuizItem> incorrectItems,
    required bool isEnglish,
  }) {
    if (incorrectItems.isEmpty) {
      return isEnglish
          ? 'No major gaps found. Move to a higher difficulty and maintain regular review.'
          : 'Tidak terlihat celah besar. Anda bisa naik tingkat kesulitan sambil menjaga murajaah rutin.';
    }

    final weakest = incorrectItems.first;
    final ref = _firstReference(weakest.ayahRefs);
    final explanation = _clip(
      weakest.explanation.isNotEmpty
          ? weakest.explanation
          : weakest.feedbackIncorrect,
      maxLength: 140,
    );

    if (ref != null) {
      return isEnglish
          ? 'Focus on ayah $ref. Review this concept: $explanation'
          : 'Fokus pada ayat $ref. Ulangi konsep ini: $explanation';
    }

    return isEnglish
        ? 'Focus on your incorrect items and revisit this concept: $explanation'
        : 'Fokus pada soal yang masih salah dan ulangi konsep ini: $explanation';
  }

  String? _firstReference(List<String> refs) {
    for (final ref in refs) {
      final trimmed = ref.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String _clip(String source, {required int maxLength}) {
    final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '-';
    }
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 3)}...';
  }
}
