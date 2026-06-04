# chat-ai Edge Function

AI chat endpoint for Tawakkal chatbot UI.

## Request body
Required:
- `message` (string)

Optional:
- `provider` (`xiaomi` or `mimo`; old `nvidia`/`nim` values are treated as MiMo for compatibility)
- `model` (MiMo model id, default `mimo-v2.5-pro`)
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
  "model": "mimo-v2.5-pro",
  "meta": {
    "provider_used": "xiaomi",
    "upstream_provider": "xiaomi_mimo",
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
- `MIMO_API_KEY`

Optional aliases:
- `XIAOMI_MIMO_API_KEY`
- `XIAOMI_API_KEY`

Recommended settings:
- `MIMO_BASE_URL` (default `https://api.xiaomimimo.com/v1`)
- `AI_MODEL` or `MIMO_MODEL` (default `mimo-v2.5-pro`)
- `MIMO_FALLBACK_MODEL` (optional, retries once on upstream timeout/5xx)
- `MIMO_REQUEST_TIMEOUT_MS` (default `45000`)
- `MIMO_MAX_COMPLETION_TOKENS` or `MIMO_MAX_TOKENS` (default `768`)
- `MIMO_TEMPERATURE` (default `0.7`)
- `MIMO_TOP_P` (default `0.95`)
- `MIMO_ENABLE_THINKING` (default `false`)
- `MIMO_CLEAR_THINKING` (default `true`)

When `MIMO_ENABLE_THINKING=true`, the function omits sampling parameters such as `temperature` because MiMo V2.5 thinking mode does not support customized temperature.

## 502 troubleshooting
- If logs show execution around `28000 ms`, requests are timing out upstream.
- Set `MIMO_REQUEST_TIMEOUT_MS=45000` and reduce `MIMO_MAX_COMPLETION_TOKENS` to `512-768`.
- Set `MIMO_FALLBACK_MODEL` to a faster MiMo model available in your account.
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
