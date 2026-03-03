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
                RichInfoCard(
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
                          color: isDark
                              ? Colors.white
                              : TawakkalColors.textPrimaryLight,
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
                              : TawakkalColors.textPrimaryLight.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        detail.summary.descriptionId,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () {
                          final url = detail
                              .summary
                              .audioFull[AppConfig.fallbackReciterKey];
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
                ),
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
