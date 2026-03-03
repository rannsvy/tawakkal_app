# chat-ai Edge Function

AI chat endpoint for Tawakkal chatbot UI.

## Request body
Required:
- `message` (string)

Optional:
- `provider` (`nvidia`)
- `model` (NVIDIA model id)
- `conversation_history` (array of `{ role, content }`, last 10 used)
- `surah_context` object:
  - `surah_id` (number)
  - `surah_name` (string)
  - `ayah_translations` (string)
  - `tafsir_snippets` (string)

## Response shape
```json
{
  "reply": "string",
  "model": "z-ai/glm4.7",
  "meta": {
    "provider_used": "nvidia",
    "latency_ms": 1234,
    "history_count": 4,
    "context_attached": true
  }
}
```

Error shape:
```json
{
  "error": "string",
  "details": "optional"
}
```

## Required secrets
- `NVIDIA_NIM_API_KEY`

Optional aliases:
- `NIM_API_KEY`

Recommended settings:
- `NVIDIA_NIM_BASE_URL` (default `https://integrate.api.nvidia.com/v1`)
- `AI_MODEL` (default `z-ai/glm4.7`)
- `NVIDIA_NIM_REQUEST_TIMEOUT_MS` (default `28000`)
- `NVIDIA_NIM_MAX_TOKENS` (default `1024`)
- `NVIDIA_NIM_TEMPERATURE` (default `0.4`)
- `NVIDIA_NIM_TOP_P` (default `0.9`)
- `NVIDIA_NIM_ENABLE_THINKING` (default `false`)
- `NVIDIA_NIM_CLEAR_THINKING` (default `true`)

## Deploy
```bash
supabase functions deploy chat-ai --project-ref YOUR_PROJECT_REF
```

## Local serve
```bash
supabase functions serve chat-ai --env-file .env.local
```

## Flutter integration
Use:
```bash
--dart-define=AI_CHAT_ENDPOINT=https://YOUR_PROJECT_REF.supabase.co/functions/v1/chat-ai
```
