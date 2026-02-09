import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../providers/quran_providers.dart';

class SurahListPage extends ConsumerWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahListProvider);

    return RichPageBackground(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(surahListProvider);
          await ref.read(surahListProvider.future);
        },
        child: AsyncStateView(
          value: surahs,
          onRetry: () => ref.invalidate(surahListProvider),
          builder: (items) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final surah = items[index];
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final titleColor = isDark
                    ? TawakkalColors.textPrimaryDark
                    : TawakkalColors.textPrimaryLight;
                final subtitleColor = isDark
                    ? TawakkalColors.textSecondary.withValues(alpha: 0.95)
                    : TawakkalColors.textPrimaryLight.withValues(alpha: 0.66);

                return RichInfoCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () => context.push('/surah/${surah.surahId}'),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TawakkalColors.primary.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                          border: Border.all(
                            color: TawakkalColors.primary.withValues(
                              alpha: isDark ? 0.42 : 0.24,
                            ),
                          ),
                        ),
                        child: Text(
                          '${surah.surahId}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${surah.revelationPlace} - ${surah.ayahCount} ayat',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : TawakkalColors.textPrimaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
