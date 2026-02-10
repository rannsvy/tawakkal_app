import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/constants/reciters.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/presentation/providers/quran_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final progress = ref.watch(progressSnapshotProvider).asData?.value;
    final surahs =
        ref.watch(surahListProvider).asData?.value ?? const <SurahSummary>[];

    final greetingName = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : 'Sahabat';
    final streak = progress?.currentStreak ?? 0;
    final xpTotal = progress?.xpTotal ?? 0;
    const goalTargetMinutes = 20;
    final todayMinutes = math
        .min(goalTargetMinutes, ((xpTotal % 260) ~/ 12) + math.min(streak, 4))
        .toInt();
    final goalRatio = (todayMinutes / goalTargetMinutes).clamp(0.0, 1.0);
    final continueSurah = _pickContinueSurah(surahs);
    final continueCompletion = math.min(0.96, 0.24 + (xpTotal % 72) / 100);
    final continueAyah = continueSurah == null
        ? 1
        : math.max(1, (continueSurah.ayahCount * continueCompletion).round());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [TawakkalColors.backgroundDark, Color(0xFF141F1C)]
              : const [TawakkalColors.backgroundLight, Color(0xFFEEF4F2)],
        ),
      ),
      child: CustomPaint(
        painter: _PatternPainter(
          color: TawakkalColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: _DashboardHeader(
                  streak: streak,
                  onNotificationsTap: () =>
                      _showComingSoon(context, featureLabel: 'Notifikasi'),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                  children: [
                    Text(
                      'Ramadan Mubarak',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TawakkalColors.textSecondary,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                            ),
                        children: [
                          const TextSpan(text: 'Assalamu Alaikum,\n'),
                          TextSpan(
                            text: greetingName,
                            style: const TextStyle(
                              color: TawakkalColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _TodayGoalCard(
                      currentMinutes: todayMinutes,
                      targetMinutes: goalTargetMinutes,
                      ratio: goalRatio,
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(
                      title: 'Continue Learning',
                      actionLabel: 'View All',
                      onActionTap: () => onSelectTab(2),
                    ),
                    const SizedBox(height: 12),
                    _ContinueLearningCard(
                      surah: continueSurah,
                      completion: continueCompletion,
                      currentAyah: continueAyah,
                      onResumeTap: continueSurah == null
                          ? null
                          : () {
                              onSelectTab(2);
                              context.push(
                                '/quiz?surahId=${continueSurah.surahId}&difficulty=easy',
                              );
                            },
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 116,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickActionTile(
                            icon: Icons.menu_book_rounded,
                            title: 'Daily Verse',
                            accent: const Color(0xFF7FB3FF),
                            onTap: () => onSelectTab(1),
                          ),
                          _QuickActionTile(
                            icon: Icons.explore_rounded,
                            title: 'Qibla Finder',
                            accent: TawakkalColors.primary,
                            onTap: () => _showComingSoon(
                              context,
                              featureLabel: 'Qibla Finder',
                            ),
                          ),
                          _QuickActionTile(
                            icon: Icons.mosque_rounded,
                            title: 'Prayer Times',
                            accent: const Color(0xFFB79CFF),
                            onTap: () => _showComingSoon(
                              context,
                              featureLabel: 'Prayer Times',
                            ),
                          ),
                          _QuickActionTile(
                            icon: Icons.volunteer_activism_rounded,
                            title: 'Tasbih',
                            accent: const Color(0xFFFFB175),
                            onTap: () => _showComingSoon(
                              context,
                              featureLabel: 'Tasbih',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Top Reciters'),
                    const SizedBox(height: 10),
                    ..._reciterTiles(
                      context: context,
                      ref: ref,
                      surahs: surahs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _reciterTiles({
    required BuildContext context,
    required WidgetRef ref,
    required List<SurahSummary> surahs,
  }) {
    final topReciterIds = ['05', '03', '01'];

    return topReciterIds.map((reciterId) {
      final reciterName = kReciters[reciterId] ?? 'Reciter';
      final startSurahId = _pickContinueSurah(surahs)?.surahId;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ReciterRow(
          name: reciterName,
          subtitle: reciterId == '05'
              ? 'Trending • 1.2M listeners'
              : reciterId == '03'
              ? 'Recent • Surah Yasin'
              : 'Popular • Murottal Harian',
          onPlay: (surahs.isEmpty || startSurahId == null)
              ? null
              : () {
                  ref
                      .read(audioActionsProvider)
                      .playSurahQueue(
                        surahs: surahs,
                        reciterId: reciterId,
                        reciterName: reciterName,
                        startSurahId: startSurahId,
                      );
                  onSelectTab(3);
                },
        ),
      );
    }).toList();
  }

  SurahSummary? _pickContinueSurah(List<SurahSummary> surahs) {
    if (surahs.isEmpty) {
      return null;
    }
    final mulkCandidates = surahs.where(
      (surah) => surah.nameLatin.toLowerCase().contains('mulk'),
    );
    if (mulkCandidates.isNotEmpty) {
      return mulkCandidates.first;
    }
    return surahs.first;
  }

  void _showComingSoon(BuildContext context, {required String featureLabel}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$featureLabel akan segera hadir.')));
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.streak,
    required this.onNotificationsTap,
  });

  final int streak;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x22000000),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22312D), Color(0xFF162320)],
                ),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            Positioned(
              right: -8,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TawakkalColors.accentGold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? TawakkalColors.backgroundDark
                        : TawakkalColors.backgroundLight,
                    width: 2,
                  ),
                ),
                child: Text(
                  'PRO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TawakkalColors.backgroundDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_rounded),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? TawakkalColors.surfaceDark.withValues(alpha: 0.66)
                    : Colors.white.withValues(alpha: 0.82),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? TawakkalColors.surfaceDark
                        : TawakkalColors.backgroundLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayGoalCard extends StatelessWidget {
  const _TodayGoalCard({
    required this.currentMinutes,
    required this.targetMinutes,
    required this.ratio,
  });

  final int currentMinutes;
  final int targetMinutes;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final safeRatio = ratio.clamp(0.0, 1.0);
    final percent = (safeRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182523), Color(0xFF1E2F2B)],
        ),
        border: Border.all(color: const Color(0x16FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: TawakkalColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -42,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: TawakkalColors.accentGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Today's Goal",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: TawakkalColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                        children: [
                          TextSpan(text: '$currentMinutes'),
                          TextSpan(
                            text: ' / $targetMinutes mins',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: TawakkalColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: safeRatio,
                        minHeight: 7,
                        backgroundColor: const Color(0x22FFFFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          TawakkalColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      percent >= 70
                          ? 'Great job! You are almost there.'
                          : 'Keep going. Every minute builds consistency.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TawakkalColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: safeRatio,
                      strokeWidth: 6,
                      backgroundColor: const Color(0x1FFFFFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        TawakkalColors.primary,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.surah,
    required this.completion,
    required this.currentAyah,
    required this.onResumeTap,
  });

  final SurahSummary? surah;
  final double completion;
  final int currentAyah;
  final VoidCallback? onResumeTap;

  @override
  Widget build(BuildContext context) {
    final safeCompletion = completion.clamp(0, 1).toDouble();
    final completionLabel = '${(safeCompletion * 100).round()}%';

    return Container(
      constraints: const BoxConstraints(minHeight: 226),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2724), Color(0xFF151E1C)],
        ),
        border: Border.all(color: const Color(0x16FFFFFF)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -44,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TawakkalColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xB3111816),
                    Color(0x66111816),
                    Color(0x33111816),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: Text(
                        'IN PROGRESS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x20FFFFFF),
                        border: Border.all(color: const Color(0x1EFFFFFF)),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  surah == null ? 'No Surah yet' : 'Surah ${surah!.nameLatin}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                if (surah != null)
                  Text(
                    surah!.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: TawakkalTypography.arabicLabelStyle(
                      color: TawakkalColors.textSecondary,
                      size: 24,
                      weight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  surah == null
                      ? 'Start your first learning journey.'
                      : '${surah!.meaning} • Ayah $currentAyah',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TawakkalColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                              children: [
                                TextSpan(text: completionLabel),
                                TextSpan(
                                  text: ' Completed',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: TawakkalColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: safeCompletion,
                              minHeight: 8,
                              backgroundColor: const Color(0x22FFFFFF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                TawakkalColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _AvatarStack(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onResumeTap,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Resume'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _miniAvatar(
          context: context,
          initials: 'IM',
          color: const Color(0xFF2D3F3A),
        ),
        Transform.translate(
          offset: const Offset(-8, 0),
          child: _miniAvatar(
            context: context,
            initials: 'YN',
            color: const Color(0xFF2A3632),
          ),
        ),
        Transform.translate(
          offset: const Offset(-16, 0),
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TawakkalColors.surfaceDarkAlt,
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Text(
              '+3',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TawakkalColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniAvatar({
    required BuildContext context,
    required String initials,
    required Color color,
  }) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0x2AFFFFFF)),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 8,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? TawakkalColors.textPrimaryDark
                : TawakkalColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: TawakkalColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 108,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? TawakkalColors.surfaceDark.withValues(alpha: 0.82)
                : TawakkalColors.surfaceLightAlt,
            border: Border.all(
              color: isDark ? const Color(0x16FFFFFF) : const Color(0x12000000),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: subtitleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReciterRow extends StatelessWidget {
  const _ReciterRow({
    required this.name,
    required this.subtitle,
    required this.onPlay,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? TawakkalColors.surfaceDark.withValues(alpha: 0.65)
            : TawakkalColors.surfaceLight,
        border: Border.all(
          color: isDark ? const Color(0x16FFFFFF) : const Color(0x12000000),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TawakkalColors.primary.withValues(alpha: 0.3),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A3834), Color(0xFF17211E)],
              ),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TawakkalColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : TawakkalColors.primary.withValues(alpha: 0.16),
              foregroundColor: isDark
                  ? Colors.white
                  : TawakkalColors.backgroundDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const gap = 42.0;
    for (double y = 16; y < size.height; y += gap) {
      for (double x = 16; x < size.width; x += gap) {
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), paint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
