# quiz-generate Edge Function

AI-first Quran quiz generation with deterministic fallback:
1. Fetches Surah context directly from EQuran API.
2. Attempts full question generation via NVIDIA NIM using cognitive-by-difficulty policy (Bloom ladder).
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
- `provider` (`nvidia`)
- `model` (NVIDIA model id)
- `generation_mode` (`ai_first` | `deterministic`, default from `QUIZ_GENERATION_MODE`)
- `request_id` (string, recommended for tracing/randomness)
- `recent_signatures` (string[], optional anti-repeat hints; ayah refs like `2:15` inside signatures are used)

## Response shape
```json
{
  "quiz": { "...": "QuizPayload-compatible JSON" },
  "meta": {
    "provider_used": "deterministic | nvidia",
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
Required for AI enrichment:
- `NVIDIA_NIM_API_KEY`

Optional aliases:
- `NIM_API_KEY` (legacy alias)

Recommended:
- `EQURAN_API_BASE` (default: `https://equran.id/api/v2`)
- `EQURAN_FETCH_TIMEOUT_MS` (default: `6000`)
- `NVIDIA_NIM_BASE_URL` (default: `https://integrate.api.nvidia.com/v1`)
- `NVIDIA_NIM_MODEL` (default: `z-ai/glm4.7`)
- `NVIDIA_NIM_FUNCTION_BUDGET_MS` (default: `42000`)
- `NVIDIA_NIM_ENRICH_TIMEOUT_MS` (default: `9000`)
- `NVIDIA_NIM_FULL_TIMEOUT_MS` (default: `12000`)
- `NVIDIA_NIM_MAX_TOKENS` (default: `900`)
- `NVIDIA_NIM_FULL_MAX_TOKENS` (default: `2200`)
- `QUIZ_GENERATION_MODE` (`ai_first` / `deterministic`, default: `ai_first`)
- `NVIDIA_NIM_ENABLE_FULL_GENERATION` (`true` / `false`, default: `true`)
- `NVIDIA_NIM_ENABLE_EXPLANATION_ENRICHMENT` (`true` / `false`, default: `false`)
- `NVIDIA_NIM_ENABLE_THINKING` (default: `false`)
- `NVIDIA_NIM_CLEAR_THINKING` (default: `true`)

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
- `400 Invalid provider`: only `nvidia` is supported.
- `500 NVIDIA_NIM_API_KEY...`: set the secret in Supabase Edge Function settings.
- `502 EQuran fetch failed`: upstream EQuran unreachable/invalid response.
- `502 budget_exhausted_before_equran`: function budget is too low for current runtime settings.
- `ai_enrichment.success=false`: deterministic EQuran-grounded output is still valid; enrichment is optional.
