import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/widgets/rich_info_card.dart';
import '../../domain/entities/ayah.dart';
import '../providers/quran_providers.dart';

class AyahCard extends ConsumerWidget {
  const AyahCard({super.key, required this.ayah, required this.onPlayPressed});

  final Ayah ayah;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locator = AyahLocator(ayah.surahId, ayah.ayahNumber);
    final bookmarkState = ref.watch(ayahBookmarkProvider(locator));
    final noteState = ref.watch(ayahNoteProvider(locator));
    final note = noteState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? TawakkalColors.textPrimaryDark
        : TawakkalColors.textPrimaryLight;
    final subtitleColor = isDark
        ? TawakkalColors.textSecondary
        : TawakkalColors.textPrimaryLight.withValues(alpha: 0.7);

    return RichInfoCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TawakkalColors.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: TawakkalColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${ayah.ayahNumber}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TawakkalColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Putar audio ayat',
                onPressed: onPlayPressed,
                icon: const Icon(Icons.play_circle_outline),
                color: TawakkalColors.primary,
              ),
              IconButton(
                tooltip: 'Simpan bookmark ayat',
                onPressed: bookmarkState.value == null
                    ? null
                    : () {
                        ref
                            .read(quranActionsProvider)
                            .toggleBookmark(
                              surahId: ayah.surahId,
                              ayahNumber: ayah.ayahNumber,
                              bookmarked: !(bookmarkState.value ?? false),
                            );
                      },
                icon: Icon(
                  (bookmarkState.value ?? false)
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                ),
                color: (bookmarkState.value ?? false)
                    ? TawakkalColors.accentGold
                    : subtitleColor,
              ),
              IconButton(
                tooltip: 'Tambahkan catatan',
                onPressed: () => _showNoteEditor(context, ref, noteState.value),
                icon: const Icon(Icons.note_alt_outlined),
                color: subtitleColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ayah.textArabic,
            textAlign: TextAlign.right,
            style: TawakkalTypography.arabicStyle(
              color: isDark ? Colors.white : TawakkalColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayah.textLatin,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: 8),
          Text(
            ayah.textIndonesian,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: titleColor),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x1AFFFFFF)
                    : const Color(0x0F000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0x1EFFFFFF)
                      : const Color(0x10000000),
                ),
              ),
              child: Text(
                note,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showNoteEditor(
    BuildContext context,
    WidgetRef ref,
    String? currentNote,
  ) async {
    final controller = TextEditingController(text: currentNote ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Catatan ayat',
                  hintText: 'Tulis refleksi atau poin belajar Anda',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(quranActionsProvider)
                        .saveNote(
                          surahId: ayah.surahId,
                          ayahNumber: ayah.ayahNumber,
                          note: controller.text.trim(),
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Simpan catatan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
