# Tawakkal (توكل)

A mobile Islamic learning app built with Flutter — read the Quran, take AI-powered quizzes, stream murottal audio, and track your daily progress.

## Features

### 🏠 Dashboard
- Personalised greeting with time-of-day context.
- Today's Goal card with XP bar and streak counter.
- Continue Learning shortcut to resume the last surah.
- Quick-action tiles: Baca Quran, Belajar, Audio, Profil.
- Reciter showcase tiles to jump straight into murottal playback.

### 📖 Quran Reader
- Full 114-surah list fetched from **EQuran.id v2** API with offline SQLite cache.
- Surah detail page: Arabic text, Latin transliteration, Indonesian translation.
- Per-ayah audio playback (stream or from offline download).
- Bookmark any ayah and attach personal notes (stored locally in SQLite, synced to Supabase when authenticated).

### 🎓 Learning & Quiz
- Duolingo-style learning path with three difficulty tiers: **Easy → Medium → Hard**.
- AI-generated quizzes via a **Supabase Edge Function** (`quiz-generate`) backed by **NVIDIA NIM**.
- Strict prompt contract (`docs/ai/quiz_prompt_contract.md`) for deterministic, respectful question generation.
- Rich result page with score ring, elapsed time, correct/wrong stats, AI insight rows, and a "Review Mistakes" bottom-sheet.
- Quiz cache in SQLite to avoid redundant AI calls.

### 🔊 Audio / Murottal
- Stream full-surah murottal from EQuran.id with background playback (`just_audio` + `audio_service`).
- Download murottal for offline listening (per-surah, per-reciter) with checksum validation.
- Persistent mini-player overlay across all tabs.
- Audio hero card with play/pause, progress bar, and reciter info.

### 📊 Progress Tracking
- XP earned per quiz, aggregated into a daily progress bar.
- Streak tracking with automatic daily reset logic.
- Per-surah learning progress stored in SQLite.
- Cloud sync queue: bookmarks, notes, and learning progress are enqueued locally and synced to Supabase when connectivity is available.

### 👤 Profile
- Display name, email, and authentication status.
- Guest mode badge or authenticated account indicator.
- Progress overview card (total XP, streak, quizzes completed).
- Sign-out action.

### 🚀 Onboarding
- Animated splash screen with brand mark and loading indicator.
- Three-slide onboarding pager: Master Your Faith, Read with Calm Focus, Listen to Trusted Reciters.
- Skip / Log In shortcut, persisted via `shared_preferences`.

### 🔐 Authentication
- Guest/offline-first mode — the app is fully functional without credentials.
- Optional Supabase Auth (email/password) for cloud sync.
- Auth gate that routes returning users directly to the home screen.

## Architecture

```
lib/
├── app/            # App shell, GoRouter, theme (colors, typography)
├── core/           # Config, constants, errors, Dio client, SQLite, utils
├── features/       # Feature modules (clean architecture)
│   ├── audio/      # data / domain / presentation
│   ├── auth/
│   ├── dashboard/
│   ├── home/       # Bottom-nav shell with 5 tabs
│   ├── learning/
│   ├── onboarding/
│   ├── profile/
│   ├── progress/
│   ├── quiz/
│   └── quran/
└── shared/         # Reusable widgets & utils
```

Each feature follows **data → domain → presentation** layering with Riverpod providers.

## Tech Stack

| Layer | Library |
|---|---|
| Framework | Flutter + Dart (SDK ^3.10.8) |
| State Management | `flutter_riverpod` |
| Routing | `go_router` |
| Networking | `dio`, `connectivity_plus` |
| Local Storage | `sqflite`, `shared_preferences`, `flutter_secure_storage` |
| Backend (optional) | `supabase_flutter` |
| Audio | `just_audio`, `audio_service` |
| Typography | `google_fonts` |
| Utilities | `uuid`, `crypto`, `collection`, `intl`, `equatable`, `path_provider` |

## Environment Configuration

Create a local `.env` file and fill in your values:

```bash
# Required for cloud features (optional for guest mode)
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
AI_QUIZ_ENDPOINT=YOUR_AI_QUIZ_ENDPOINT
AI_MODEL=qwen/qwen2.5-coder-32b-instruct
```

Run with `.env` (recommended):

```bash
flutter run --dart-define-from-file=.env
```

Build with `.env`:

```bash
flutter build apk --dart-define-from-file=.env
flutter build appbundle --dart-define-from-file=.env
```

### Supabase Edge Function

Deploy the quiz-generate function:

```bash
supabase functions deploy quiz-generate --project-ref YOUR_PROJECT_REF
```

Function source: `supabase/functions/quiz-generate/index.ts`

**NVIDIA NIM** optional resilience secrets (set in Edge Function secrets):
- `NVIDIA_NIM_MODEL_CANDIDATES`
- `NVIDIA_NIM_MAX_RETRIES`
- `NVIDIA_NIM_RETRY_BASE_MS`

> **Security note:** Never put server secrets (`NVIDIA_NIM_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, etc.) in the app `.env`. Keep them in Supabase Edge Function secrets.

Without credentials the app runs in **guest/offline-first mode**.

## Key Project Paths

| Path | Purpose |
|---|---|
| `lib/app/` | App shell, theme, and GoRouter config |
| `lib/core/` | Config, networking (Dio), SQLite database, utilities |
| `lib/features/` | All feature modules |
| `lib/shared/` | Shared widgets (`AsyncStateView`, `RichInfoCard`, `RichPageBackground`, `RichSectionTitle`) |
| `supabase/migrations/20260209_tawakkal_init.sql` | Database migration |
| `supabase/functions/quiz-generate/` | AI quiz Edge Function |
| `docs/ai/quiz_prompt_contract.md` | AI prompt contract |
| `docs/integration/equran_v2.md` | EQuran API integration notes |
| `test/` | Unit and widget tests |

## Testing

```bash
flutter analyze   # Static analysis — passes
flutter test      # Unit & widget tests — passes
```
