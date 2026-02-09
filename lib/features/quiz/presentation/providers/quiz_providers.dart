import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/storage/sqlite/app_database.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../learning/domain/entities/difficulty.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/quiz_repository_impl.dart';
import '../../domain/entities/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';

final quizHttpClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final quranRepository = ref.watch(quranRepositoryProvider);
  final httpClient = ref.watch(quizHttpClientProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return QuizRepositoryImpl(
    database: database,
    quranRepository: quranRepository,
    httpClient: httpClient,
    supabaseClient: supabaseClient,
  );
});

final quizPayloadProvider = FutureProvider.family<QuizPayload, QuizRequest>((
  ref,
  request,
) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuiz(
    surahId: request.surahId,
    difficulty: request.difficulty,
    language: request.language,
  );
});

class QuizRequest {
  const QuizRequest({
    required this.surahId,
    required this.difficulty,
    this.language = 'id',
  });

  final int surahId;
  final Difficulty difficulty;
  final String language;

  @override
  bool operator ==(Object other) {
    return other is QuizRequest &&
        other.surahId == surahId &&
        other.difficulty == difficulty &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(surahId, difficulty, language);
}
