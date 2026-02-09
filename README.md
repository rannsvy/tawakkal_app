# Tawakkal (توكل)

Mobile Islamic learning app built with Flutter.

## Implemented v1 Foundation
- Quran reading with EQuran v2 integration.
- Ayah details: Arabic, transliteration, Indonesian translation, play audio.
- Ayah bookmark + personal notes (offline SQLite).
- Murottal streaming and offline download by reciter.
- Duolingo-style learning entry and quiz flow (easy/medium/hard).
- AI-quiz-ready architecture with strict prompt contract.
- XP and streak progress tracking.
- Guest mode with optional Supabase auth integration.
- Riverpod + GoRouter modular architecture.

## Tech Stack
- Flutter + Dart
- Riverpod
- GoRouter
- SQLite (`sqflite`)
- Dio
- Supabase Flutter (optional credentials)
- just_audio

## Environment Configuration
Run with Supabase enabled:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Optional AI endpoint:

```bash
flutter run --dart-define=AI_QUIZ_ENDPOINT=https://your-edge-function-url
```

Deploy the quiz function:

```bash
supabase functions deploy quiz-generate --project-ref YOUR_PROJECT_REF
```

Function source:
- `supabase/functions/quiz-generate/index.ts`

Without those values, app runs in guest/offline-first mode.

## Key Project Paths
- App shell + theme + router: `lib/app/`
- Core config/network/storage: `lib/core/`
- Feature modules: `lib/features/`
- Shared widgets: `lib/shared/`
- Supabase migration: `supabase/migrations/20260209_tawakkal_init.sql`
- AI prompt contract: `docs/ai/quiz_prompt_contract.md`
- EQuran integration notes: `docs/integration/equran_v2.md`

## Validation
- `flutter analyze` passes.
- `flutter test` passes.
