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
- `NVIDIA_NIM_FALLBACK_MODEL` (optional, retries once on upstream timeout/5xx)
- `NVIDIA_NIM_REQUEST_TIMEOUT_MS` (default `45000`)
- `NVIDIA_NIM_MAX_TOKENS` (default `768`)
- `NVIDIA_NIM_TEMPERATURE` (default `0.4`)
- `NVIDIA_NIM_TOP_P` (default `0.9`)
- `NVIDIA_NIM_ENABLE_THINKING` (default `false`)
- `NVIDIA_NIM_CLEAR_THINKING` (default `true`)

## 502 troubleshooting
- If logs show execution around `28000 ms`, requests are timing out upstream.
- Set `NVIDIA_NIM_REQUEST_TIMEOUT_MS=45000` and reduce `NVIDIA_NIM_MAX_TOKENS` to `512-768`.
- Set `NVIDIA_NIM_FALLBACK_MODEL` to a faster model available in your NVIDIA account.
- Upstream timeout now returns `504` (`AI upstream timeout.`) for clearer diagnosis.
- Redeploy the function after changing code/secrets.

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
