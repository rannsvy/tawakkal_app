import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/reciters.dart';
import '../../../../shared/widgets/async_state_view.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../../../shared/widgets/rich_page_background.dart';
import '../../../../shared/widgets/rich_section_title.dart';
import '../../../quran/domain/entities/surah.dart';
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
  bool _isQariExpanded = false;
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
    final reciterName = kReciters[_selectedReciter] ?? 'Murottal';

    return RichPageBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _AudioHeroCard(
              selectedReciter: _selectedReciter,
              downloadedCount: downloadedIds.length,
              isExpanded: _isQariExpanded,
              onToggleExpanded: () {
                setState(() {
                  _isQariExpanded = !_isQariExpanded;
                });
              },
              onReciterChanged: (value) {
                setState(() {
                  _selectedReciter = value;
                  _isQariExpanded = false;
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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

                    return _AudioSurahTile(
                      surah: surah,
                      reciterName: reciterName,
                      isDownloaded: isDownloaded,
                      isDownloading: isDownloading,
                      isRemoving: isRemoving,
                      progress: progress,
                      onPlay: url == null
                          ? null
                          : () {
                              ref
                                  .read(audioActionsProvider)
                                  .playSurahQueue(
                                    surahs: surahs,
                                    reciterId: _selectedReciter,
                                    reciterName: reciterName,
                                    startSurahId: surah.surahId,
                                  );
                            },
                      onDownloadTap: isDownloaded
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
                      onDownloadLongPress:
                          isDownloaded && !isDownloading && !isRemoving
                          ? () => _confirmRemoveDownload(
                              surahId: surah.surahId,
                              surahName: surah.nameLatin,
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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

class _AudioHeroCard extends StatelessWidget {
  const _AudioHeroCard({
    required this.selectedReciter,
    required this.downloadedCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onReciterChanged,
  });

  final String selectedReciter;
  final int downloadedCount;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onReciterChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTextColor = isDark
        ? Colors.white
        : TawakkalColors.primaryDark;
    final qariEntries = kReciters.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionTitle(title: 'Audio Murottal'),
        const SizedBox(height: 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.multitrack_audio_rounded,
                    color: TawakkalColors.accentGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih qari favorit untuk didengarkan',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark
                            ? TawakkalColors.textPrimaryDark
                            : TawakkalColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : TawakkalColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$downloadedCount offline',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? TawakkalColors.textSecondary
                            : TawakkalColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onToggleExpanded,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0x1DFFFFFF)
                          : Colors.white.withValues(alpha: 0.86),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x25FFFFFF)
                            : const Color(0x17000000),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over_rounded,
                          color: TawakkalColors.accentGold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qari',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isDark
                                          ? TawakkalColors.textSecondary
                                          : TawakkalColors.textPrimaryLight
                                                .withValues(alpha: 0.66),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                kReciters[selectedReciter] ?? selectedReciter,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: selectedTextColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark
                                ? TawakkalColors.textPrimaryDark
                                : TawakkalColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: isExpanded
                    ? Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? TawakkalColors.surfaceDarkAlt
                              : TawakkalColors.surfaceLight,
                          border: Border.all(
                            color: isDark
                                ? const Color(0x22FFFFFF)
                                : const Color(0x12000000),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.08,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: qariEntries.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark
                                  ? const Color(0x1DFFFFFF)
                                  : const Color(0x0F000000),
                            ),
                            itemBuilder: (context, index) {
                              final entry = qariEntries[index];
                              final selected = selectedReciter == entry.key;
                              final itemTextColor = isDark
                                  ? Colors.white
                                  : TawakkalColors.textPrimaryLight;

                              return Material(
                                color: selected
                                    ? TawakkalColors.primary.withValues(
                                        alpha: isDark ? 0.22 : 0.16,
                                      )
                                    : Colors.transparent,
                                child: InkWell(
                                  onTap: () => onReciterChanged(entry.key),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              FadeTransition(
                                                opacity: anim,
                                                child: ScaleTransition(
                                                  scale: anim,
                                                  child: child,
                                                ),
                                              ),
                                          child: selected
                                              ? const Icon(
                                                  Icons.check_circle_rounded,
                                                  key: ValueKey('selected'),
                                                  size: 18,
                                                  color: TawakkalColors.primary,
                                                )
                                              : Icon(
                                                  Icons.circle_outlined,
                                                  key: const ValueKey(
                                                    'unselected',
                                                  ),
                                                  size: 18,
                                                  color: isDark
                                                      ? const Color(0x44FFFFFF)
                                                      : const Color(0x33000000),
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: itemTextColor,
                                                  fontWeight: selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudioSurahTile extends StatelessWidget {
  const _AudioSurahTile({
    required this.surah,
    required this.reciterName,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isRemoving,
    required this.progress,
    required this.onPlay,
    required this.onDownloadTap,
    this.onDownloadLongPress,
  });

  final SurahSummary surah;
  final String reciterName;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isRemoving;
  final double progress;
  final VoidCallback? onPlay;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onDownloadLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.64);

    return RichInfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: onPlay,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TawakkalColors.primary.withValues(
                alpha: isDark ? 0.22 : 0.14,
              ),
              border: Border.all(
                color: TawakkalColors.primary.withValues(
                  alpha: isDark ? 0.4 : 0.24,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${surah.surahId}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TawakkalColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.nameLatin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TawakkalTypography.arabicLabelStyle(
                    color: subtitleColor,
                    size: 20,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$reciterName - ${surah.ayahCount} ayat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Putar',
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            color: TawakkalColors.primary,
          ),
          AudioDownloadButton(
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            isRemoving: isRemoving,
            progress: progress,
            onPressed: onDownloadTap,
            onLongPress: onDownloadLongPress,
          ),
        ],
      ),
    );
  }
}
