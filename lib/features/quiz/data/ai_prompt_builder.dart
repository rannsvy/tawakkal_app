import '../../learning/domain/entities/difficulty.dart';
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
      Difficulty.easy => 5,
      Difficulty.medium => 7,
      Difficulty.hard => 8,
    };

    final ayahContext = surah.ayahs
        .map(
          (ayah) =>
              '${surah.summary.surahId}:${ayah.ayahNumber} | ${ayah.textIndonesian}',
        )
        .join('\n');

    final tafsirContext = surah.tafsir
        .take(8)
        .map(
          (entry) =>
              '${surah.summary.surahId}:${entry.ayahNumber} | ${entry.text}',
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
id, type, prompt, ayah_refs, choices, correct_choice_id, explanation, feedback{correct,incorrect}, grounding_refs.
Grounding refs must cite only provided ayah translations or tafsir snippets.

Number of questions: $maxQuestions.
No Arabic alteration. No unsupported claims.

Ayah translations:
$ayahContext

Tafsir context:
$tafsirContext
''';
  }
}
