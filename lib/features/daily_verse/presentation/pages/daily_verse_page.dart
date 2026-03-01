import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../providers/daily_verse_providers.dart';

class DailyVersePage extends ConsumerWidget {
  const DailyVersePage({super.key});

  static const routeName = 'daily-verse-page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseState = ref.watch(todayDailyVerseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayat Harian')),
      body: RichPageBackground(
        child: AsyncStateView(
          value: verseState,
          onRetry: () => ref.invalidate(todayDailyVerseProvider),
          builder: (verse) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                RichInfoCard(
                  borderRadius: 24,
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
                        'Pilihan ayat untuk hari ini',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TawakkalColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.textArabic,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TawakkalTypography.arabicLabelStyle(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          size: 30,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.textLatin,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TawakkalColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.textIndonesian,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(label: 'Surah ${verse.surahId}'),
                          _MetaChip(label: 'Ayat ${verse.ayahNumber}'),
                          _MetaChip(label: verse.dateKey),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () {
                          context.push('/surah/${verse.surahId}');
                        },
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Buka Surah'),
                      ),
                    ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TawakkalColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isDark ? TawakkalColors.textSecondary : TawakkalColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
