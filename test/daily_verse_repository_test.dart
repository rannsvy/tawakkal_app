import 'package:flutter_test/flutter_test.dart';
import 'package:tawakkal_app/core/storage/sqlite/app_database.dart';
import 'package:tawakkal_app/features/daily_verse/data/daily_verse_repository.dart';
import 'package:tawakkal_app/features/quran/domain/entities/ayah.dart';
import 'package:tawakkal_app/features/quran/domain/entities/bookmark.dart';
import 'package:tawakkal_app/features/quran/domain/entities/surah.dart';
import 'package:tawakkal_app/features/quran/domain/repositories/quran_repository.dart';

void main() {
  test('returns cached daily verse for same date key', () async {
    final db = _FakeDailyVerseDatabase();
    final quran = _FakeQuranRepository();
    final repository = DailyVerseRepository(
      database: db,
      quranRepository: quran,
    );

    final date = DateTime(2026, 3, 1, 10, 0);
    final first = await repository.getTodayVerse(now: date);
    final callsAfterFirst = quran.callCount;
    expect(first.dateKey, '2026-03-01');
    expect(first.textIndonesian, isNotEmpty);

    quran.throwOnCall = true;
    final second = await repository.getTodayVerse(now: date);
    expect(second.textArabic, first.textArabic);
    expect(quran.callCount, callsAfterFirst);
  });

  test('changes verse when local date key changes', () async {
    final db = _FakeDailyVerseDatabase();
    final quran = _FakeQuranRepository();
    final repository = DailyVerseRepository(
      database: db,
      quranRepository: quran,
    );

    final dayOne = await repository.getTodayVerse(now: DateTime(2026, 3, 1, 8));
    final dayTwo = await repository.getTodayVerse(now: DateTime(2026, 3, 2, 8));

    expect(dayOne.dateKey, '2026-03-01');
    expect(dayTwo.dateKey, '2026-03-02');
    expect('${dayOne.surahId}:${dayOne.ayahNumber}', isNotEmpty);
    expect('${dayTwo.surahId}:${dayTwo.ayahNumber}', isNotEmpty);
  });
}

class _FakeDailyVerseDatabase extends AppDatabase {
  final Map<String, Map<String, Object?>> _cache =
      <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> getDailyVerse({required String dateKey}) async {
    return _cache[dateKey];
  }

  @override
  Future<void> upsertDailyVerse({
    required String dateKey,
    required int surahId,
    required int ayahNumber,
    required String textAr,
    required String textLatin,
    required String textId,
    required String source,
  }) async {
    _cache[dateKey] = <String, Object?>{
      'date_key': dateKey,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'text_ar': textAr,
      'text_latin': textLatin,
      'text_id': textId,
      'source': source,
    };
  }
}

class _FakeQuranRepository implements QuranRepository {
  int callCount = 0;
  bool throwOnCall = false;

  @override
  Future<SurahDetail> getSurahDetail(int surahId, {bool forceRefresh = false}) {
    callCount += 1;
    if (throwOnCall) {
      throw Exception('network disabled');
    }
    return Future<SurahDetail>.value(
      SurahDetail(
        summary: SurahSummary(
          surahId: surahId,
          nameArabic: 'arabic-$surahId',
          nameLatin: 'Surah $surahId',
          ayahCount: 286,
          revelationPlace: 'Makkah',
          meaning: 'Meaning',
          descriptionId: '',
          audioFull: const <String, String>{},
        ),
        ayahs: List<Ayah>.generate(
          300,
          (index) => Ayah(
            surahId: surahId,
            ayahNumber: index + 1,
            textArabic: 'آية ${index + 1}',
            textLatin: 'Ayah ${index + 1}',
            textIndonesian: 'Makna ${index + 1}',
            audioUrls: const <String, String>{},
          ),
        ),
        tafsir: const <TafsirEntry>[],
      ),
    );
  }

  @override
  Future<List<SurahSummary>> getSurahs({bool forceRefresh = false}) {
    return Future<List<SurahSummary>>.value(const <SurahSummary>[]);
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
  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String note,
  }) {
    return Future<void>.value();
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
