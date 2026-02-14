import 'package:equatable/equatable.dart';

class CompactedText extends Equatable {
  const CompactedText({
    required this.original,
    required this.compact,
    required this.isTruncated,
  });

  final String original;
  final String compact;
  final bool isTruncated;

  @override
  List<Object?> get props => [original, compact, isTruncated];
}

class QuizTextCompactor {
  static const int _feedbackMaxChars = 120;
  static const int _feedbackMaxSentences = 1;
  static const int _answerMaxChars = 90;
  static const int _answerMaxSentences = 1;
  static const int _focusAreaMaxSentences = 2;

  const QuizTextCompactor._();

  static CompactedText compactFeedback(
    String source, {
    required bool isEnglish,
  }) {
    return _compact(
      source,
      maxSentences: _feedbackMaxSentences,
      maxChars: _feedbackMaxChars,
      isEnglish: isEnglish,
    );
  }

  static CompactedText compactExplanation(
    String source, {
    required bool isEnglish,
  }) {
    final maxChars = isEnglish ? 180 : 170;
    return _compact(
      source,
      maxSentences: 2,
      maxChars: maxChars,
      isEnglish: isEnglish,
    );
  }

  static CompactedText compactAnswer(String source, {required bool isEnglish}) {
    return _compact(
      source,
      maxSentences: _answerMaxSentences,
      maxChars: _answerMaxChars,
      isEnglish: isEnglish,
    );
  }

  static CompactedText compactFocusArea(
    String source, {
    required bool isEnglish,
  }) {
    return _compact(
      source,
      maxSentences: _focusAreaMaxSentences,
      maxChars: isEnglish ? 132 : 124,
      isEnglish: isEnglish,
    );
  }

  static CompactedText _compact(
    String source, {
    required int maxSentences,
    required int maxChars,
    required bool isEnglish,
  }) {
    final normalized = _normalize(source);
    if (normalized.isEmpty) {
      return const CompactedText(original: '', compact: '', isTruncated: false);
    }

    var compact = _takeSentences(normalized, maxSentences);
    var isTruncated = compact.length < normalized.length;

    if (compact.length > maxChars) {
      compact = _clipToWordBoundary(compact, maxChars);
      isTruncated = true;
    }

    if (isTruncated) {
      compact = _withEllipsis(compact);
    }

    if (compact.isEmpty) {
      final fallbackLength = normalized.length > 24 ? 24 : normalized.length;
      compact = _withEllipsis(normalized.substring(0, fallbackLength));
      isTruncated = true;
    }

    // keep parameter used for future locale-specific limits and avoid dead params
    if (!isEnglish && compact.length > maxChars) {
      compact = _withEllipsis(_clipToWordBoundary(compact, maxChars));
      isTruncated = true;
    }

    return CompactedText(
      original: normalized,
      compact: compact,
      isTruncated: isTruncated,
    );
  }

  static String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _takeSentences(String source, int maxSentences) {
    final sentences = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      buffer.write(char);
      final isTerminal = char == '.' || char == '!' || char == '?';
      final nextIsSpace = i + 1 >= source.length || source[i + 1] == ' ';
      if (isTerminal && nextIsSpace) {
        final candidate = buffer.toString().trim();
        if (candidate.isNotEmpty) {
          sentences.add(candidate);
        }
        buffer.clear();
      }
    }

    final remainder = buffer.toString().trim();
    if (remainder.isNotEmpty) {
      sentences.add(remainder);
    }
    if (sentences.isEmpty) {
      return source;
    }

    return sentences.take(maxSentences).join(' ').trim();
  }

  static String _clipToWordBoundary(String source, int maxChars) {
    if (source.length <= maxChars) {
      return source;
    }
    final clipped = source.substring(0, maxChars).trimRight();
    final pivot = (maxChars * 0.65).floor();
    final lastSpace = clipped.lastIndexOf(' ');
    if (lastSpace > pivot) {
      return clipped.substring(0, lastSpace).trimRight();
    }
    return clipped;
  }

  static String _withEllipsis(String source) {
    final cleaned = source.replaceAll(RegExp(r'[\s.!?]+$'), '').trimRight();
    if (cleaned.isEmpty) {
      return '...';
    }
    return '$cleaned...';
  }
}
