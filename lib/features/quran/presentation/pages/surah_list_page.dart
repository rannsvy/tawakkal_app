import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/diamond_index_badge.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_index_providers.dart';
import '../providers/quran_providers.dart';

enum QuranIndexTab { surah, juz, bookmarks }

class SurahListPage extends ConsumerStatefulWidget {
  const SurahListPage({super.key});

  @override
  ConsumerState<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends ConsumerState<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  QuranIndexTab _activeTab = QuranIndexTab.surah;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahsState = ref.watch(surahListProvider);
    final juzItemsState = ref.watch(juzIndexItemsProvider);
    final bookmarkedGroupsState = ref.watch(bookmarkedSurahGroupsProvider);
    final bookmarkedCountMap =
        ref.watch(bookmarkedSurahCountProvider).asData?.value ??
        const <int, int>{};

    return RichPageBackground(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(surahListProvider);
          ref.invalidate(juzIndexItemsProvider);
          ref.invalidate(bookmarkedAyahsProvider);
          ref.invalidate(bookmarkedSurahGroupsProvider);
          ref.invalidate(bookmarkedSurahCountProvider);
          await Future.wait([
            ref.read(surahListProvider.future),
            ref.read(juzIndexItemsProvider.future),
            ref.read(bookmarkedSurahGroupsProvider.future),
          ]);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: _QuranIndexHeader(
                onSettingsTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan Quran akan hadir segera.'),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: _SearchField(
                controller: _searchController,
                placeholder: _placeholderForTab(_activeTab),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _SegmentedTabs(
                activeTab: _activeTab,
                onChanged: (tab) {
                  setState(() {
                    _activeTab = tab;
                  });
                },
              ),
            ),
            Expanded(
              child: switch (_activeTab) {
                QuranIndexTab.surah => AsyncStateView(
                  value: surahsState,
                  onRetry: () => ref.invalidate(surahListProvider),
                  builder: (surahs) {
                    final filtered = _filterSurahs(surahs, _query);
                    if (filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Surah tidak ditemukan',
                        description:
                            'Coba kata kunci lain untuk pencarian surah.',
                      );
                    }

                    return ListView.separated(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final surah = filtered[index];
                        final bookmarkCount =
                            bookmarkedCountMap[surah.surahId] ?? 0;
                        return _SurahIndexCard(
                          surah: surah,
                          bookmarkCount: bookmarkCount,
                          onTap: () => context.push('/surah/${surah.surahId}'),
                        );
                      },
                    );
                  },
                ),
                QuranIndexTab.juz => AsyncStateView(
                  value: juzItemsState,
                  onRetry: () => ref.invalidate(juzIndexItemsProvider),
                  builder: (juzItems) {
                    final filtered = _filterJuzItems(juzItems, _query);
                    if (filtered.isEmpty) {
                      return const _EmptyState(
                        title: 'Juz tidak ditemukan',
                        description:
                            'Gunakan nomor juz atau nama surah awal/akhir.',
                      );
                    }

                    return ListView.separated(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _JuzIndexCard(
                          item: item,
                          onTap: () => context.push(
                            '/surah/${item.boundary.startSurahId}',
                          ),
                        );
                      },
                    );
                  },
                ),
                QuranIndexTab.bookmarks => AsyncStateView(
                  value: bookmarkedGroupsState,
                  onRetry: () {
                    ref.invalidate(bookmarkedAyahsProvider);
                    ref.invalidate(bookmarkedSurahGroupsProvider);
                  },
                  builder: (groups) {
                    final filtered = _filterBookmarkGroups(groups, _query);
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        title: 'Belum ada bookmark',
                        description: _query.isEmpty
                            ? 'Simpan ayat favorit di halaman detail surah.'
                            : 'Tidak ada hasil bookmark untuk kata kunci tersebut.',
                      );
                    }

                    return ListView.separated(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = filtered[index];
                        return _BookmarkSurahCard(
                          group: group,
                          onTap: () =>
                              context.push('/surah/${group.surah.surahId}'),
                        );
                      },
                    );
                  },
                ),
              },
            ),
            if (!isDark) const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  String _placeholderForTab(QuranIndexTab tab) {
    return switch (tab) {
      QuranIndexTab.surah => 'Search Surah by name or number...',
      QuranIndexTab.juz => 'Search Juz number or Surah range...',
      QuranIndexTab.bookmarks => 'Search bookmarked Surah...',
    };
  }

  List<SurahSummary> _filterSurahs(List<SurahSummary> surahs, String query) {
    if (query.isEmpty) {
      return surahs;
    }
    final lower = query.toLowerCase();
    return surahs.where((surah) {
      return surah.surahId.toString().contains(lower) ||
          surah.nameLatin.toLowerCase().contains(lower) ||
          surah.nameArabic.contains(query) ||
          surah.meaning.toLowerCase().contains(lower);
    }).toList();
  }

  List<JuzIndexItem> _filterJuzItems(List<JuzIndexItem> items, String query) {
    if (query.isEmpty) {
      return items;
    }
    final lower = query.toLowerCase();
    return items.where((item) {
      return item.boundary.juzNumber.toString().contains(lower) ||
          'juz ${item.boundary.juzNumber}'.contains(lower) ||
          item.startSurahName.toLowerCase().contains(lower) ||
          item.endSurahName.toLowerCase().contains(lower);
    }).toList();
  }

  List<BookmarkedSurahGroup> _filterBookmarkGroups(
    List<BookmarkedSurahGroup> groups,
    String query,
  ) {
    if (query.isEmpty) {
      return groups;
    }
    final lower = query.toLowerCase();
    return groups.where((group) {
      return group.surah.surahId.toString().contains(lower) ||
          group.surah.nameLatin.toLowerCase().contains(lower) ||
          group.surah.nameArabic.contains(query);
    }).toList();
  }
}

class _QuranIndexHeader extends StatelessWidget {
  const _QuranIndexHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          'Quran Index',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDark
                ? TawakkalColors.textPrimaryDark
                : TawakkalColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings_rounded),
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? TawakkalColors.surfaceDark.withValues(alpha: 0.8)
                : TawakkalColors.surfaceLight,
            foregroundColor: isDark
                ? TawakkalColors.textSecondary
                : TawakkalColors.textPrimaryLight.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.placeholder});

  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white : TawakkalColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? TawakkalColors.textSecondary
              : TawakkalColors.textPrimaryLight.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark
              ? TawakkalColors.textSecondary
              : TawakkalColors.textPrimaryLight.withValues(alpha: 0.6),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: controller.clear,
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark
                      ? TawakkalColors.textSecondary
                      : TawakkalColors.textPrimaryLight.withValues(alpha: 0.55),
                ),
              )
            : null,
        filled: true,
        fillColor: isDark
            ? TawakkalColors.surfaceDark
            : TawakkalColors.surfaceLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1DFFFFFF) : const Color(0x12000000),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: TawakkalColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.activeTab, required this.onChanged});

  final QuranIndexTab activeTab;
  final ValueChanged<QuranIndexTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tabButton(QuranIndexTab tab, String label) {
      final selected = activeTab == tab;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? TawakkalColors.primary
                : (isDark
                      ? Colors.transparent
                      : TawakkalColors.surfaceLight.withValues(alpha: 0.0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () => onChanged(tab),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? TawakkalColors.backgroundDark
                    : (isDark
                          ? TawakkalColors.textSecondary
                          : TawakkalColors.textPrimaryLight.withValues(
                              alpha: 0.7,
                            )),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? TawakkalColors.surfaceDark.withValues(alpha: 0.88)
            : TawakkalColors.surfaceLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x1DFFFFFF) : const Color(0x12000000),
        ),
      ),
      child: Row(
        children: [
          tabButton(QuranIndexTab.surah, 'Surah'),
          const SizedBox(width: 4),
          tabButton(QuranIndexTab.juz, 'Juz'),
          const SizedBox(width: 4),
          tabButton(QuranIndexTab.bookmarks, 'Bookmarks'),
        ],
      ),
    );
  }
}

class _SurahIndexCard extends StatelessWidget {
  const _SurahIndexCard({
    required this.surah,
    required this.bookmarkCount,
    required this.onTap,
  });

  final SurahSummary surah;
  final int bookmarkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBookmark = bookmarkCount > 0;

    return RichInfoCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Stack(
        children: [
          if (hasBookmark)
            Positioned(
              left: -14,
              top: -13,
              bottom: -13,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: TawakkalColors.accentGold,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              DiamondIndexBadge(
                number: surah.surahId,
                highlighted: hasBookmark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            surah.nameLatin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: isDark
                                      ? TawakkalColors.textPrimaryDark
                                      : TawakkalColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          surah.nameArabic,
                          textDirection: TextDirection.rtl,
                          style: TawakkalTypography.arabicLabelStyle(
                            color: TawakkalColors.primary,
                            size: 21,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.meaning} - ${surah.revelationPlace} - ${surah.ayahCount} verses',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? TawakkalColors.textSecondary
                            : TawakkalColors.textPrimaryLight.withValues(
                                alpha: 0.63,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (hasBookmark)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.bookmark_rounded,
                      size: 18,
                      color: TawakkalColors.accentGold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bookmarkCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TawakkalColors.accentGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? TawakkalColors.textSecondary
                      : TawakkalColors.textPrimaryLight.withValues(alpha: 0.55),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JuzIndexCard extends StatelessWidget {
  const _JuzIndexCard({required this.item, required this.onTap});

  final JuzIndexItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spanCount = item.boundary.endSurahId - item.boundary.startSurahId + 1;
    final spanText = spanCount <= 1 ? '1 surah' : '$spanCount surahs';
    return RichInfoCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          DiamondIndexBadge(
            number: item.boundary.juzNumber,
            highlighted: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juz ${item.boundary.juzNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? TawakkalColors.textPrimaryDark
                        : TawakkalColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.startSurahName} ${item.boundary.startAyah} - ${item.endSurahName} ${item.boundary.endAyah}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? TawakkalColors.textSecondary
                        : TawakkalColors.textPrimaryLight.withValues(
                            alpha: 0.63,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spanText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TawakkalColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? TawakkalColors.textSecondary
                    : TawakkalColors.textPrimaryLight.withValues(alpha: 0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookmarkSurahCard extends StatelessWidget {
  const _BookmarkSurahCard({required this.group, required this.onTap});

  final BookmarkedSurahGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RichInfoCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          DiamondIndexBadge(number: group.surah.surahId, highlighted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.surah.nameLatin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.surah.nameArabic,
                      textDirection: TextDirection.rtl,
                      style: TawakkalTypography.arabicLabelStyle(
                        color: TawakkalColors.primary,
                        size: 21,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.bookmarkCount} bookmarked ayat - latest ayat ${group.latestAyahNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? TawakkalColors.textSecondary
                        : TawakkalColors.textPrimaryLight.withValues(
                            alpha: 0.63,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.bookmark_rounded,
                size: 18,
                color: TawakkalColors.accentGold,
              ),
              const SizedBox(height: 2),
              Text(
                '${group.bookmarkCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TawakkalColors.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 30,
              color: isDark
                  ? TawakkalColors.textSecondary
                  : TawakkalColors.textPrimaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? TawakkalColors.textSecondary
                    : TawakkalColors.textPrimaryLight.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
