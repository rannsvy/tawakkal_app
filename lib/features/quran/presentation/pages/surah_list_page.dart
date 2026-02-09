import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_state_view.dart';
import '../providers/quran_providers.dart';

class SurahListPage extends ConsumerWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahListProvider);

    return RefreshIndicator(
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
              return Card(
                child: ListTile(
                  minTileHeight: 72,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  onTap: () => context.push('/surah/${surah.surahId}'),
                  leading: CircleAvatar(child: Text('${surah.surahId}')),
                  title: Text(surah.nameLatin),
                  subtitle: Text(
                    '${surah.revelationPlace} • ${surah.ayahCount} ayat',
                  ),
                  trailing: Text(
                    surah.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
