import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../app/theme/colors.dart';
import '../providers/audio_providers.dart';

class PersistentMiniPlayer extends ConsumerWidget {
  const PersistentMiniPlayer({super.key, this.onOpenPlayer});

  final VoidCallback? onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(audioCurrentTrackProvider);
    if (track == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final playerState = ref.watch(audioPlayerStateProvider).asData?.value;
    final isPlaying = playerState?.playing ?? false;
    final currentIndex = ref.watch(audioCurrentIndexProvider).asData?.value;
    final queue = ref.watch(audioQueueProvider);
    final hasPrevious = currentIndex != null && currentIndex > 0;
    final hasNext = currentIndex != null && currentIndex < queue.length - 1;
    final loopMode =
        ref.watch(audioLoopModeProvider).asData?.value ?? LoopMode.off;
    final position =
        ref.watch(audioPositionProvider).asData?.value ?? Duration.zero;
    final duration =
        ref.watch(audioDurationProvider).asData?.value ?? Duration.zero;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble();

    final backgroundGradient = isDark
        ? const [Color(0xFF15221F), Color(0xFF1C2F29)]
        : const [Color(0xFFEEF5F2), Color(0xFFE4F0EC)];
    final foreground = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtleForeground = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.62);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenPlayer,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundGradient,
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0x18FFFFFF)
                    : const Color(0x14000000),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isDark
                              ? const Color(0x22FFFFFF)
                              : TawakkalColors.primary.withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: isDark
                              ? TawakkalColors.textPrimaryDark
                              : TawakkalColors.primaryDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              track.artist ?? 'Murottal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtleForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: hasPrevious
                            ? () {
                                ref.read(audioActionsProvider).previous();
                              }
                            : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: foreground,
                        iconSize: 24,
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(audioActionsProvider).togglePlayPause();
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                        ),
                        color: TawakkalColors.primary,
                        iconSize: 32,
                      ),
                      IconButton(
                        onPressed: hasNext
                            ? () {
                                ref.read(audioActionsProvider).next();
                              }
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                        color: foreground,
                        iconSize: 24,
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(audioActionsProvider)
                              .setRepeatOne(loopMode != LoopMode.one);
                        },
                        icon: Icon(
                          Icons.repeat_one_rounded,
                          color: loopMode == LoopMode.one
                              ? TawakkalColors.primary
                              : subtleForeground,
                        ),
                        iconSize: 22,
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: progress,
                    backgroundColor: isDark
                        ? const Color(0x1FFFFFFF)
                        : const Color(0x16000000),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      TawakkalColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
