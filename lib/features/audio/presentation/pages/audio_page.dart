import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/reciters.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../providers/audio_providers.dart';
import '../widgets/audio_download_button.dart';

class AudioPage extends ConsumerStatefulWidget {
  const AudioPage({super.key});

  @override
  ConsumerState<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends ConsumerState<AudioPage> {
  late String _selectedReciter;
  final Map<int, double> _downloadProgress = <int, double>{};
  final Set<int> _downloading = <int>{};
  final Set<int> _removing = <int>{};

  @override
  void initState() {
    super.initState();
    _selectedReciter = AppConfig.fallbackReciterKey;
  }

  @override
  Widget build(BuildContext context) {
    final surahsState = ref.watch(surahListProvider);
    final downloadedIds =
        ref.watch(downloadedSurahIdsProvider(_selectedReciter)).asData?.value ??
        const <int>{};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedReciter,
            decoration: const InputDecoration(labelText: 'Qari'),
            items: kReciters.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedReciter = value;
                _downloadProgress.clear();
                _downloading.clear();
                _removing.clear();
              });
            },
          ),
        ),
        Expanded(
          child: AsyncStateView(
            value: surahsState,
            onRetry: () => ref.invalidate(surahListProvider),
            builder: (surahs) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: surahs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  final url = surah.audioFull[_selectedReciter];
                  final isDownloaded = downloadedIds.contains(surah.surahId);
                  final isDownloading = _downloading.contains(surah.surahId);
                  final isRemoving = _removing.contains(surah.surahId);
                  final progress = _downloadProgress[surah.surahId] ?? 0;

                  return Card(
                    child: ListTile(
                      minTileHeight: 72,
                      title: Text(surah.nameLatin),
                      subtitle: Text(
                        '${kReciters[_selectedReciter]} - ${surah.ayahCount} ayat',
                      ),
                      trailing: Wrap(
                        spacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Putar',
                            onPressed: url == null
                                ? null
                                : () {
                                    ref
                                        .read(audioActionsProvider)
                                        .playSurahQueue(
                                          surahs: surahs,
                                          reciterId: _selectedReciter,
                                          reciterName:
                                              kReciters[_selectedReciter] ??
                                              'Murottal',
                                          startSurahId: surah.surahId,
                                        );
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                          AudioDownloadButton(
                            isDownloaded: isDownloaded,
                            isDownloading: isDownloading,
                            isRemoving: isRemoving,
                            progress: progress,
                            onPressed: isDownloaded
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Audio tersimpan offline. Tekan lama untuk hapus.',
                                        ),
                                      ),
                                    );
                                  }
                                : (url == null || isDownloading || isRemoving
                                      ? null
                                      : () => _downloadSurah(
                                          context: context,
                                          surahId: surah.surahId,
                                          surahName: surah.nameLatin,
                                          url: url,
                                        )),
                            onLongPress:
                                isDownloaded && !isDownloading && !isRemoving
                                ? () => _confirmRemoveDownload(
                                    surahId: surah.surahId,
                                    surahName: surah.nameLatin,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemoveDownload({
    required int surahId,
    required String surahName,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Audio Offline'),
          content: Text('Hapus "$surahName" dari perangkat?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _removing.add(surahId);
    });

    try {
      await ref
          .read(audioActionsProvider)
          .removeDownload(reciterId: _selectedReciter, surahId: surahId);
      if (!mounted) {
        return;
      }
      setState(() {
        _removing.remove(surahId);
      });
      ref.invalidate(downloadedSurahIdsProvider(_selectedReciter));
      messenger.showSnackBar(
        SnackBar(content: Text('$surahName dihapus dari offline.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _removing.remove(surahId);
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus audio: $error')),
      );
    }
  }

  Future<void> _downloadSurah({
    required BuildContext context,
    required int surahId,
    required String surahName,
    required String url,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _downloading.add(surahId);
      _downloadProgress[surahId] = 0;
    });

    try {
      await ref
          .read(audioActionsProvider)
          .downloadSurah(
            reciterId: _selectedReciter,
            surahId: surahId,
            url: url,
            onProgress: (received, total) {
              if (!mounted) {
                return;
              }
              final progress = total > 0 ? (received / total) : 0.0;
              setState(() {
                _downloadProgress[surahId] = progress;
              });
            },
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _downloading.remove(surahId);
        _downloadProgress.remove(surahId);
      });
      ref.invalidate(downloadedSurahIdsProvider(_selectedReciter));
      messenger.showSnackBar(
        SnackBar(
          content: Text('$surahName tersimpan untuk offline di perangkat.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _downloading.remove(surahId);
        _downloadProgress.remove(surahId);
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengunduh audio: $error')),
      );
    }
  }
}
