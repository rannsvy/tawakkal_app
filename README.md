# Tawakkal App

Tawakkal is a Flutter mobile app for Quran learning with an offline-first architecture. Core flows work in guest mode, and cloud features are enabled when Supabase and AI endpoints are configured.

## Feature Overview

- Quran Reader
  - Browse all surahs and read Arabic text, transliteration, and translation.
  - Bookmark ayat and save notes locally.
- Learning and Quiz
  - Difficulty-based quiz flow (easy, medium, hard).
  - AI quiz generation through Supabase Edge Function, with deterministic local fallback when unavailable.
- Audio and Murottal
  - Stream recitations and keep playback running in background.
  - Persistent mini player across tabs.
- Daily Verse
  - Daily ayah highlight with direct link to its surah.
- Prayer Times
  - Daily prayer schedule from location with refresh and manual location override.
- Qibla Finder
  - Compass-based qibla direction with degree guidance.
- Tasbih Counter
  - Tap counter with target presets and daily history.
- AI Chat Assistant
  - Floating dock chat UI that can use surah context.
- Progress and Profile
  - XP/streak style progress and user profile/account state.

## Tech Stack

- Flutter / Dart (`sdk: ^3.10.8`)
- State management: `flutter_riverpod`
- Routing: `go_router`
- Networking: `dio`
- Local storage: `sqflite`, `shared_preferences`, `flutter_secure_storage`
- Optional backend: `supabase_flutter`
- Audio: `just_audio`, `audio_service`
- Location/compass/prayer support: `geolocator`, `geocoding`, `flutter_compass`, `adhan_dart`

## Project Structure

```text
lib/
  app/                # Bootstrap, app shell, router, theme
  core/               # Config, network, storage, shared infrastructure
  features/
    audio/
    auth/
    chat/
    daily_verse/
    dashboard/
    home/
    learning/
    onboarding/
    prayer_times/
    profile/
    progress/
    qibla/
    quiz/
    quran/
    tasbih/
  shared/             # Shared widgets/utilities
supabase/functions/
  chat-ai/
  quiz-generate/
```

## Prerequisites

- Flutter SDK compatible with Dart `^3.10.8`
- Android Studio/Xcode setup for target platform
- Optional: Supabase CLI for function deployment

## Quick Start

```bash
flutter pub get
flutter run
```

`flutter run` works in guest mode if no environment values are provided.

## Environment Configuration (Optional but Recommended)

Create `.env` in project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
AI_QUIZ_ENDPOINT=https://your-project.supabase.co/functions/v1/quiz-generate
CHAT_AI_TAWAKKAL_ENDPOINT=https://your-project.supabase.co/functions/v1/chat-ai
AI_PROVIDER=nvidia
AI_MODEL=z-ai/glm4.7
AI_QUIZ_ALWAYS_FRESH=true
AI_QUIZ_RECENT_SIGNATURE_LIMIT=30
```

Run using the env file:

```bash
flutter run --dart-define-from-file=.env
```

Alternative (no `--dart-define`): copy `.env` into `assets/env/runtime.env`.
The app will load this asset at startup as a runtime fallback.

Build using the env file:

```bash
flutter build apk --dart-define-from-file=.env
flutter build appbundle --dart-define-from-file=.env
```

## Supabase Edge Functions (Optional)

Deploy quiz function:

```bash
supabase functions deploy quiz-generate --project-ref YOUR_PROJECT_REF
```

Deploy chat function:

```bash
supabase functions deploy chat-ai --project-ref YOUR_PROJECT_REF
```

If you deploy chat under a different function name, update `CHAT_AI_TAWAKKAL_ENDPOINT` accordingly.
For the default `chat-ai-tawakkal` deployment, the app intentionally uses anon auth first to avoid known user-JWT `401 Invalid JWT` noise on some Edge Function auth configurations.

## Quality Checks

```bash
flutter analyze
flutter test
```

## Security Notes

- Do not commit real credentials in `.env`.
- Keep server-side secrets (for example provider API keys) in Supabase Edge Function secrets, not in the Flutter app.
