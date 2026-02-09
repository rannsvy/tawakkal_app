import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/sqlite/app_database.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../data/equran_api.dart';
import '../../data/quran_repository_impl.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

final quranApiProvider = Provider<EquranApi>((ref) {
  final dio = ref.watch(dioProvider);
  return EquranApi(dio);
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final api = ref.watch(quranApiProvider);
  final database = ref.watch(appDatabaseProvider);
  return QuranRepositoryImpl(api: api, database: database);
});

final surahListProvider = FutureProvider<List<SurahSummary>>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  return repository.getSurahs();
});

final surahDetailProvider = FutureProvider.family<SurahDetail, int>((
  ref,
  surahId,
) async {
  final repository = ref.watch(quranRepositoryProvider);
  return repository.getSurahDetail(surahId);
});

final quranActionsProvider = Provider<QuranActions>((ref) {
  final repository = ref.watch(quranRepositoryProvider);
  return QuranActions(repository: repository, ref: ref);
});

final ayahBookmarkProvider = FutureProvider.family<bool, AyahLocator>((
  ref,
  locator,
) async {
  final repository = ref.watch(quranRepositoryProvider);
  final userLocalId = ref.watch(currentUserIdProvider);
  return repository.isBookmarked(
    userLocalId: userLocalId,
    surahId: locator.surahId,
    ayahNumber: locator.ayahNumber,
  );
});

final ayahNoteProvider = FutureProvider.family<String?, AyahLocator>((
  ref,
  locator,
) async {
  final repository = ref.watch(quranRepositoryProvider);
  final userLocalId = ref.watch(currentUserIdProvider);
  return repository.getNote(
    userLocalId: userLocalId,
    surahId: locator.surahId,
    ayahNumber: locator.ayahNumber,
  );
});

class QuranActions {
  QuranActions({required QuranRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref;

  final QuranRepository _repository;
  final Ref _ref;

  Future<void> toggleBookmark({
    required int surahId,
    required int ayahNumber,
    required bool bookmarked,
  }) async {
    final userLocalId = _ref.read(currentUserIdProvider);
    await _repository.toggleBookmark(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
      bookmarked: bookmarked,
    );
    _ref.invalidate(ayahBookmarkProvider(AyahLocator(surahId, ayahNumber)));
    await _ref.read(progressActionsProvider).syncPendingData();
  }

  Future<void> saveNote({
    required int surahId,
    required int ayahNumber,
    required String note,
  }) async {
    final userLocalId = _ref.read(currentUserIdProvider);
    await _repository.saveNote(
      userLocalId: userLocalId,
      surahId: surahId,
      ayahNumber: ayahNumber,
      note: note,
    );
    _ref.invalidate(ayahNoteProvider(AyahLocator(surahId, ayahNumber)));
    await _ref.read(progressActionsProvider).syncPendingData();
  }
}

class AyahLocator {
  const AyahLocator(this.surahId, this.ayahNumber);

  final int surahId;
  final int ayahNumber;

  @override
  bool operator ==(Object other) {
    return other is AyahLocator &&
        other.surahId == surahId &&
        other.ayahNumber == ayahNumber;
  }

  @override
  int get hashCode => Object.hash(surahId, ayahNumber);
}
