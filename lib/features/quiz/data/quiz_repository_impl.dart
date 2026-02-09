import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/sqlite/app_database.dart';
import '../../learning/domain/entities/difficulty.dart';
import '../../quran/domain/entities/surah.dart';
import '../../quran/domain/repositories/quran_repository.dart';
import 'ai_prompt_builder.dart';
import '../domain/entities/quiz_models.dart';
import '../domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl({
    required AppDatabase database,
    required QuranRepository quranRepository,
    required Dio httpClient,
    required SupabaseClient? supabaseClient,
  }) : _database = database,
       _quranRepository = quranRepository,
       _httpClient = httpClient,
       _supabaseClient = supabaseClient;

  final AppDatabase _database;
  final QuranRepository _quranRepository;
  final Dio _httpClient;
  final SupabaseClient? _supabaseClient;

  @override
  Future<QuizPayload> getQuiz({
    required int surahId,
    required Difficulty difficulty,
    String language = AppConfig.defaultLanguage,
  }) async {
    final cached = await _database.getQuizCache(
      surahId: surahId,
      difficulty: difficulty.name,
      language: language,
    );

    if (cached != null) {
      final expiresAt = DateTime.tryParse(
        cached['expires_at'] as String? ?? '',
      );
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        final payload =
            jsonDecode(cached['payload_json'] as String? ?? '{}')
                as Map<String, dynamic>;
        return QuizPayload.fromJson(payload);
      }
    }

    final surah = await _quranRepository.getSurahDetail(surahId);

    QuizPayload generated;
    if (AppConfig.aiQuizEndpoint.isNotEmpty) {
      try {
        generated = await _fetchRemoteQuiz(
          surah: surah,
          difficulty: difficulty,
          language: language,
        );
      } catch (_) {
        generated = _buildFallbackQuiz(
          surah: surah,
          difficulty: difficulty,
          language: language,
        );
      }
    } else {
      generated = _buildFallbackQuiz(
        surah: surah,
        difficulty: difficulty,
        language: language,
      );
    }

    await _database.putQuizCache(
      quizId: generated.quizId,
      surahId: surahId,
      difficulty: difficulty.name,
      language: language,
      payload: generated.toJson(),
      expiresAt: DateTime.now().add(const Duration(days: 2)),
    );
    return generated;
  }

  Future<QuizPayload> _fetchRemoteQuiz({
    required SurahDetail surah,
    required Difficulty difficulty,
    required String language,
  }) async {
    final requestBody = <String, dynamic>{
      'surah_id': surah.summary.surahId,
      'surah_name': surah.summary.nameLatin,
      'difficulty': difficulty.name,
      'language': language,
      'model': AppConfig.openAiModel,
      'system_instruction': AiPromptBuilder.systemInstruction,
      'prompt': AiPromptBuilder.buildQuizPrompt(
        surah: surah,
        difficulty: difficulty,
        language: language,
      ),
      'grounding': <String, dynamic>{
        'ayahs': surah.ayahs
            .map(
              (ayah) => <String, dynamic>{
                'ayah_number': ayah.ayahNumber,
                'text_indonesian': ayah.textIndonesian,
                'text_latin': ayah.textLatin,
                'text_arabic': ayah.textArabic,
              },
            )
            .toList(),
        'tafsir': surah.tafsir
            .take(12)
            .map(
              (entry) => <String, dynamic>{
                'ayah_number': entry.ayahNumber,
                'text': entry.text,
                'source': entry.source,
              },
            )
            .toList(),
      },
    };

    final headers = <String, String>{'Content-Type': 'application/json'};
    final accessToken = _supabaseClient?.auth.currentSession?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await _httpClient.postUri(
      Uri.parse(AppConfig.aiQuizEndpoint),
      data: requestBody,
      options: Options(headers: headers),
    );

    final responseMap = _coerceToMap(response.data);
    final payloadMap = responseMap == null
        ? null
        : (_coerceToMap(responseMap['quiz']) ?? responseMap);
    if (payloadMap == null) {
      throw const AppException('Invalid quiz payload returned by AI endpoint.');
    }

    payloadMap['surah_id'] ??= surah.summary.surahId;
    payloadMap['surah_name'] ??= surah.summary.nameLatin;
    payloadMap['difficulty'] ??= difficulty.name;
    payloadMap['language'] ??= language;
    payloadMap['version'] ??= 1;

    final parsed = QuizPayload.fromJson(payloadMap);
    if (parsed.questions.isEmpty) {
      throw const AppException('AI endpoint returned an empty quiz.');
    }
    return parsed;
  }

  QuizPayload _buildFallbackQuiz({
    required SurahDetail surah,
    required Difficulty difficulty,
    required String language,
  }) {
    final questionCount = switch (difficulty) {
      Difficulty.easy => min(5, surah.ayahs.length),
      Difficulty.medium => min(7, surah.ayahs.length),
      Difficulty.hard => min(8, surah.ayahs.length),
    };

    final questions = <QuizQuestion>[];
    for (var i = 0; i < questionCount; i++) {
      final ayah = surah.ayahs[i];
      final distractors = surah.ayahs
          .where((item) => item.ayahNumber != ayah.ayahNumber)
          .take(3)
          .map((item) => item.textIndonesian)
          .toList();

      final options = <QuizOption>[
        QuizOption(id: 'a', text: ayah.textIndonesian),
        ...distractors.asMap().entries.map(
          (entry) => QuizOption(
            id: String.fromCharCode('b'.codeUnitAt(0) + entry.key),
            text: entry.value,
          ),
        ),
      ]..shuffle();

      final correctOptionId = options
          .firstWhere((option) => option.text == ayah.textIndonesian)
          .id;

      questions.add(
        QuizQuestion(
          id: 'q${i + 1}',
          type: QuizQuestionType.multipleChoice,
          prompt: _promptForDifficulty(
            difficulty: difficulty,
            surahName: surah.summary.nameLatin,
            ayahNumber: ayah.ayahNumber,
          ),
          ayahRefs: ['${surah.summary.surahId}:${ayah.ayahNumber}'],
          options: options,
          correctOptionId: correctOptionId,
          explanation: _explanationForDifficulty(
            difficulty: difficulty,
            ayahMeaning: ayah.textIndonesian,
          ),
          feedback: const QuizFeedback(
            correct:
                'Benar. Pemahaman ini membantu Anda membaca ayat dengan makna yang lebih dalam.',
            incorrect:
                'Belum tepat. Baca kembali ayat dan maknanya, lalu coba dengan tenang.',
          ),
          groundingRefs: [
            {
              'type': 'translation_id',
              'ref': 'EQURAN:${surah.summary.surahId}:${ayah.ayahNumber}',
            },
          ],
        ),
      );
    }

    return QuizPayload(
      quizId:
          'qz_s${surah.summary.surahId.toString().padLeft(3, '0')}_${difficulty.name}_${DateTime.now().millisecondsSinceEpoch}',
      surahId: surah.summary.surahId,
      surahName: surah.summary.nameLatin,
      difficulty: difficulty,
      language: language,
      version: 1,
      questions: questions,
      scoring: QuizScoring(
        xpPerCorrect: switch (difficulty) {
          Difficulty.easy => 8,
          Difficulty.medium => 12,
          Difficulty.hard => 16,
        },
        completionBonus: switch (difficulty) {
          Difficulty.easy => 20,
          Difficulty.medium => 30,
          Difficulty.hard => 40,
        },
      ),
    );
  }

  String _promptForDifficulty({
    required Difficulty difficulty,
    required String surahName,
    required int ayahNumber,
  }) {
    return switch (difficulty) {
      Difficulty.easy =>
        'Makna umum ayat $ayahNumber pada Surah $surahName adalah...',
      Difficulty.medium =>
        'Dalam konteks Surah $surahName, ayat $ayahNumber menekankan...',
      Difficulty.hard =>
        'Refleksi yang paling sesuai dengan ayat $ayahNumber pada Surah $surahName adalah...',
    };
  }

  String _explanationForDifficulty({
    required Difficulty difficulty,
    required String ayahMeaning,
  }) {
    return switch (difficulty) {
      Difficulty.easy => 'Ayat ini mengajarkan: $ayahMeaning',
      Difficulty.medium =>
        'Makna ayat dalam konteks surah ini: $ayahMeaning. Perhatikan hubungan antarayat.',
      Difficulty.hard =>
        'Ayat ini mengandung pelajaran mendalam: $ayahMeaning. Renungkan penerapannya dalam kehidupan.',
    };
  }

  Map<String, dynamic>? _coerceToMap(Object? source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    if (source is Map) {
      return source.map((key, value) => MapEntry(key.toString(), value));
    }
    if (source is String) {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return null;
  }
}
