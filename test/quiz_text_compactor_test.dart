import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/quiz/domain/services/quiz_text_compactor.dart';

void main() {
  test('compactFeedback truncates long feedback to one sentence', () {
    const input =
        'This is the first sentence with detailed guidance. This is the second sentence that should not be visible in compact mode.';
    final result = QuizTextCompactor.compactFeedback(input, isEnglish: true);

    expect(result.isTruncated, isTrue);
    expect(result.compact, isNot(contains('second sentence')));
    expect(result.compact.endsWith('...'), isTrue);
  });

  test('compactExplanation keeps up to two short sentences', () {
    const input =
        'Sentence one explains context. Sentence two gives practice advice. Sentence three should be removed.';
    final result = QuizTextCompactor.compactExplanation(input, isEnglish: true);

    expect(result.isTruncated, isTrue);
    expect(result.compact, contains('Sentence one explains context'));
    expect(result.compact, contains('Sentence two gives practice advice'));
    expect(result.compact, isNot(contains('Sentence three')));
  });

  test('compactAnswer keeps short text unchanged', () {
    const input = 'Short answer text';
    final result = QuizTextCompactor.compactAnswer(input, isEnglish: false);

    expect(result.isTruncated, isFalse);
    expect(result.compact, input);
    expect(result.original, input);
  });

  test('compactor normalizes whitespace', () {
    const input = '  Line  one.\n\nLine   two.  ';
    final result = QuizTextCompactor.compactExplanation(input, isEnglish: true);

    expect(result.original, 'Line one. Line two.');
  });
}
