import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../providers/tasbih_providers.dart';

class TasbihPage extends ConsumerWidget {
  const TasbihPage({super.key});

  static const routeName = 'tasbih-page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateValue = ref.watch(tasbihStateProvider);
    final historyValue = ref.watch(tasbihHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih')),
      body: RichPageBackground(
        child: AsyncStateView(
          value: stateValue,
          onRetry: () => ref.invalidate(tasbihStateProvider),
          builder: (state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                RichInfoCard(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Text(
                        'Target ${state.target}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.count}',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: TawakkalColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: TawakkalColors.primary,
                            foregroundColor: TawakkalColors.backgroundDark,
                          ),
                          onPressed: () {
                            ref.read(tasbihStateProvider.notifier).increment();
                          },
                          child: const Icon(Icons.touch_app_rounded, size: 56),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Siklus hari ini: ${state.todayCycles}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: TawakkalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichInfoCard(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preset Target',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TargetChip(
                            label: '33',
                            selected: state.target == 33,
                            isDark: isDark,
                            onTap: () => ref
                                .read(tasbihStateProvider.notifier)
                                .setTarget(33),
                          ),
                          _TargetChip(
                            label: '99',
                            selected: state.target == 99,
                            isDark: isDark,
                            onTap: () => ref
                                .read(tasbihStateProvider.notifier)
                                .setTarget(99),
                          ),
                          _TargetChip(
                            label: '100',
                            selected: state.target == 100,
                            isDark: isDark,
                            onTap: () => ref
                                .read(tasbihStateProvider.notifier)
                                .setTarget(100),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              final custom = await _showCustomTargetDialog(
                                context,
                              );
                              if (custom == null) {
                                return;
                              }
                              await ref
                                  .read(tasbihStateProvider.notifier)
                                  .setTarget(custom);
                            },
                            child: const Text('Custom'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(tasbihStateProvider.notifier)
                                .resetCount(),
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Reset Hitungan'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(tasbihStateProvider.notifier)
                                .resetDailyCycles(),
                            icon: const Icon(Icons.history_toggle_off_rounded),
                            label: const Text('Reset Siklus Harian'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichInfoCard(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Hari Ini',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      historyValue.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return Text(
                              'Belum ada siklus yang selesai hari ini.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: TawakkalColors.textSecondary,
                                  ),
                            );
                          }
                          return Column(
                            children: items
                                .map((item) {
                                  final hour = item.completedAt.hour
                                      .toString()
                                      .padLeft(2, '0');
                                  final minute = item.completedAt.minute
                                      .toString()
                                      .padLeft(2, '0');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$hour:$minute',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                        Text(
                                          'Target ${item.target}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: TawakkalColors
                                                    .textSecondary,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.finalCount}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: TawakkalColors.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          );
                        },
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (_, _) => Text(
                          'Riwayat tidak tersedia.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: TawakkalColors.textSecondary),
                        ),
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

  Future<int?> _showCustomTargetDialog(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Target Custom'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Masukkan angka target',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: TawakkalColors.primary.withValues(alpha: 0.2),
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
            : (isDark ? const Color(0x26FFFFFF) : const Color(0x25000000)),
      ),
    );
  }
}
