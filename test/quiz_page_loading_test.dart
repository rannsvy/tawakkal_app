import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/learning/domain/entities/difficulty.dart';
import 'package:tawakkal_app/features/progress/presentation/providers/progress_providers.dart';
import 'package:tawakkal_app/features/quran/domain/entities/ayah.dart';
import 'package:tawakkal_app/features/quran/domain/entities/bookmark.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:tawakkal_app/features/quiz/domain/entities/quiz_models.dart';
import 'package:tawakkal_app/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:tawakkal_app/features/quiz/presentation/pages/quiz_page.dart';
import 'package:tawakkal_app/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:tawakkal_app/shared/widgets/universal_loading_view.dart';

void main() {
  void setLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
  }

  testWidgets('shows universal loading while quiz payload is loading', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final quizCompleter = Completer<QuizPayload>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(
            _FakeQuizRepository(future: quizCompleter.future),
          ),
          quranRepositoryProvider.overrideWithValue(_FakeQuranRepository()),
        ],
        child: const MaterialApp(
          home: QuizPage(surahId: 1, difficultyKey: 'easy'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('Generating quiz and AI feedback...'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
    final rootSize = tester.getSize(
      find.byKey(const Key('universal-loading-root')),
    );
    expect(rootSize.width, 390);
    expect(rootSize.height, 844);

    final firstProgress = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    await tester.pump(const Duration(seconds: 2));
    final secondProgress = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    expect(secondProgress.widthFactor, greaterThan(firstProgress.widthFactor!));

    final barBlockSize = tester.getSize(
      find.byKey(const Key('universal-loading-bar-block')),
    );
    expect(barBlockSize.width, lessThanOrEqualTo(320));
  });

  testWidgets('shows universal loading while completing quiz actions', (
    tester,
  ) async {
    setLargeViewport(tester);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final progressCompleter = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(
            _FakeQuizRepository(future: Future<QuizPayload>.value(_sampleQuiz)),
          ),
          quranRepositoryProvider.overrideWithValue(_FakeQuranRepository()),
          progressActionsProvider.overrideWith(
            (ref) => _FakeProgressActions(ref, completion: progressCompleter),
          ),
        ],
        child: const MaterialApp(
          home: QuizPage(surahId: 1, difficultyKey: 'easy'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Correct option'), findsOneWidget);

    await tester.tap(find.text('Correct option'));
    await tester.pump();

    await tester.tap(find.text('Check Answer'));
    await tester.pump(const Duration(milliseconds: 280));

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.byType(UniversalLoadingView), findsOneWidget);
    expect(find.text('Finalizing result and AI feedback...'), findsOneWidget);

    final beforeCompletion = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    expect(beforeCompletion.widthFactor, lessThan(1));

    progressCompleter.complete();
    await tester.pump();

    final completionFill = tester.widget<FractionallySizedBox>(
      find.byKey(const Key('universal-loading-determinate-fill')),
    );
    expect(completionFill.widthFactor, closeTo(1, 0.0001));

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(UniversalLoadingView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}

const QuizPayload _sampleQuiz = QuizPayload(
  quizId: 'quiz_test',
  surahId: 1,
  surahName: 'Al-Fatihah',
  difficulty: Difficulty.easy,
  language: 'en',
  version: 1,
  questions: [
    QuizQuestion(
      id: 'q1',
      type: QuizQuestionType.multipleChoice,
      prompt: 'Pick the best option.',
      ayahRefs: ['1:1'],
      options: [
        QuizOption(id: 'a', text: 'Correct option'),
        QuizOption(id: 'b', text: 'Wrong option'),
      ],
      correctOptionId: 'a',
      explanation: 'Explanation',
      feedback: QuizFeedback(
        correct: 'Great understanding.',
        incorrect: 'Review and try again.',
      ),
      groundingRefs: [],
    ),
  ],
  scoring: QuizScoring(xpPerCorrect: 10, completionBonus: 20),
);

class _FakeQuizRepository implements QuizRepository {
  const _FakeQuizRepository({required this.future});

  final Future<QuizPayload> future;

  @override
  Future<QuizPayload> getQuiz({
    required int surahId,
    required Difficulty difficulty,
    String language = 'id',
  }) {
    return future;
  }
}

class _FakeProgressActions extends ProgressActions {
  _FakeProgressActions(super.ref, {required this.completion});

  final Completer<void> completion;

  @override
  Future<void> recordQuizCompletion({
    required int surahId,
    required Difficulty difficulty,
    required int score,
    required int maxScore,
    required int xpEarned,
  }) {
    return completion.future;
  }
}

class _FakeQuranRepository implements QuranRepository {
  @override
  Future<SurahDetail> getSurahDetail(int surahId, {bool forceRefresh = false}) {
    return Future<SurahDetail>.value(
      const SurahDetail(
        summary: SurahSummary(
          surahId: 1,
          nameArabic: 'al-fatihah-ar',
          nameLatin: 'Al-Fatihah',
          ayahCount: 7,
          revelationPlace: 'meccan',
          meaning: 'The Opening',
          descriptionId: '',
          audioFull: {},
        ),
        ayahs: [
          Ayah(
            surahId: 1,
            ayahNumber: 1,
            textArabic: 'bismillah',
            textLatin: 'Bismillahirrahmanirrahim',
            textIndonesian: 'Dengan nama Allah Yang Maha Pengasih...',
            audioUrls: {},
          ),
        ],
        tafsir: [],
      ),
    );
  }

  @override
  Future<List<SurahSummary>> getSurahs({bool forceRefresh = false}) {
    return Future<List<SurahSummary>>.value(const [
      SurahSummary(
        surahId: 1,
        nameArabic: 'al-fatihah-ar',
        nameLatin: 'Al-Fatihah',
        ayahCount: 7,
        revelationPlace: 'meccan',
        meaning: 'The Opening',
        descriptionId: '',
        audioFull: {},
      ),
    ]);
  }

  @override
  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String note,
  }) {
    return Future<void>.value();
  }

  @override
  Future<void> toggleBookmark({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  }) {
    return Future<void>.value();
  }

  @override
  Future<bool> isBookmarked({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) {
    return Future<bool>.value(false);
  }

  @override
  Future<String?> getNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) {
    return Future<String?>.value(null);
  }

  @override
  Future<List<BookmarkedAyah>> getBookmarkedAyahs({
    required String userLocalId,
  }) {
    return Future<List<BookmarkedAyah>>.value(const <BookmarkedAyah>[]);
  }
}
