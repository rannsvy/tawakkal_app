import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/typography.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('${ayah.ayahNumber}')),
                const Spacer(),
                IconButton(
                  tooltip: 'Putar audio ayat',
                  onPressed: onPlayPressed,
                  icon: const Icon(Icons.play_circle_outline),
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
                ),
                IconButton(
                  tooltip: 'Tambahkan catatan',
                  onPressed: () =>
                      _showNoteEditor(context, ref, noteState.value),
                  icon: const Icon(Icons.note_alt_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ayah.textArabic,
              textAlign: TextAlign.right,
              style: TawakkalTypography.arabicStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(ayah.textLatin, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              ayah.textIndonesian,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(note, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
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
