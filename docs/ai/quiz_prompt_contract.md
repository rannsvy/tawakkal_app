# Tawakkal AI Quiz Prompt Contract

## System Rules
- Never modify or rewrite Arabic Quran text.
- Use only provided grounding materials (translation, tafsir, surah metadata).
- Return strict JSON only, no markdown.
- Keep explanations respectful and educational.

## Required Output Keys
- `quiz_id`
- `surah_id`
- `surah_name`
- `difficulty` (`easy|medium|hard`)
- `language` (`id|en`)
- `version`
- `questions[]`
- `scoring`

## Question Item Schema
- `id`
- `type` (`multiple_choice|matching|ordering|reflection`)
- `prompt`
- `ayah_refs[]`
- `choices[]` with `{id,text}`
- `correct_choice_id`
- `explanation`
- `feedback` with `correct` and `incorrect`
- `grounding_refs[]` with `{type,ref}`

## Safety Validation
- Reject payload if Arabic appears altered.
- Reject payload if required keys are missing.
- Reject payload if references do not map to known grounding.
- Regenerate on invalid payload.

