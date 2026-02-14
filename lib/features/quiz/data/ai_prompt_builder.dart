import '../../learning/domain/entities/difficulty.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/domain/entities/surah.dart';

class AiPromptBuilder {
  static const String systemInstruction = '''
You are an Islamic learning assistant for Tawakkal.
Never modify or rewrite Arabic Quran text.
Only generate educational questions using the provided translation and tafsir context.
Respond with valid JSON only.
Keep tone respectful and gentle.
''';

  static String buildQuizPrompt({
    required SurahDetail surah,
    required Difficulty difficulty,
    required String language,
  }) {
    final maxQuestions = switch (difficulty) {
      Difficulty.easy => 3,
      Difficulty.medium => 5,
      Difficulty.hard => 6,
    };

    final maxAyahContext = switch (difficulty) {
      Difficulty.easy => 14,
      Difficulty.medium => 20,
      Difficulty.hard => 26,
    };
    final maxTafsirContext = switch (difficulty) {
      Difficulty.easy => 4,
      Difficulty.medium => 5,
      Difficulty.hard => 6,
    };

    final ayahContext =
        _selectAyahContext(ayahs: surah.ayahs, maxItems: maxAyahContext)
            .map(
              (ayah) =>
                  '${surah.summary.surahId}:${ayah.ayahNumber} | ${_truncate(ayah.textIndonesian, 220)}',
            )
            .join('\n');

    final tafsirContext = surah.tafsir
        .take(maxTafsirContext)
        .map(
          (entry) =>
              '${surah.summary.surahId}:${entry.ayahNumber} | ${_truncate(entry.text, 280)}',
        )
        .join('\n');

    return '''
Generate a ${difficulty.name} Quran quiz in language "$language" for surah ${surah.summary.nameLatin}.
Return strict JSON with keys:
quiz_id, surah_id, surah_name, difficulty, language, version, questions, scoring.

Question types allowed:
- multiple_choice
- matching
- ordering
- reflection

Each question must include:
id, type, prompt, ayah_refs, choices, correct_choice_id, correct_choice_text, explanation, feedback{correct,incorrect}, grounding_refs.
Grounding refs must cite only provided ayah translations or tafsir snippets.
`correct_choice_text` must match exactly the text of the option referenced by `correct_choice_id`.

Number of questions: exactly $maxQuestions.
Each question must have exactly 4 choices.
Keep explanation concise (max 1-2 short sentences).
Keep feedback concise (max 1 short sentence each for correct/incorrect).
Keep explanation <= 180 characters.
Keep each feedback field <= 120 characters.
No Arabic alteration. No unsupported claims.

Ayah translations:
$ayahContext

Tafsir context:
$tafsirContext
''';
  }

  static List<Ayah> _selectAyahContext({
    required List<Ayah> ayahs,
    required int maxItems,
  }) {
    if (ayahs.length <= maxItems) {
      return ayahs;
    }

    final selected = <Ayah>[];
    final headCount = (maxItems * 0.5).floor();
    final middleCount = (maxItems * 0.25).floor();
    final tailCount = maxItems - headCount - middleCount;

    selected.addAll(ayahs.take(headCount));
    if (middleCount > 0) {
      final start = ((ayahs.length - middleCount) / 2).floor();
      selected.addAll(ayahs.skip(start).take(middleCount));
    }
    selected.addAll(ayahs.skip(ayahs.length - tailCount));

    final deduped = <Ayah>[];
    final seen = <int>{};
    for (final ayah in selected) {
      if (seen.add(ayah.ayahNumber)) {
        deduped.add(ayah);
      }
    }
    return deduped;
  }

  static String _truncate(String value, int maxChars) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars)}...';
  }
}
