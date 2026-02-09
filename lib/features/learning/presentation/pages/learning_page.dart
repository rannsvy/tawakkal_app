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
import '../../domain/entities/learning_stage.dart';

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key});

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  Difficulty _difficulty = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    final surahsState = ref.watch(surahListProvider);
    final difficultyLabel = _difficultyLabel(_difficulty);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RichPageBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  'Belajar secara bertahap dari pengantar surah hingga kuis makna.',
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
          const RichSectionTitle(title: 'Tahapan Pembelajaran'),
          const SizedBox(height: 8),
          ...kDefaultLearningStages.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LearningStageTile(
                stage: entry.value,
                isLast: entry.key == kDefaultLearningStages.length - 1,
              ),
            );
          }),
          const SizedBox(height: 6),
          const RichSectionTitle(title: 'Pilih Surah untuk Mulai Kuis'),
          const SizedBox(height: 8),
          AsyncStateView(
            value: surahsState,
            onRetry: () => ref.invalidate(surahListProvider),
            builder: (surahs) {
              return Column(
                children: surahs.map((surah) {
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
                }).toList(),
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
}

class _LearningStageTile extends StatelessWidget {
  const _LearningStageTile({required this.stage, required this.isLast});

  final LearningStage stage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary.withValues(alpha: 0.2),
                border: Border.all(
                  color: TawakkalColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '${stage.order}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TawakkalColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: TawakkalColors.primary.withValues(alpha: 0.35),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichInfoCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
        ),
      ],
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
