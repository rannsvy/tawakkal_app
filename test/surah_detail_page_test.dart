import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/features/quran/domain/entities/bookmark.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:tawakkal_app/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:tawakkal_app/features/quran/presentation/providers/quran_providers.dart';

void main() {
  testWidgets('surah description is collapsed and expands with Show More', (
    tester,
  ) async {
    const description =
        'Surat Al Faatihah (Pembukaan) yang diturunkan di Mekah dan terdiri '
        'dari 7 ayat adalah surat yang pertama-tama diturunkan dengan lengkap '
        'diantara surat-surat yang ada dalam Al Quran dan termasuk golongan '
        'surat Makkiyyah. Surat ini disebut Al Faatihah karena dengan surat '
        'inilah dibuka dan dimulainya Al Quran. Dinamakan Ummul Quran karena '
        'dia merupakan induk dari semua isi Al Quran.';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranRepositoryProvider.overrideWithValue(
            _FakeQuranRepository(description: description),
          ),
        ],
        child: const MaterialApp(home: SurahDetailPage(surahId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show More'), findsOneWidget);
    final collapsedText = tester.widget<Text>(find.text(description));
    expect(collapsedText.maxLines, 4);

    await tester.tap(find.text('Show More'));
    await tester.pumpAndSettle();

    expect(find.text('Show Less'), findsOneWidget);
    final expandedText = tester.widget<Text>(find.text(description));
    expect(expandedText.maxLines, isNull);
  });
}

class _FakeQuranRepository implements QuranRepository {
  const _FakeQuranRepository({required this.description});

  final String description;

  @override
  Future<SurahDetail> getSurahDetail(
    int surahId, {
    bool forceRefresh = false,
  }) async {
    return SurahDetail(
      summary: SurahSummary(
        surahId: 1,
        nameArabic: 'الفاتحة',
        nameLatin: 'Al-Fatihah',
        ayahCount: 7,
        revelationPlace: 'Mekah',
        meaning: 'Pembukaan',
        descriptionId: description,
        audioFull: const {},
      ),
      ayahs: const [],
      tafsir: const [],
    );
  }

  @override
  Future<List<SurahSummary>> getSurahs({bool forceRefresh = false}) async => [];

  @override
  Future<List<BookmarkedAyah>> getBookmarkedAyahs({
    required String userLocalId,
  }) async => [];

  @override
  Future<String?> getNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) async => null;

  @override
  Future<bool> isBookmarked({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) async => false;

  @override
  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String note,
  }) async {}

  @override
  Future<void> toggleBookmark({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  }) async {}
}
