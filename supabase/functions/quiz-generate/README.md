# quiz-generate Edge Function

AI-first Quran quiz generation with deterministic fallback:
1. Fetches Surah context directly from EQuran API.
2. Attempts full question generation via Xiaomi MiMo using the low-cost `mimo-v2-flash` model and cognitive-by-difficulty policy (Bloom ladder).
3. Falls back to deterministic randomized generation if AI is unavailable or invalid.
4. Optionally enriches explanations/feedback for deterministic fallback output (best-effort, timeout-safe).
5. Applies final compaction guardrails so explanation/feedback stay concise for mobile readability.

## Request body
Required:
- `surah_id` (number)

Optional:
- `surah_name` (string)
- `difficulty` (`easy` | `medium` | `hard`)
- `language` (`id` | `en`)
- `question_count` (number, clamped to 1..10)
- `provider` (`xiaomi` or `mimo`; old `nvidia`/`nim` values are treated as MiMo for compatibility)
- `model` is ignored by this function so quiz generation stays on the server-configured low-cost MiMo model
- `generation_mode` (`ai_first` | `deterministic`, default from `QUIZ_GENERATION_MODE`)
- `request_id` (string, recommended for tracing/randomness)
- `recent_signatures` (string[], optional anti-repeat hints; ayah refs like `2:15` inside signatures are used)

## Response shape
```json
{
  "quiz": { "...": "QuizPayload-compatible JSON" },
  "meta": {
    "provider_used": "deterministic | xiaomi_mimo",
    "model_used": "string|null",
    "generation_mode": "ai_first | deterministic | deterministic_ai_enhanced",
    "cognitive_profile": "bloom_ladder",
    "anti_repeat_applied": true,
    "fallback_reason": "string|null",
    "equran_fetch": { "...": "timing + context stats" },
    "ai_generation": { "...": "attempt/success/timing/error" },
    "ai_enrichment": { "...": "attempt/success/timing/error" },
    "validation": { "dropped_questions": 0, "repaired_questions": 0 },
    "latency_ms": 1234
  }
}
```

## Required / optional secrets
Required for AI generation/enrichment:
- `MIMO_API_KEY`

Optional aliases:
- `XIAOMI_MIMO_API_KEY`
- `XIAOMI_API_KEY`

Recommended:
- `EQURAN_API_BASE` (default: `https://equran.id/api/v2`)
- `EQURAN_FETCH_TIMEOUT_MS` (default: `6000`)
- `MIMO_BASE_URL` (default: `https://api.xiaomimimo.com/v1`)
- `MIMO_QUIZ_MODEL` (default: `mimo-v2-flash`)
- `MIMO_QUIZ_FUNCTION_BUDGET_MS` (default: `42000`)
- `MIMO_QUIZ_ENRICH_TIMEOUT_MS` (default: `9000`)
- `MIMO_QUIZ_FULL_TIMEOUT_MS` (default: `12000`)
- `MIMO_QUIZ_MAX_COMPLETION_TOKENS` (default: `900`)
- `MIMO_QUIZ_FULL_MAX_COMPLETION_TOKENS` (default: `2200`)
- `QUIZ_GENERATION_MODE` (`ai_first` / `deterministic`, default: `ai_first`)
- `MIMO_QUIZ_ENABLE_FULL_GENERATION` (`true` / `false`, default: `true`)
- `MIMO_QUIZ_ENABLE_EXPLANATION_ENRICHMENT` (`true` / `false`, default: `false`)
- `MIMO_QUIZ_ENABLE_THINKING` (default: `false`)

## Deploy
```bash
supabase functions deploy quiz-generate --project-ref YOUR_PROJECT_REF
```

## Local serve
```bash
supabase functions serve quiz-generate --env-file .env.local
```

## Flutter integration
```bash
flutter run --dart-define=AI_QUIZ_ENDPOINT=https://YOUR_PROJECT_REF.supabase.co/functions/v1/quiz-generate
```

## Troubleshooting
- `400 Missing required fields`: include at least `surah_id`.
- `400 Invalid provider`: only `xiaomi` / `mimo` are supported; old `nvidia` / `nim` values are accepted as compatibility aliases.
- `missing_mimo_api_key`: set `MIMO_API_KEY` in Supabase Edge Function secrets.
- `502 EQuran fetch failed`: upstream EQuran unreachable/invalid response.
- `502 budget_exhausted_before_equran`: function budget is too low for current runtime settings.
- `ai_enrichment.success=false`: deterministic EQuran-grounded output is still valid; enrichment is optional.
