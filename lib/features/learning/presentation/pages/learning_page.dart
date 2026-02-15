import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../../shared/widgets/rich_section_title.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../domain/entities/difficulty.dart';

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key, this.bottomOverlayOverlap = 0});

  final double bottomOverlayOverlap;

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  final TextEditingController _searchController = TextEditingController();

  Difficulty _difficulty = Difficulty.easy;
  String _query = '';
  bool _showAllSurahs = false;

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
    final surahsState = ref.watch(surahListProvider);
    final difficultyLabel = _difficultyLabel(_difficulty);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const endGap = 8.0;
    const fallbackPadding = 16.0;
    final listBottomPadding = math.max(
      fallbackPadding,
      widget.bottomOverlayOverlap + endGap,
    );

    return RichPageBackground(
      child: ListView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPadding),
        children: [
          RichInfoCard(
            borderRadius: 24,
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF182523), Color(0xFF1E2F2B)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9F8F3), Color(0xFFDFF3ED)],
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: TawakkalColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jalur Belajar Surah',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : TawakkalColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        difficultyLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? TawakkalColors.textSecondary
                              : TawakkalColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Pilih tingkat kesulitan, cari surah, lalu mulai kuis.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? TawakkalColors.textSecondary
                        : TawakkalColors.textPrimaryLight.withValues(
                            alpha: 0.68,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const RichSectionTitle(title: 'Pilih Tingkat Kesulitan'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Difficulty.values.map((difficulty) {
              final selected = _difficulty == difficulty;
              return ChoiceChip(
                label: Text(_difficultyLabel(difficulty)),
                selected: selected,
                showCheckmark: false,
                selectedColor: TawakkalColors.primary.withValues(alpha: 0.2),
                backgroundColor: isDark
                    ? TawakkalColors.surfaceDark.withValues(alpha: 0.65)
                    : TawakkalColors.surfaceLight,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? TawakkalColors.primary
                      : (isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight),
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected
                      ? TawakkalColors.primary.withValues(alpha: 0.5)
                      : (isDark
                            ? const Color(0x1EFFFFFF)
                            : const Color(0x12000000)),
                ),
                onSelected: (_) {
                  setState(() {
                    _difficulty = difficulty;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const RichSectionTitle(title: 'Pilih Surah untuk Mulai Kuis'),
          const SizedBox(height: 8),
          _SurahSearchField(
            controller: _searchController,
            query: _query,
            onClear: _searchController.clear,
          ),
          const SizedBox(height: 10),
          AsyncStateView(
            value: surahsState,
            onRetry: () => ref.invalidate(surahListProvider),
            builder: (surahs) {
              final filteredSurahs = _filterSurahs(surahs, _query);
              if (filteredSurahs.isEmpty) {
                return const _SurahSearchEmptyState();
              }

              final isSearching = _query.isNotEmpty;
              final showToggle = !isSearching && filteredSurahs.length > 10;
              final visibleSurahs = (isSearching || _showAllSurahs)
                  ? filteredSurahs
                  : filteredSurahs.take(10).toList(growable: false);

              return Column(
                children: [
                  ...visibleSurahs.map((surah) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SurahQuizTile(
                        surah: surah,
                        difficulty: _difficulty,
                        onTap: () {
                          context.push(
                            '/quiz?surahId=${surah.surahId}&difficulty=${_difficulty.name}',
                          );
                        },
                      ),
                    );
                  }),
                  if (showToggle)
                    _SurahListToggle(
                      isExpanded: _showAllSurahs,
                      visibleCount: visibleSurahs.length,
                      totalCount: filteredSurahs.length,
                      onToggle: () {
                        setState(() {
                          _showAllSurahs = !_showAllSurahs;
                        });
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => 'Mudah',
      Difficulty.medium => 'Menengah',
      Difficulty.hard => 'Sulit',
    };
  }

  List<SurahSummary> _filterSurahs(List<SurahSummary> surahs, String query) {
    if (query.isEmpty) {
      return surahs;
    }
    final lowerQuery = query.toLowerCase();
    return surahs
        .where((surah) {
          return surah.surahId.toString().contains(lowerQuery) ||
              surah.nameLatin.toLowerCase().contains(lowerQuery) ||
              surah.meaning.toLowerCase().contains(lowerQuery) ||
              surah.nameArabic.contains(query);
        })
        .toList(growable: false);
  }
}

class _SurahSearchField extends StatelessWidget {
  const _SurahSearchField({
    required this.controller,
    required this.query,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari surah (nama, arti, Arab, nomor)...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Hapus pencarian',
              ),
        filled: true,
        fillColor: isDark
            ? TawakkalColors.surfaceDark.withValues(alpha: 0.65)
            : TawakkalColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1EFFFFFF) : const Color(0x12000000),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: TawakkalColors.primary.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SurahListToggle extends StatelessWidget {
  const _SurahListToggle({
    required this.isExpanded,
    required this.visibleCount,
    required this.totalCount,
    required this.onToggle,
  });

  final bool isExpanded;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: RichInfoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Menampilkan $visibleCount dari $totalCount surah',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
            ),
            TextButton(
              onPressed: onToggle,
              child: Text(
                isExpanded
                    ? 'Tampilkan lebih sedikit'
                    : 'Tampilkan semua surah',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahSearchEmptyState extends StatelessWidget {
  const _SurahSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68);

    return RichInfoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TawakkalColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.search_off_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasil tidak ditemukan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coba kata kunci lain untuk surah.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahQuizTile extends StatelessWidget {
  const _SurahQuizTile({
    required this.surah,
    required this.difficulty,
    required this.onTap,
  });

  final SurahSummary surah;
  final Difficulty difficulty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68);

    return RichInfoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TawakkalColors.primary.withValues(alpha: 0.16),
            ),
            child: Text(
              '${surah.surahId}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TawakkalColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.nameLatin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${surah.ayahCount} ayat - ${_difficultyLabel(difficulty)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: onTap, child: const Text('Mulai')),
        ],
      ),
    );
  }

  String _difficultyLabel(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => 'Mudah',
      Difficulty.medium => 'Menengah',
      Difficulty.hard => 'Sulit',
    };
  }
}
