import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: TawakkalColors.primary.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
              border: Border.all(
                color: TawakkalColors.primary.withValues(
                  alpha: isDark ? 0.38 : 0.28,
                ),
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              color: isDark
                  ? TawakkalColors.primary
                  : TawakkalColors.primaryDark,
            ),
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
                backgroundColor: isDark
                    ? const Color(0x22FFFFFF)
                    : const Color(0x22000000),
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

    return Tooltip(
      message: 'Unduh offline',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
            border: Border.all(
              color: isDark ? const Color(0x24FFFFFF) : const Color(0x12000000),
            ),
          ),
          child: const Icon(Icons.download_for_offline_outlined),
        ),
      ),
    );
  }
}
