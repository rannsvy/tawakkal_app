import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/audio/presentation/pages/audio_page.dart';
import 'package:tawakkal_app/features/audio/presentation/providers/audio_providers.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';

void main() {
  Future<void> pumpAudioPage(
    WidgetTester tester, {
    List<SurahSummary> surahs = _sampleSurahs,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListProvider.overrideWith((ref) async => surahs),
          downloadedSurahIdsProvider.overrideWith(
            (ref, reciterId) async => <int>{},
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AudioPage())),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows search field and limits surah list to 10 by default', (
    tester,
  ) async {
    await pumpAudioPage(tester);

    final listView = tester.widget<ListView>(find.byType(ListView).first);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Cari surah (nama, arti, Arab, nomor)...'),
      findsOneWidget,
    );
    expect(listView.childrenDelegate.estimatedChildCount, 21);
  });

  testWidgets('expands to all surahs then collapses back to 10', (
    tester,
  ) async {
    await pumpAudioPage(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Tampilkan semua surah'));
    await tester.pumpAndSettle();

    final expandedListView = tester.widget<ListView>(
      find.byType(ListView).first,
    );
    expect(expandedListView.childrenDelegate.estimatedChildCount, 25);
    expect(find.text('Tampilkan lebih sedikit'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(TextButton, 'Tampilkan lebih sedikit'),
    );
    await tester.pumpAndSettle();

    final collapsedListView = tester.widget<ListView>(
      find.byType(ListView).first,
    );
    expect(collapsedListView.childrenDelegate.estimatedChildCount, 21);
  });

  testWidgets('search filters surahs and hides toggle', (tester) async {
    await pumpAudioPage(tester);

    await tester.enterText(find.byType(TextField), 'fatih');
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView).first);
    expect(listView.childrenDelegate.estimatedChildCount, 1);
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsNothing);
    expect(find.text('Tampilkan semua surah'), findsNothing);
  });

  testWidgets('shows empty state when search has no result', (tester) async {
    await pumpAudioPage(tester);

    await tester.enterText(find.byType(TextField), 'zzzz-no-match');
    await tester.pumpAndSettle();

    expect(find.text('Hasil tidak ditemukan'), findsOneWidget);
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
    audioFull: {'05': 'https://example.com/1.mp3'},
  ),
  SurahSummary(
    surahId: 2,
    nameArabic: 'al-baqarah-ar',
    nameLatin: 'Al-Baqarah',
    ayahCount: 286,
    revelationPlace: 'Madinah',
    meaning: 'Tema 2',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/2.mp3'},
  ),
  SurahSummary(
    surahId: 3,
    nameArabic: 'ali-imran-ar',
    nameLatin: 'Ali Imran',
    ayahCount: 200,
    revelationPlace: 'Madinah',
    meaning: 'Tema 3',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/3.mp3'},
  ),
  SurahSummary(
    surahId: 4,
    nameArabic: 'an-nisa-ar',
    nameLatin: 'An-Nisa',
    ayahCount: 176,
    revelationPlace: 'Madinah',
    meaning: 'Tema 4',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/4.mp3'},
  ),
  SurahSummary(
    surahId: 5,
    nameArabic: 'al-maidah-ar',
    nameLatin: 'Al-Maidah',
    ayahCount: 120,
    revelationPlace: 'Madinah',
    meaning: 'Tema 5',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/5.mp3'},
  ),
  SurahSummary(
    surahId: 6,
    nameArabic: 'al-anam-ar',
    nameLatin: 'Al-Anam',
    ayahCount: 165,
    revelationPlace: 'Makkah',
    meaning: 'Tema 6',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/6.mp3'},
  ),
  SurahSummary(
    surahId: 7,
    nameArabic: 'al-araf-ar',
    nameLatin: 'Al-Araf',
    ayahCount: 206,
    revelationPlace: 'Makkah',
    meaning: 'Tema 7',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/7.mp3'},
  ),
  SurahSummary(
    surahId: 8,
    nameArabic: 'al-anfal-ar',
    nameLatin: 'Al-Anfal',
    ayahCount: 75,
    revelationPlace: 'Madinah',
    meaning: 'Tema 8',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/8.mp3'},
  ),
  SurahSummary(
    surahId: 9,
    nameArabic: 'at-tawbah-ar',
    nameLatin: 'At-Tawbah',
    ayahCount: 129,
    revelationPlace: 'Madinah',
    meaning: 'Tema 9',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/9.mp3'},
  ),
  SurahSummary(
    surahId: 10,
    nameArabic: 'yunus-ar',
    nameLatin: 'Yunus',
    ayahCount: 109,
    revelationPlace: 'Makkah',
    meaning: 'Tema 10',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/10.mp3'},
  ),
  SurahSummary(
    surahId: 11,
    nameArabic: 'hud-ar',
    nameLatin: 'Hud',
    ayahCount: 123,
    revelationPlace: 'Makkah',
    meaning: 'Tema 11',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/11.mp3'},
  ),
  SurahSummary(
    surahId: 12,
    nameArabic: 'yusuf-ar',
    nameLatin: 'Yusuf',
    ayahCount: 111,
    revelationPlace: 'Makkah',
    meaning: 'Tema 12',
    descriptionId: '',
    audioFull: {'05': 'https://example.com/12.mp3'},
  ),
];
