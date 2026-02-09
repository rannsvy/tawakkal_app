import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/reciters.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_card.dart';

class SurahDetailPage extends ConsumerWidget {
  const SurahDetailPage({super.key, required this.surahId});

  static const routeName = 'surah-detail';
  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(surahDetailProvider(surahId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Surah')),
      body: AsyncStateView(
        value: detailState,
        onRetry: () => ref.invalidate(surahDetailProvider(surahId)),
        builder: (detail) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        detail.summary.nameArabic,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail.summary.nameLatin,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${detail.summary.revelationPlace} • ${detail.summary.ayahCount} ayat',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(detail.summary.descriptionId),
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
              ),
              const SizedBox(height: 14),
              ...detail.ayahs.map(
                (ayah) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AyahCard(
                    ayah: ayah,
                    onPlayPressed: () {
                      final url = ayah.audioUrls[AppConfig.fallbackReciterKey];
                      if (url == null) {
                        return;
                      }
                      ref
                          .read(audioActionsProvider)
                          .playUrl(
                            url: url,
                            title:
                                '${detail.summary.nameLatin} • Ayat ${ayah.ayahNumber}',
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
    );
  }
}
