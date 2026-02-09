import '../../../learning/domain/entities/difficulty.dart';
import '../entities/quiz_models.dart';

abstract class QuizRepository {
  Future<QuizPayload> getQuiz({
    required int surahId,
    required Difficulty difficulty,
    String language = 'id',
  });
}
