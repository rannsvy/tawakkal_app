# quiz-generate Edge Function

Generates grounded Quran quiz JSON via OpenAI and returns strict schema output.

## Required secrets
- `OPENAI_API_KEY`
- Optional: `OPENAI_MODEL` (default: `gpt-4.1-mini`)

## Deploy
```bash
supabase functions deploy quiz-generate --project-ref YOUR_PROJECT_REF
```

## Local serve
```bash
supabase functions serve quiz-generate --env-file .env.local
```

`.env.local` example:
```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4.1-mini
```

## Flutter integration
Pass function invoke URL into app:

```bash
flutter run --dart-define=AI_QUIZ_ENDPOINT=https://YOUR_PROJECT_REF.supabase.co/functions/v1/quiz-generate
```

