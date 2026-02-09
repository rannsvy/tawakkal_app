import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../../shared/widgets/rich_section_title.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../progress/presentation/widgets/progress_header_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final isGuest = user?.isGuest ?? true;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : 'Sahabat Tawakkal';
    final email = user?.email ?? 'Belum terhubung';
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
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : TawakkalColors.primary.withValues(alpha: 0.14),
                    border: Border.all(
                      color: TawakkalColors.primary.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: isDark
                        ? TawakkalColors.textPrimaryDark
                        : TawakkalColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? TawakkalColors.textSecondary
                              : TawakkalColors.textPrimaryLight.withValues(
                                  alpha: 0.68,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : TawakkalColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isGuest ? 'Guest Mode' : 'Akun Terautentikasi',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? TawakkalColors.textSecondary
                                    : TawakkalColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const RichSectionTitle(title: 'Progress Ibadah Belajar'),
          const SizedBox(height: 8),
          const ProgressHeaderCard(),
          const SizedBox(height: 14),
          const RichSectionTitle(title: 'Informasi Akun'),
          const SizedBox(height: 8),
          RichInfoCard(
            child: Column(
              children: [
                _ProfileInfoRow(label: 'Nama', value: displayName),
                const Divider(height: 20),
                _ProfileInfoRow(
                  label: 'Status',
                  value: isGuest ? 'Guest' : 'Terautentikasi',
                ),
                const Divider(height: 20),
                _ProfileInfoRow(label: 'Email', value: email),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
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

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? TawakkalColors.textSecondary
                : TawakkalColors.textPrimaryLight.withValues(alpha: 0.68),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? TawakkalColors.textPrimaryDark
                  : TawakkalColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
