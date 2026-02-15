import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tawakkal_app/features/learning/presentation/pages/learning_page.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';

void main() {
  Future<void> pumpLearningPage(
    WidgetTester tester, {
    GoRouter? router,
    List<SurahSummary> surahs = _sampleSurahs,
    double bottomOverlayOverlap = 0,
  }) async {
    final app = router == null
        ? MaterialApp(
            home: Scaffold(
              body: LearningPage(bottomOverlayOverlap: bottomOverlayOverlap),
            ),
          )
        : MaterialApp.router(routerConfig: router);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [surahListProvider.overrideWith((ref) async => surahs)],
        child: app,
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('removes Tahapan Pembelajaran and shows search input', (
    tester,
  ) async {
    await pumpLearningPage(tester);

    expect(find.text('Tahapan Pembelajaran'), findsNothing);
    expect(find.text('Pilih Surah untuk Mulai Kuis'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Cari surah (nama, arti, Arab, nomor)...'),
      findsOneWidget,
    );
  });

  testWidgets('shows 10 surahs by default with expand toggle', (tester) async {
    await pumpLearningPage(tester);

    expect(find.text('Mulai'), findsNWidgets(10));
    expect(find.text('Tampilkan semua surah'), findsOneWidget);
    expect(find.text('Yunus'), findsOneWidget);
    expect(find.text('Hud'), findsNothing);
  });

  testWidgets('expands to all surahs then collapses back to 10', (
    tester,
  ) async {
    await pumpLearningPage(tester);

    final expandButton = find.widgetWithText(
      TextButton,
      'Tampilkan semua surah',
    );
    final expandWidget = tester.widget<TextButton>(expandButton);
    expandWidget.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Mulai'), findsNWidgets(12));
    expect(find.text('Hud'), findsOneWidget);
    expect(find.text('Tampilkan lebih sedikit'), findsOneWidget);

    final collapseButton = find.widgetWithText(
      TextButton,
      'Tampilkan lebih sedikit',
    );
    final collapseWidget = tester.widget<TextButton>(collapseButton);
    collapseWidget.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Mulai'), findsNWidgets(10));
    expect(find.text('Hud'), findsNothing);
  });

  testWidgets('search auto-shows all matches and supports partial query', (
    tester,
  ) async {
    await pumpLearningPage(tester);

    await tester.enterText(find.byType(TextField), 'tema');
    await tester.pumpAndSettle();

    expect(find.text('Mulai'), findsNWidgets(12));
    expect(find.text('Tampilkan semua surah'), findsNothing);

    await tester.enterText(find.byType(TextField), 'fatih');
    await tester.pumpAndSettle();

    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsNothing);
  });

  testWidgets('shows empty state when search has no result', (tester) async {
    await pumpLearningPage(tester);

    await tester.enterText(find.byType(TextField), 'zzzz-no-match');
    await tester.pumpAndSettle();

    expect(find.text('Hasil tidak ditemukan'), findsOneWidget);
  });

  testWidgets('uses fallback bottom padding when overlap is zero', (
    tester,
  ) async {
    await pumpLearningPage(tester);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding as EdgeInsets;

    expect(padding.bottom, 16);
  });

  testWidgets('uses overlap plus 8dp for bottom padding', (tester) async {
    await pumpLearningPage(tester, bottomOverlayOverlap: 80);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding as EdgeInsets;

    expect(padding.bottom, 88);
  });

  testWidgets('starts quiz with selected difficulty in query params', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: LearningPage()),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) {
            final surahId = state.uri.queryParameters['surahId'] ?? '';
            final difficulty = state.uri.queryParameters['difficulty'] ?? '';
            return Scaffold(body: Text('quiz:$surahId:$difficulty'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await pumpLearningPage(tester, router: router);

    await tester.tap(find.text('Sulit'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Mulai').first);
    await tester.pumpAndSettle();

    expect(find.text('quiz:1:hard'), findsOneWidget);
  });
}

const List<SurahSummary> _sampleSurahs = [
  SurahSummary(
    surahId: 1,
    nameArabic: 'al-fatihah-ar',
    nameLatin: 'Al-Fatihah',
    ayahCount: 7,
    revelationPlace: 'Makkah',
    meaning: 'Tema 1',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 2,
    nameArabic: 'al-baqarah-ar',
    nameLatin: 'Al-Baqarah',
    ayahCount: 286,
    revelationPlace: 'Madinah',
    meaning: 'Tema 2',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 3,
    nameArabic: 'ali-imran-ar',
    nameLatin: 'Ali Imran',
    ayahCount: 200,
    revelationPlace: 'Madinah',
    meaning: 'Tema 3',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 4,
    nameArabic: 'an-nisa-ar',
    nameLatin: 'An-Nisa',
    ayahCount: 176,
    revelationPlace: 'Madinah',
    meaning: 'Tema 4',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 5,
    nameArabic: 'al-maidah-ar',
    nameLatin: 'Al-Maidah',
    ayahCount: 120,
    revelationPlace: 'Madinah',
    meaning: 'Tema 5',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 6,
    nameArabic: 'al-anam-ar',
    nameLatin: 'Al-Anam',
    ayahCount: 165,
    revelationPlace: 'Makkah',
    meaning: 'Tema 6',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 7,
    nameArabic: 'al-araf-ar',
    nameLatin: 'Al-Araf',
    ayahCount: 206,
    revelationPlace: 'Makkah',
    meaning: 'Tema 7',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 8,
    nameArabic: 'al-anfal-ar',
    nameLatin: 'Al-Anfal',
    ayahCount: 75,
    revelationPlace: 'Madinah',
    meaning: 'Tema 8',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 9,
    nameArabic: 'at-tawbah-ar',
    nameLatin: 'At-Tawbah',
    ayahCount: 129,
    revelationPlace: 'Madinah',
    meaning: 'Tema 9',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 10,
    nameArabic: 'yunus-ar',
    nameLatin: 'Yunus',
    ayahCount: 109,
    revelationPlace: 'Makkah',
    meaning: 'Tema 10',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 11,
    nameArabic: 'hud-ar',
    nameLatin: 'Hud',
    ayahCount: 123,
    revelationPlace: 'Makkah',
    meaning: 'Tema 11',
    descriptionId: '',
    audioFull: {},
  ),
  SurahSummary(
    surahId: 12,
    nameArabic: 'yusuf-ar',
    nameLatin: 'Yusuf',
    ayahCount: 111,
    revelationPlace: 'Makkah',
    meaning: 'Tema 12',
    descriptionId: '',
    audioFull: {},
  ),
];
