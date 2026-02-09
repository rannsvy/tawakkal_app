import '../entities/surah.dart';

abstract class QuranRepository {
  Future<List<SurahSummary>> getSurahs({bool forceRefresh = false});
  Future<SurahDetail> getSurahDetail(int surahId, {bool forceRefresh = false});
  Future<void> toggleBookmark({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  });
  Future<bool> isBookmarked({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  });
  Future<void> saveNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
    required String note,
  });
  Future<String?> getNote({
    required String userLocalId,
    required int surahId,
    required int ayahNumber,
  });
}
