import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/async_state_view.dart';
import '../providers/progress_providers.dart';

class ProgressHeaderCard extends ConsumerWidget {
  const ProgressHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(progressSnapshotProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AsyncStateView(
          value: progressState,
          builder: (snapshot) {
            final progressInLevel = snapshot.xpTotal % 120;
            final value = (progressInLevel / 120).clamp(0, 1).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Level ${snapshot.level}'),
                    const Spacer(),
                    Text('XP ${snapshot.xpTotal}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: value),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Streak: ${snapshot.currentStreak} hari'),
                    const Spacer(),
                    Text('Terpanjang: ${snapshot.longestStreak}'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
