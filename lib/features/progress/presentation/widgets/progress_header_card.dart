import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../providers/progress_providers.dart';

class ProgressHeaderCard extends ConsumerWidget {
  const ProgressHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(progressSnapshotProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RichInfoCard(
      borderRadius: 20,
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
      child: AsyncStateView(
        value: progressState,
        builder: (snapshot) {
          final progressInLevel = snapshot.xpTotal % 120;
          final value = (progressInLevel / 120).clamp(0, 1).toDouble();
          final titleColor = isDark
              ? TawakkalColors.textPrimaryDark
              : TawakkalColors.textPrimaryLight;
          final subtitleColor = isDark
              ? TawakkalColors.textSecondary
              : TawakkalColors.textPrimaryLight.withValues(alpha: 0.66);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Level ${snapshot.level}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'XP ${snapshot.xpTotal}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: TawakkalColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x16000000),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TawakkalColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Streak: ${snapshot.currentStreak} hari',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                  ),
                  const Spacer(),
                  Text(
                    'Terpanjang: ${snapshot.longestStreak}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
