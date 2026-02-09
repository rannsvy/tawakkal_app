import 'package:flutter/material.dart';

class AudioDownloadButton extends StatelessWidget {
  const AudioDownloadButton({
    super.key,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isRemoving,
    required this.progress,
    required this.onPressed,
    this.onLongPress,
  });

  final bool isDownloaded;
  final bool isDownloading;
  final bool isRemoving;
  final double progress;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (isRemoving) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    if (isDownloaded && !isDownloading) {
      return Tooltip(
        message: 'Tersimpan offline. Tekan lama untuk hapus.',
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x132E7D6D),
              border: Border.all(color: const Color(0x332E7D6D)),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D6D)),
          ),
        ),
      );
    }

    if (isDownloading) {
      final safeProgress = progress.clamp(0, 1).toDouble();
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: safeProgress,
                strokeWidth: 2.6,
                backgroundColor: const Color(0x22000000),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Icon(
              safeProgress >= 1
                  ? Icons.check_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    }

    return IconButton(
      tooltip: 'Unduh offline',
      onPressed: onPressed,
      icon: const Icon(Icons.download_for_offline_outlined),
    );
  }
}
