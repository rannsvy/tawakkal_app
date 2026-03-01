import '../../../core/storage/sqlite/app_database.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/domain/repositories/quran_repository.dart';
import '../domain/entities/daily_verse.dart';

class DailyVerseRepository {
  DailyVerseRepository({
    required AppDatabase database,
    required QuranRepository quranRepository,
  }) : _database = database,
       _quranRepository = quranRepository;

  final AppDatabase _database;
  final QuranRepository _quranRepository;

  static const List<({int surahId, int ayahNumber})> _curatedPool = [
    (surahId: 1, ayahNumber: 1),
    (surahId: 1, ayahNumber: 2),
    (surahId: 1, ayahNumber: 5),
    (surahId: 2, ayahNumber: 152),
    (surahId: 2, ayahNumber: 186),
    (surahId: 2, ayahNumber: 255),
    (surahId: 2, ayahNumber: 286),
    (surahId: 3, ayahNumber: 139),
    (surahId: 13, ayahNumber: 28),
    (surahId: 14, ayahNumber: 7),
    (surahId: 16, ayahNumber: 97),
    (surahId: 17, ayahNumber: 24),
    (surahId: 24, ayahNumber: 35),
    (surahId: 39, ayahNumber: 53),
    (surahId: 65, ayahNumber: 2),
    (surahId: 65, ayahNumber: 3),
    (surahId: 93, ayahNumber: 3),
    (surahId: 93, ayahNumber: 4),
    (surahId: 93, ayahNumber: 5),
    (surahId: 94, ayahNumber: 5),
    (surahId: 94, ayahNumber: 6),
    (surahId: 103, ayahNumber: 1),
    (surahId: 103, ayahNumber: 2),
    (surahId: 103, ayahNumber: 3),
    (surahId: 112, ayahNumber: 1),
    (surahId: 112, ayahNumber: 2),
    (surahId: 112, ayahNumber: 3),
    (surahId: 112, ayahNumber: 4),
  ];

  Future<DailyVerse> getTodayVerse({DateTime? now}) async {
    final value = now ?? DateTime.now();
    final dateKey = _dateKey(value);

    final cached = await _database.getDailyVerse(dateKey: dateKey);
    if (cached != null) {
      return _fromRow(cached);
    }

    final seed = dateKey.hashCode.abs();
    final initialIndex = seed % _curatedPool.length;
    for (var offset = 0; offset < _curatedPool.length; offset++) {
      final selected =
          _curatedPool[(initialIndex + offset) % _curatedPool.length];
      final ayah = await _tryResolveAyah(
        surahId: selected.surahId,
        ayahNumber: selected.ayahNumber,
      );
      if (ayah == null) {
        continue;
      }
      final verse = DailyVerse(
        dateKey: dateKey,
        surahId: selected.surahId,
        ayahNumber: selected.ayahNumber,
        textArabic: ayah.textArabic,
        textLatin: ayah.textLatin,
        textIndonesian: ayah.textIndonesian,
        source: 'curated_pool',
      );
      await _database.upsertDailyVerse(
        dateKey: dateKey,
        surahId: verse.surahId,
        ayahNumber: verse.ayahNumber,
        textAr: verse.textArabic,
        textLatin: verse.textLatin,
        textId: verse.textIndonesian,
        source: verse.source,
      );
      return verse;
    }

    // Guaranteed fallback to keep UI available even when curated ayahs fail.
    final fallbackAyah = await _tryResolveAyah(surahId: 1, ayahNumber: 1);
    final verse = DailyVerse(
      dateKey: dateKey,
      surahId: 1,
      ayahNumber: 1,
      textArabic: fallbackAyah?.textArabic ?? '',
      textLatin: fallbackAyah?.textLatin ?? '',
      textIndonesian: fallbackAyah?.textIndonesian ?? '',
      source: 'fallback',
    );
    await _database.upsertDailyVerse(
      dateKey: dateKey,
      surahId: verse.surahId,
      ayahNumber: verse.ayahNumber,
      textAr: verse.textArabic,
      textLatin: verse.textLatin,
      textId: verse.textIndonesian,
      source: verse.source,
    );
    return verse;
  }

  Future<Ayah?> _tryResolveAyah({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final detail = await _quranRepository.getSurahDetail(surahId);
      for (final ayah in detail.ayahs) {
        if (ayah.ayahNumber == ayahNumber) {
          return ayah;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  DailyVerse _fromRow(Map<String, Object?> row) {
    return DailyVerse(
      dateKey: row['date_key'] as String? ?? '',
      surahId: (row['surah_id'] as int?) ?? 1,
      ayahNumber: (row['ayah_number'] as int?) ?? 1,
      textArabic: row['text_ar'] as String? ?? '',
      textLatin: row['text_latin'] as String? ?? '',
      textIndonesian: row['text_id'] as String? ?? '',
      source: row['source'] as String? ?? 'cache',
    );
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }
}
