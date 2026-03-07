import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../domain/entities/profile_overview.dart';
import '../../domain/entities/reward_milestone.dart';
import '../providers/profile_overview_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(profileOverviewProvider);

    return RichPageBackground(
      child: AsyncStateView(
        value: overviewState,
        onRetry: () {
          ref.invalidate(profileOverviewProvider);
        },
        builder: (overview) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 14),
              _ProfileIdentityCard(
                overview: overview,
                onSignOut: () => _handleSignOut(context, ref),
              ),
              const SizedBox(height: 18),
              const _ProfileSectionLabel('PROGRES SAAT INI'),
              const SizedBox(height: 8),
              _CurrentProgressCard(overview: overview),
              const SizedBox(height: 18),
              const _ProfileSectionLabel('PENCAPAIAN IBADAH'),
              const SizedBox(height: 10),
              _RewardGrid(rewards: overview.rewards),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!context.mounted) {
        return;
      }
      context.go('/auth');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('Gagal sign out: $error')));
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 28,
          color: isDark ? TawakkalColors.textSecondary : TawakkalColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          'PROFIL SAYA',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 0.4,
            fontWeight: FontWeight.w800,
            color: isDark
                ? TawakkalColors.textPrimaryDark
                : TawakkalColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.overview, required this.onSignOut});

  final ProfileOverview overview;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.62);

    return RichInfoCard(
      borderRadius: 24,
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF182523), Color(0xFF1F302C)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F6F4)],
            ),
      child: Row(
        children: [
          _AvatarBadge(name: overview.displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? TawakkalColors.textPrimaryDark
                        : TawakkalColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  overview.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.trending_up_rounded,
                      label: 'Level ${overview.level}',
                    ),
                    _InfoPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${overview.currentStreak} Hari',
                    ),
                    if (overview.isGuest)
                      const _InfoPill(
                        icon: Icons.lock_outline_rounded,
                        label: 'Guest',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('profile-signout-button'),
                    onPressed: () {
                      onSignOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? TawakkalColors.textPrimaryDark
                          : TawakkalColors.primaryDark,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0x26FFFFFF)
                            : TawakkalColors.primary.withValues(alpha: 0.34),
                      ),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.68),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TawakkalColors.primary, TawakkalColors.primaryDark],
        ),
        border: Border.all(
          color: isDark ? const Color(0x30FFFFFF) : const Color(0x11000000),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: TawakkalColors.backgroundDark,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? TawakkalColors.textSecondary
                : TawakkalColors.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
        color: isDark ? TawakkalColors.textSecondary : const Color(0xFF5A6A66),
      ),
    );
  }
}

class _CurrentProgressCard extends StatelessWidget {
  const _CurrentProgressCard({required this.overview});

  final ProfileOverview overview;

  @override
  Widget build(BuildContext context) {
    return RichInfoCard(
      borderRadius: 22,
      child: Column(
        children: [
          _ProgressRow(
            label: 'Hari beruntun',
            value: '${overview.currentStreak} hari',
          ),
          const SizedBox(height: 12),
          _ProgressRow(label: 'Pengalaman', value: '${overview.xpTotal} poin'),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Tasbih hari ini',
            value: '${overview.tasbihTodayCycles} sesi',
            highlight: true,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Kuis selesai',
            value: '${overview.completedQuizUnits} unit',
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = highlight
        ? TawakkalColors.accentGold
        : (isDark
              ? TawakkalColors.textPrimaryDark
              : TawakkalColors.textPrimaryLight);

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? TawakkalColors.textSecondary
                : TawakkalColors.textPrimaryLight.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _RewardGrid extends StatelessWidget {
  const _RewardGrid({required this.rewards});

  final List<RewardMilestone> rewards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: rewards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return _RewardCard(
          key: ValueKey('reward-${reward.code}'),
          reward: reward,
          onTap: () => _showRewardDetails(context, reward),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({super.key, required this.reward, required this.onTap});

  final RewardMilestone reward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _rewardColor(reward.kind);

    return RichInfoCard(
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(
                  alpha: reward.isUnlocked ? 0.85 : 0.25,
                ),
                width: 1.5,
              ),
              color: reward.isUnlocked
                  ? accentColor.withValues(alpha: isDark ? 0.14 : 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03)),
            ),
            child: Icon(
              _rewardIcon(reward.kind),
              color: reward.isUnlocked
                  ? accentColor
                  : (isDark
                        ? TawakkalColors.textSecondary
                        : const Color(0xFF9AA3A0)),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reward.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: reward.isUnlocked
                  ? accentColor.withValues(alpha: isDark ? 0.2 : 0.18)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              reward.progressText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: reward.isUnlocked
                    ? accentColor
                    : (isDark
                          ? TawakkalColors.textSecondary
                          : TawakkalColors.textPrimaryLight.withValues(
                              alpha: 0.66,
                            )),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showRewardDetails(BuildContext context, RewardMilestone reward) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accentColor = _rewardColor(reward.kind);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: isDark
        ? TawakkalColors.surfaceDark
        : TawakkalColors.surfaceLight,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.14),
                  ),
                  child: Icon(_rewardIcon(reward.kind), color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reward.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reward.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? TawakkalColors.textSecondary
                    : TawakkalColors.textPrimaryLight.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: reward.progress,
                minHeight: 8,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Progres: ${reward.progressText}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              reward.isUnlocked ? 'Status: Tercapai' : 'Status: Dalam proses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: reward.isUnlocked
                    ? TawakkalColors.success
                    : TawakkalColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    },
  );
}

IconData _rewardIcon(RewardMilestoneKind kind) {
  switch (kind) {
    case RewardMilestoneKind.streak:
      return Icons.local_fire_department_rounded;
    case RewardMilestoneKind.xp:
      return Icons.auto_awesome_rounded;
    case RewardMilestoneKind.tasbih:
      return Icons.grain_rounded;
    case RewardMilestoneKind.quiz:
      return Icons.menu_book_rounded;
  }
}

Color _rewardColor(RewardMilestoneKind kind) {
  switch (kind) {
    case RewardMilestoneKind.streak:
      return const Color(0xFFE07A29);
    case RewardMilestoneKind.xp:
      return TawakkalColors.primary;
    case RewardMilestoneKind.tasbih:
      return TawakkalColors.accentGold;
    case RewardMilestoneKind.quiz:
      return const Color(0xFF4E84D8);
  }
}

String _buildInitials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return 'TA';
  }
  if (words.length == 1) {
    final word = words.first;
    final end = word.length >= 2 ? 2 : word.length;
    return word.substring(0, end).toUpperCase();
  }
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
}
