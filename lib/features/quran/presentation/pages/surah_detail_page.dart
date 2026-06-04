import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/reciters.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../../../chat/data/chat_prompt_builder.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_card.dart';

class SurahDetailPage extends ConsumerWidget {
  const SurahDetailPage({super.key, required this.surahId});

  static const routeName = 'surah-detail';
  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(surahDetailProvider(surahId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Surah')),
      body: RichPageBackground(
        child: AsyncStateView(
          value: detailState,
          onRetry: () => ref.invalidate(surahDetailProvider(surahId)),
          builder: (detail) {
            final chatContext = ChatPromptBuilder.buildContext(detail);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ref.read(activeSurahContextProvider) != chatContext) {
                ref.read(activeSurahContextProvider.notifier).state =
                    chatContext;
              }
            });

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SurahSummaryCard(detail: detail, isDark: isDark),
                const SizedBox(height: 14),
                ...detail.ayahs.map(
                  (ayah) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AyahCard(
                      ayah: ayah,
                      onPlayPressed: () {
                        final url =
                            ayah.audioUrls[AppConfig.fallbackReciterKey];
                        if (url == null) {
                          return;
                        }
                        ref
                            .read(audioActionsProvider)
                            .playUrl(
                              url: url,
                              title:
                                  '${detail.summary.nameLatin} - Ayat ${ayah.ayahNumber}',
                              artist: kReciters[AppConfig.fallbackReciterKey],
                            );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahSummaryCard extends ConsumerStatefulWidget {
  const _SurahSummaryCard({required this.detail, required this.isDark});

  final SurahDetail detail;
  final bool isDark;

  @override
  ConsumerState<_SurahSummaryCard> createState() => _SurahSummaryCardState();
}

class _SurahSummaryCardState extends ConsumerState<_SurahSummaryCard> {
  static const int _collapsedDescriptionLines = 4;
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final isDark = widget.isDark;
    final description = detail.summary.descriptionId.trim();
    final canExpand = description.length > 220;

    return RichInfoCard(
      borderRadius: 22,
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2724), Color(0xFF202F2B)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF0F6F4)],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            detail.summary.nameArabic,
            textAlign: TextAlign.right,
            style: TawakkalTypography.arabicLabelStyle(
              color: isDark ? Colors.white : TawakkalColors.textPrimaryLight,
              size: 32,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.summary.nameLatin,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${detail.summary.revelationPlace} - ${detail.summary.ayahCount} ayat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? TawakkalColors.textSecondary
                  : TawakkalColors.textPrimaryLight.withValues(alpha: 0.7),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: _isDescriptionExpanded
                  ? null
                  : _collapsedDescriptionLines,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? TawakkalColors.textPrimaryDark
                    : TawakkalColors.textPrimaryLight,
                height: 1.38,
              ),
            ),
            if (canExpand) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: TawakkalColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _isDescriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isDescriptionExpanded ? 'Show Less' : 'Show More',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              final url =
                  detail.summary.audioFull[AppConfig.fallbackReciterKey];
              if (url == null) {
                return;
              }
              ref
                  .read(audioActionsProvider)
                  .playUrl(
                    url: url,
                    title: detail.summary.nameLatin,
                    artist: kReciters[AppConfig.fallbackReciterKey],
                  );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Putar Murottal Surah'),
          ),
        ],
      ),
    );
  }
}
