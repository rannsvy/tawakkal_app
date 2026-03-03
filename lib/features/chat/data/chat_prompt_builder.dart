import '../domain/entities/chat_context.dart';
import '../../quran/domain/entities/surah.dart';

class ChatPromptBuilder {
  static const int _maxAyahContext = 12;
  static const int _maxTafsirContext = 4;

  static ChatContext buildContext(SurahDetail detail) {
    final ayahLines = detail.ayahs
        .take(_maxAyahContext)
        .map(
          (ayah) =>
              '${detail.summary.surahId}:${ayah.ayahNumber} | ${_truncate(ayah.textIndonesian, 220)}',
        )
        .where((line) => line.trim().isNotEmpty)
        .join('\n');

    final tafsirLines = detail.tafsir
        .take(_maxTafsirContext)
        .map(
          (entry) =>
              '${detail.summary.surahId}:${entry.ayahNumber} | ${_truncate(entry.text, 280)}',
        )
        .where((line) => line.trim().isNotEmpty)
        .join('\n');

    return ChatContext(
      surahId: detail.summary.surahId,
      surahName: detail.summary.nameLatin,
      ayahTranslations: ayahLines.isEmpty ? null : ayahLines,
      tafsirSnippets: tafsirLines.isEmpty ? null : tafsirLines,
    );
  }

  static String _truncate(String value, int maxChars) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars)}...';
  }
}
