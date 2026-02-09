import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_models.dart';

void main() {
  test('Quiz payload parses from json', () {
    final payload = QuizPayload.fromJson(<String, dynamic>{
      'quiz_id': 'qz_1',
      'surah_id': 1,
      'surah_name': 'Al-Fatihah',
      'difficulty': 'easy',
      'language': 'id',
      'version': 1,
      'questions': [
        {
          'id': 'q1',
          'type': 'multipleChoice',
          'prompt': 'Test?',
          'ayah_refs': ['1:1'],
          'choices': [
            {'id': 'a', 'text': 'A'},
            {'id': 'b', 'text': 'B'},
          ],
          'correct_choice_id': 'a',
          'explanation': 'Exp',
          'feedback': {'correct': 'ok', 'incorrect': 'no'},
          'grounding_refs': [
            {'type': 'translation', 'ref': 'EQURAN:1:1'},
          ],
        },
      ],
      'scoring': {'xp_per_correct': 10, 'completion_bonus': 20},
    });

    expect(payload.quizId, 'qz_1');
    expect(payload.questions.length, 1);
    expect(payload.questions.first.correctOptionId, 'a');
  });
}
