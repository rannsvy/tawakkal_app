import 'dart:convert';

import '../../../core/storage/sqlite/app_database.dart';
import '../../../core/utils/html_utils.dart';
import '../domain/entities/ayah.dart';
import '../domain/entities/surah.dart';
import '../domain/repositories/quran_repository.dart';
import 'equran_api.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({required EquranApi api, required AppDatabase database})
    : _api = api,
      _database = database;

  final EquranApi _api;
  final AppDatabase _database;

  @override
  Future<List<SurahSummary>> getSurahs({bool forceRefresh = false}) async {
    final localRows = await _database.getSurahs();
    if (!forceRefresh && localRows.isNotEmpty) {
      return localRows.map(_surahFromRow).toList();
    }

    try {
      final remote = await _api.fetchSurahList();
      final now = DateTime.now().toIso8601String();
      final rows = remote
          .map(
            (item) => <String, Object?>{
              'surah_id': item['nomor'] as int,
              'name_ar': item['nama'] as String? ?? '',
              'name_latin': item['namaLatin'] as String? ?? '',
              'ayah_count': item['jumlahAyat'] as int? ?? 0,
              'revelation_place': item['tempatTurun'] as String? ?? '',
              'meaning': item['arti'] as String? ?? '',
              'description_id': stripHtmlTags(
                item['deskripsi'] as String? ?? '',
              ),
              'audio_full_json': jsonEncode(
                _stringMapFromDynamic(item['audioFull']),
              ),
              'updated_at': now,
            },
          )
          .toList();
      await _database.upsertSurahs(rows);
      return rows.map(_surahFromRow).toList();
    } catch (_) {
      if (localRows.isNotEmpty) {
        return localRows.map(_surahFromRow).toList();
      }
      rethrow;
    }
  }

  @override
  Future<SurahDetail> getSurahDetail(
    int surahId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final localSurah = await _database.getSurah(surahId);
      final localAyahs = await _database.getAyahs(surahId);
      if (localSurah != null && localAyahs.isNotEmpty) {
        final localTafsir = await _database.getTafsir(surahId);
        return SurahDetail(
          summary: _surahFromRow(localSurah),
          ayahs: localAyahs.map(_ayahFromRow).toList(),
          tafsir: localTafsir.map(_tafsirFromRow).toList(),
        );
      }
    }

    try {
      final detailMap = await _api.fetchSurahDetail(surahId);
      final tafsirMap = await _api.fetchTafsir(surahId);

      final summary = _surahFromRemote(detailMap);
      final ayahs = _ayahsFromRemote(
        surahId: surahId,
        data: detailMap['ayat'] as List<dynamic>? ?? const [],
      );
      final tafsir = _tafsirFromRemote(
        surahId: surahId,
        data: tafsirMap['tafsir'] as List<dynamic>? ?? const [],
      );

      await _database.upsertSurahDetail(
        surahRow: _surahToRow(summary),
        ayahRows: ayahs.map(_ayahToRow).toList(),
        tafsirRows: tafsir.map(_tafsirToRow).toList(),
      );

      return SurahDetail(summary: summary, ayahs: ayahs, tafsir: tafsir);
    } catch (_) {
      final localSurah = await _database.getSurah(surahId);
      final localAyahs = await _database.getAyahs(surahId);
      if (localSurah != null && localAyahs.isNotEmpty) {
        final localTafsir = await _database.getTafsir(surahId);
        return SurahDetail(
          summary: _surahFromRow(localSurah),
          ayahs: localAyahs.map(_ayahFromRow).toList(),
          tafsir: localTafsir.map(_tafsirFromRow).toList(),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> toggleBookmark({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  }) async {
    await _database.setBookmark(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
      bookmarked: bookmarked,
    );
    await _database.enqueueSync(
      entityType: 'bookmark',
      entityId: '$userLocalId:$surahId:$ayahNumber',
      operation: bookmarked ? 'upsert' : 'delete',
      payload: <String, Object?>{
        'user_id': userLocalId,
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'bookmarked': bookmarked,
      },
    );
  }

  @override
  Future<bool> isBookmarked({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) {
    return _database.isBookmarked(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
  }

  @override
  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String note,
  }) async {
    await _database.saveNote(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
      noteText: note,
    );
    await _database.enqueueSync(
      entityType: 'note',
      entityId: '$userLocalId:$surahId:$ayahNumber',
      operation: 'upsert',
      payload: <String, Object?>{
        'user_id': userLocalId,
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'note_text': note,
      },
    );
  }

  @override
  Future<String?> getNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  }) {
    return _database.getNote(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
  }

  SurahSummary _surahFromRemote(Map<String, dynamic> item) {
    return SurahSummary(
      surahId: item['nomor'] as int? ?? 0,
      nameArabic: item['nama'] as String? ?? '',
      nameLatin: item['namaLatin'] as String? ?? '',
      ayahCount: item['jumlahAyat'] as int? ?? 0,
      revelationPlace: item['tempatTurun'] as String? ?? '',
      meaning: item['arti'] as String? ?? '',
      descriptionId: stripHtmlTags(item['deskripsi'] as String? ?? ''),
      audioFull: _stringMapFromDynamic(item['audioFull']),
    );
  }

  List<Ayah> _ayahsFromRemote({
    required int surahId,
    required List<dynamic> data,
  }) {
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => Ayah(
            surahId: surahId,
            ayahNumber: item['nomorAyat'] as int? ?? 0,
            textArabic: item['teksArab'] as String? ?? '',
            textLatin: item['teksLatin'] as String? ?? '',
            textIndonesian: item['teksIndonesia'] as String? ?? '',
            textEnglish: null,
            audioUrls: _stringMapFromDynamic(item['audio']),
          ),
        )
        .toList();
  }

  List<TafsirEntry> _tafsirFromRemote({
    required int surahId,
    required List<dynamic> data,
  }) {
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => TafsirEntry(
            surahId: surahId,
            ayahNumber: item['ayat'] as int? ?? 0,
            text: item['teks'] as String? ?? '',
          ),
        )
        .toList();
  }

  SurahSummary _surahFromRow(Map<String, Object?> row) {
    return SurahSummary(
      surahId: (row['surah_id'] as int?) ?? 0,
      nameArabic: row['name_ar'] as String? ?? '',
      nameLatin: row['name_latin'] as String? ?? '',
      ayahCount: (row['ayah_count'] as int?) ?? 0,
      revelationPlace: row['revelation_place'] as String? ?? '',
      meaning: row['meaning'] as String? ?? '',
      descriptionId: row['description_id'] as String? ?? '',
      audioFull: _stringMapFromDynamic(
        jsonDecode(row['audio_full_json'] as String? ?? '{}'),
      ),
    );
  }

  Map<String, Object?> _surahToRow(SurahSummary surah) {
    return <String, Object?>{
      'surah_id': surah.surahId,
      'name_ar': surah.nameArabic,
      'name_latin': surah.nameLatin,
      'ayah_count': surah.ayahCount,
      'revelation_place': surah.revelationPlace,
      'meaning': surah.meaning,
      'description_id': surah.descriptionId,
      'audio_full_json': jsonEncode(surah.audioFull),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Ayah _ayahFromRow(Map<String, Object?> row) {
    return Ayah(
      surahId: (row['surah_id'] as int?) ?? 0,
      ayahNumber: (row['ayah_number'] as int?) ?? 0,
      textArabic: row['text_ar'] as String? ?? '',
      textLatin: row['text_latin'] as String? ?? '',
      textIndonesian: row['text_id'] as String? ?? '',
      textEnglish: row['text_en'] as String?,
      audioUrls: _stringMapFromDynamic(
        jsonDecode(row['audio_urls_json'] as String? ?? '{}'),
      ),
    );
  }

  Map<String, Object?> _ayahToRow(Ayah ayah) {
    return <String, Object?>{
      'surah_id': ayah.surahId,
      'ayah_number': ayah.ayahNumber,
      'text_ar': ayah.textArabic,
      'text_latin': ayah.textLatin,
      'text_id': ayah.textIndonesian,
      'text_en': ayah.textEnglish,
      'audio_urls_json': jsonEncode(ayah.audioUrls),
    };
  }

  TafsirEntry _tafsirFromRow(Map<String, Object?> row) {
    return TafsirEntry(
      surahId: (row['surah_id'] as int?) ?? 0,
      ayahNumber: (row['ayah_number'] as int?) ?? 0,
      text: row['tafsir_text'] as String? ?? '',
      source: row['source'] as String? ?? 'equran_tafsir_id',
    );
  }

  Map<String, Object?> _tafsirToRow(TafsirEntry entry) {
    return <String, Object?>{
      'surah_id': entry.surahId,
      'ayah_number': entry.ayahNumber,
      'tafsir_text': entry.text,
      'source': entry.source,
    };
  }

  Map<String, String> _stringMapFromDynamic(Object? raw) {
    if (raw is Map<String, String>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), '$value'));
    }
    return <String, String>{};
  }
}
