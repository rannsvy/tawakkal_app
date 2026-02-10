import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/constants/juz_boundaries.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/surah.dart';
import 'quran_providers.dart';

class JuzIndexItem {
  const JuzIndexItem({
    required this.boundary,
    required this.startSurahName,
    required this.endSurahName,
  });

  final JuzBoundary boundary;
  final String startSurahName;
  final String endSurahName;
}

class BookmarkedSurahGroup {
  const BookmarkedSurahGroup({
    required this.surah,
    required this.bookmarkCount,
    required this.latestAyahNumber,
    required this.latestCreatedAt,
  });

  final SurahSummary surah;
  final int bookmarkCount;
  final int latestAyahNumber;
  final DateTime latestCreatedAt;
}

final bookmarkedAyahsProvider = FutureProvider<List<BookmarkedAyah>>((
  ref,
) async {
  ref.watch(bookmarkRefreshTickProvider);
  final repository = ref.watch(quranRepositoryProvider);
  final userLocalId = ref.watch(currentUserIdProvider);
  return repository.getBookmarkedAyahs(userLocalId: userLocalId);
});

final bookmarkedSurahCountProvider = FutureProvider<Map<int, int>>((ref) async {
  final bookmarks = await ref.watch(bookmarkedAyahsProvider.future);
  final Map<int, int> counts = <int, int>{};
  for (final bookmark in bookmarks) {
    counts.update(bookmark.surahId, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
});

final bookmarkedSurahGroupsProvider =
    FutureProvider<List<BookmarkedSurahGroup>>((ref) async {
      final surahs = await ref.watch(surahListProvider.future);
      final bookmarks = await ref.watch(bookmarkedAyahsProvider.future);
      final Map<int, SurahSummary> surahMap = <int, SurahSummary>{
        for (final surah in surahs) surah.surahId: surah,
      };
      final Map<int, List<BookmarkedAyah>> grouped =
          <int, List<BookmarkedAyah>>{};
      for (final bookmark in bookmarks) {
        grouped
            .putIfAbsent(bookmark.surahId, () => <BookmarkedAyah>[])
            .add(bookmark);
      }

      final List<BookmarkedSurahGroup> groups =
          grouped.entries
              .map((entry) {
                final surah = surahMap[entry.key];
                if (surah == null || entry.value.isEmpty) {
                  return null;
                }
                final sorted = [...entry.value]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return BookmarkedSurahGroup(
                  surah: surah,
                  bookmarkCount: sorted.length,
                  latestAyahNumber: sorted.first.ayahNumber,
                  latestCreatedAt: sorted.first.createdAt,
                );
              })
              .whereType<BookmarkedSurahGroup>()
              .toList()
            ..sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));

      return groups;
    });

final juzIndexItemsProvider = FutureProvider<List<JuzIndexItem>>((ref) async {
  final surahs = await ref.watch(surahListProvider.future);
  final Map<int, String> surahNameById = <int, String>{
    for (final surah in surahs) surah.surahId: surah.nameLatin,
  };

  return kJuzBoundaries
      .map(
        (boundary) => JuzIndexItem(
          boundary: boundary,
          startSurahName:
              surahNameById[boundary.startSurahId] ??
              'Surah ${boundary.startSurahId}',
          endSurahName:
              surahNameById[boundary.endSurahId] ??
              'Surah ${boundary.endSurahId}',
        ),
      )
      .toList();
});
