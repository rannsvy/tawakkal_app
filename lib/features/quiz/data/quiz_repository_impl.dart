import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/sqlite/app_database.dart';
import '../../learning/domain/entities/difficulty.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/domain/entities/surah.dart';
import '../../quran/domain/repositories/quran_repository.dart';
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
    final alwaysFresh = AppConfig.aiQuizAlwaysFresh;
    final userLocalId = _resolveUserLocalId();
    if (!alwaysFresh) {
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
          debugPrint(
            '[QuizRepository] Cache hit for surah=$surahId difficulty=${difficulty.name} language=$language; AI request skipped.',
          );
          final payload =
              jsonDecode(cached['payload_json'] as String? ?? '{}')
                  as Map<String, dynamic>;
          return QuizPayload.fromJson(payload);
        }
      }
    }

    final surah = await _quranRepository.getSurahDetail(surahId);
    final recentSignatures = await _database.getRecentQuizQuestionSignatures(
      userLocalId: userLocalId,
      surahId: surahId,
      difficulty: difficulty.name,
      language: language,
      limit: AppConfig.aiQuizRecentSignatureLimit,
    );
    final requestId =
        'rq_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 30)}';

    QuizPayload generated;
    if (AppConfig.aiQuizEndpoint.isNotEmpty) {
      try {
        debugPrint(
          '[QuizRepository] Requesting remote AI quiz from ${AppConfig.aiQuizEndpoint} using model=${AppConfig.aiModel}.',
        );
        generated = await _fetchRemoteQuiz(
          surah: surah,
          difficulty: difficulty,
          language: language,
          requestId: requestId,
          recentSignatures: recentSignatures,
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[QuizRepository] Remote AI quiz failed. Falling back to local quiz.\n$error\n$stackTrace',
        );
        generated = _buildFallbackQuiz(
          surah: surah,
          difficulty: difficulty,
          language: language,
        );
      }
    } else {
      debugPrint(
        '[QuizRepository] AI_QUIZ_ENDPOINT is empty. Using local fallback quiz.',
      );
      generated = _buildFallbackQuiz(
        surah: surah,
        difficulty: difficulty,
        language: language,
      );
    }

    if (!alwaysFresh) {
      await _database.putQuizCache(
        quizId: generated.quizId,
        surahId: surahId,
        difficulty: difficulty.name,
        language: language,
        payload: generated.toJson(),
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      );
    }
    await _storeQuestionHistory(
      userLocalId: userLocalId,
      surahId: surahId,
      difficulty: difficulty.name,
      language: language,
      quiz: generated,
    );
    return generated;
  }

  Future<QuizPayload> _fetchRemoteQuiz({
    required SurahDetail surah,
    required Difficulty difficulty,
    required String language,
    required String requestId,
    required List<String> recentSignatures,
  }) async {
    final requestedQuestionCount = switch (difficulty) {
      Difficulty.easy => 3,
      Difficulty.medium => 5,
      Difficulty.hard => 6,
    };
    final provider = AppConfig.aiProvider.trim();
    final requestBody = <String, dynamic>{
      if (provider.isNotEmpty) 'provider': provider,
      'surah_id': surah.summary.surahId,
      'surah_name': surah.summary.nameLatin,
      'difficulty': difficulty.name,
      'language': language,
      'model': AppConfig.aiModel,
      'question_count': requestedQuestionCount,
      'request_id': requestId,
      'recent_signatures': recentSignatures,
      'generation_mode': 'ai_first',
    };

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (AppConfig.supabaseAnonKey.isNotEmpty) {
      headers['apikey'] = AppConfig.supabaseAnonKey;
    }
    final accessToken = _supabaseClient?.auth.currentSession?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    } else if (AppConfig.supabaseAnonKey.isNotEmpty) {
      // Allows edge function invocation in guest mode when JWT verification is enabled.
      headers['Authorization'] = 'Bearer ${AppConfig.supabaseAnonKey}';
    }

    Response<dynamic> response;
    try {
      response = await _httpClient.postUri(
        Uri.parse(AppConfig.aiQuizEndpoint),
        data: requestBody,
        options: Options(
          headers: headers,
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
    } on DioException catch (error) {
      debugPrint(
        '[QuizRepository] AI endpoint status=${error.response?.statusCode} '
        'body=${_compactLog(error.response?.data)}',
      );
      rethrow;
    }

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
    final random = Random.secure();
    final questionCount = switch (difficulty) {
      Difficulty.easy => min(5, surah.ayahs.length),
      Difficulty.medium => min(7, surah.ayahs.length),
      Difficulty.hard => min(8, surah.ayahs.length),
    };
    final shuffledAyahs = [...surah.ayahs]..shuffle(random);
    final selectedAyahs = shuffledAyahs
        .take(questionCount)
        .toList(growable: false);

    final questions = <QuizQuestion>[];
    for (var i = 0; i < selectedAyahs.length; i++) {
      final ayah = selectedAyahs[i];
      final correctMeaning = _selectAyahMeaning(ayah, language);
      final distractorPool =
          surah.ayahs
              .where((item) => item.ayahNumber != ayah.ayahNumber)
              .map((item) => _selectAyahMeaning(item, language))
              .map((text) => text.trim())
              .where((text) => text.isNotEmpty && text != correctMeaning)
              .toSet()
              .toList()
            ..shuffle(random);

      final distractors = <String>[...distractorPool.take(3)];
      while (distractors.length < 3) {
        distractors.add(
          language.toLowerCase() == 'en'
              ? 'A meaning not supported by this ayah context.'
              : 'Makna yang tidak didukung oleh konteks ayat ini.',
        );
      }

      final options = <QuizOption>[
        QuizOption(id: 'a', text: correctMeaning),
        ...distractors.asMap().entries.map(
          (entry) => QuizOption(
            id: String.fromCharCode('b'.codeUnitAt(0) + entry.key),
            text: entry.value,
          ),
        ),
      ]..shuffle(random);

      final correctOptionId = options
          .firstWhere((option) => option.text == correctMeaning)
          .id;

      questions.add(
        QuizQuestion(
          id: 'q${i + 1}',
          type: QuizQuestionType.multipleChoice,
          prompt: _promptForDifficulty(
            difficulty: difficulty,
            surahName: surah.summary.nameLatin,
            ayahNumber: ayah.ayahNumber,
            language: language,
            random: random,
          ),
          ayahRefs: ['${surah.summary.surahId}:${ayah.ayahNumber}'],
          options: options,
          correctOptionId: correctOptionId,
          explanation: _explanationForDifficulty(
            difficulty: difficulty,
            ayahMeaning: correctMeaning,
            language: language,
          ),
          feedback: QuizFeedback(
            correct: language.toLowerCase() == 'en'
                ? 'Correct. Your choice aligns with the core message of this ayah.'
                : 'Benar. Pilihan Anda sejalan dengan pesan inti ayat ini.',
            incorrect: language.toLowerCase() == 'en'
                ? 'Not yet. Re-read the ayah meaning calmly and compare each option.'
                : 'Belum tepat. Baca ulang makna ayat dengan tenang dan bandingkan opsi.',
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

  String _selectAyahMeaning(Ayah ayah, String language) {
    if (language.toLowerCase() == 'en') {
      return (ayah.textEnglish?.trim().isNotEmpty ?? false)
          ? ayah.textEnglish!.trim()
          : ayah.textIndonesian.trim();
    }
    return ayah.textIndonesian.trim();
  }

  String _promptForDifficulty({
    required Difficulty difficulty,
    required String surahName,
    required int ayahNumber,
    required String language,
    required Random random,
  }) {
    final isEnglish = language.toLowerCase() == 'en';
    final pools = switch (difficulty) {
      Difficulty.easy =>
        isEnglish
            ? <String>[
                'Which meaning best matches ayah $ayahNumber in Surah $surahName?',
                'What is the clearest meaning of ayah $ayahNumber?',
                'Choose the statement that reflects ayah $ayahNumber most directly.',
                'Ayah $ayahNumber mainly teaches...',
              ]
            : <String>[
                'Makna yang paling sesuai untuk ayat $ayahNumber pada Surah $surahName adalah...',
                'Makna paling langsung dari ayat $ayahNumber adalah...',
                'Pernyataan yang paling mencerminkan ayat $ayahNumber adalah...',
                'Ayat $ayahNumber terutama mengajarkan...',
              ],
      Difficulty.medium =>
        isEnglish
            ? <String>[
                'In Surah $surahName, ayah $ayahNumber guides believers to apply this principle by...',
                'Which option best applies the meaning of ayah $ayahNumber in daily life?',
                'Ayah $ayahNumber can be understood in context as...',
                'Which interpretation best connects ayah $ayahNumber with practical behavior?',
              ]
            : <String>[
                'Dalam Surah $surahName, ayat $ayahNumber membimbing penerapan nilai melalui...',
                'Pilihan yang paling tepat untuk menerapkan makna ayat $ayahNumber dalam keseharian adalah...',
                'Dalam konteksnya, ayat $ayahNumber dapat dipahami sebagai...',
                'Penafsiran yang paling menghubungkan ayat $ayahNumber dengan perilaku nyata adalah...',
              ],
      Difficulty.hard =>
        isEnglish
            ? <String>[
                'Which reflection is most consistent with ayah $ayahNumber in Surah $surahName?',
                'Which evaluative conclusion is strongest based on ayah $ayahNumber?',
                'If ayah $ayahNumber is used as guidance, the best moral judgment is...',
                'What is the most defensible interpretation of ayah $ayahNumber for character development?',
              ]
            : <String>[
                'Refleksi yang paling konsisten dengan ayat $ayahNumber pada Surah $surahName adalah...',
                'Kesimpulan evaluatif yang paling kuat berdasarkan ayat $ayahNumber adalah...',
                'Jika ayat $ayahNumber dijadikan pedoman, penilaian akhlak yang paling tepat adalah...',
                'Interpretasi yang paling dapat dipertanggungjawabkan dari ayat $ayahNumber untuk pembinaan karakter adalah...',
              ],
    };
    return pools[random.nextInt(pools.length)];
  }

  String _explanationForDifficulty({
    required Difficulty difficulty,
    required String ayahMeaning,
    required String language,
  }) {
    final isEnglish = language.toLowerCase() == 'en';
    return switch (difficulty) {
      Difficulty.easy =>
        isEnglish
            ? 'This ayah directly means: $ayahMeaning'
            : 'Makna langsung ayat ini adalah: $ayahMeaning',
      Difficulty.medium =>
        isEnglish
            ? 'This ayah points to: $ayahMeaning. Apply it by observing the verse context.'
            : 'Ayat ini mengarahkan pada: $ayahMeaning. Terapkan dengan memperhatikan konteks ayat.',
      Difficulty.hard =>
        isEnglish
            ? 'This ayah teaches: $ayahMeaning. Reflect critically on how it shapes judgment and character.'
            : 'Ayat ini mengajarkan: $ayahMeaning. Renungkan secara kritis dampaknya pada penilaian dan karakter.',
    };
  }

  String _resolveUserLocalId() {
    final userId = _supabaseClient?.auth.currentUser?.id;
    if (userId != null && userId.trim().isNotEmpty) {
      return userId.trim();
    }
    return 'guest_local_user';
  }

  Future<void> _storeQuestionHistory({
    required String userLocalId,
    required int surahId,
    required String difficulty,
    required String language,
    required QuizPayload quiz,
  }) async {
    try {
      final signatures = quiz.questions
          .map(_buildQuestionSignature)
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
      final ayahRefs = quiz.questions
          .map(
            (question) =>
                question.ayahRefs.isNotEmpty ? question.ayahRefs.first : '',
          )
          .toList(growable: false);
      await _database.putQuizQuestionHistoryBatch(
        userLocalId: userLocalId,
        surahId: surahId,
        difficulty: difficulty,
        language: language,
        signatures: signatures,
        ayahRefs: ayahRefs,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[QuizRepository] Failed to store quiz question history. Proceeding without anti-repeat memory.\n$error\n$stackTrace',
      );
    }
  }

  String _buildQuestionSignature(QuizQuestion question) {
    final ref = question.ayahRefs.isNotEmpty
        ? question.ayahRefs.first.trim()
        : '-';
    final correctText = question.options
        .firstWhere(
          (option) => option.id.trim() == question.correctOptionId.trim(),
          orElse: () => question.options.isNotEmpty
              ? question.options.first
              : const QuizOption(id: '', text: ''),
        )
        .text;
    final normalizedPrompt = question.prompt
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final normalizedAnswer = correctText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final promptPart = _clipSignaturePart(normalizedPrompt, 120);
    final answerPart = _clipSignaturePart(normalizedAnswer, 60);
    return '$ref|$promptPart|$answerPart';
  }

  String _clipSignaturePart(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
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

  String _compactLog(Object? source) {
    if (source == null) {
      return 'null';
    }

    String text;
    if (source is String) {
      text = source;
    } else {
      try {
        text = jsonEncode(source);
      } catch (_) {
        text = source.toString();
      }
    }

    if (text.length <= 1200) {
      return text;
    }
    return '${text.substring(0, 1200)}...';
  }
}
