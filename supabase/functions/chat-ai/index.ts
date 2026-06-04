import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const defaultMimoBaseUrl = "https://api.xiaomimimo.com/v1";
const defaultMimoModel = "mimo-v2.5-pro";
const maxUserMessageChars = 1800;
const maxHistoryMessageChars = 900;
const maxAyahTranslationsChars = 2600;
const maxTafsirSnippetsChars = 2200;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Provider = "xiaomi";
type ChatRole = "system" | "user" | "assistant";

type ConversationMessage = {
  role: ChatRole;
  content: string;
};

type SurahContext = {
  surah_id: number;
  surah_name: string;
  ayah_translations?: string;
  tafsir_snippets?: string;
};

type MimoConfig = {
  baseUrl: string;
  apiKey: string;
  defaultModel: string;
  requestTimeoutMs: number;
  maxTokens: number;
  temperature: number;
  topP: number;
  enableThinking: boolean;
  clearThinking: boolean;
};

type ChatCompletionResponse = {
  choices?: Array<{ message?: { content?: unknown } }>;
  model?: unknown;
};

const systemInstruction = `
You are Tawakkal AI, an Islamic learning assistant.
Your role is to explain Quran meanings, tafsir, and practical reflections clearly and respectfully.
Never modify, rewrite, or invent Arabic Quran text.
Ground your answer in the provided surah context whenever available.
If context is missing or insufficient, state uncertainty honestly.
Keep answers concise but useful (roughly 2-4 short paragraphs).
Reply in Indonesian or English based on the user's language.
`;

Deno.serve(async (req: Request) => {
  const startedAt = Date.now();

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON payload." }, 400);
  }

  const provider = parseProvider(body.provider);
  if (provider === "invalid") {
    return jsonResponse({ error: "Invalid provider. Allowed values: xiaomi, mimo." }, 400);
  }

  const userMessageRaw = asString(body.message).trim();
  if (!userMessageRaw) {
    return jsonResponse({ error: "Missing or empty 'message' field." }, 400);
  }
  const userMessage = clampText(userMessageRaw, maxUserMessageChars);

  const config = loadMimoConfig();
  if (!config.apiKey) {
    return jsonResponse(
      {
        error: "MIMO_API_KEY is not configured for chat-ai function.",
      },
      500,
    );
  }

  const model = resolveMimoModel(asString(body.model), config.defaultModel);
  const history = parseConversationHistory(body.conversation_history);
  const surahContext = parseSurahContext(body.surah_context);

  const messages: ConversationMessage[] = [
    { role: "system", content: systemInstruction.trim() },
  ];

  if (surahContext) {
    messages.push({
      role: "system",
      content: buildSurahContextInstruction(surahContext),
    });
  }

  messages.push(...history);
  messages.push({ role: "user", content: userMessage });

  try {
    const completion = await requestChatCompletionWithFallback({
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model,
      messages,
      timeoutMs: config.requestTimeoutMs,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      topP: config.topP,
      enableThinking: config.enableThinking,
      clearThinking: config.clearThinking,
    });

    if (!completion.response.ok) {
      const upstreamStatus = completion.response.status;
      const upstreamCode = extractErrorCode(completion.errorBody);
      const timeoutDetected = upstreamStatus === 408 || upstreamCode === 408;
      const mappedStatus = timeoutDetected ? 504 : upstreamStatus || 502;
      const mappedError =
        timeoutDetected
          ? "AI upstream timeout."
          : "AI upstream request failed.";
      return jsonResponse(
        {
          error: mappedError,
          details: completion.errorBody ?? null,
        },
        mappedStatus,
      );
    }

    const responseBody = await safeJson<ChatCompletionResponse>(completion.response);
    const rawContent = coerceTextContent(responseBody?.choices?.[0]?.message?.content);
    if (!rawContent) {
      return jsonResponse({ error: "AI model returned empty response." }, 502);
    }

    const reply = config.clearThinking ? clearThinkingBlocks(rawContent) : rawContent.trim();
    if (!reply) {
      return jsonResponse({ error: "AI response was empty after sanitization." }, 502);
    }

    const modelUsed = asString(responseBody?.model) || completion.modelUsed;
    return jsonResponse(
      {
        reply,
        model: modelUsed,
        meta: {
          provider_used: provider ?? "xiaomi",
          upstream_provider: "xiaomi_mimo",
          completion_attempt: completion.attempt,
          latency_ms: Date.now() - startedAt,
          history_count: history.length,
          context_attached: surahContext !== null,
        },
      },
      200,
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(
      {
        error: "Internal chat-ai error.",
        details: message,
      },
      500,
    );
  }
});

function buildSurahContextInstruction(context: SurahContext): string {
  const safeAyahTranslations = clampText(
    context.ayah_translations ?? "",
    maxAyahTranslationsChars,
  );
  const safeTafsirSnippets = clampText(
    context.tafsir_snippets ?? "",
    maxTafsirSnippetsChars,
  );

  const parts = [
    `Current Surah Context:`,
    `- Surah ID: ${context.surah_id}`,
    `- Surah Name: ${context.surah_name}`,
  ];

  if (safeAyahTranslations.length > 0) {
    parts.push(`\nAyah Translations:\n${safeAyahTranslations}`);
  }
  if (safeTafsirSnippets.length > 0) {
    parts.push(`\nTafsir Snippets:\n${safeTafsirSnippets}`);
  }

  return parts.join("\n");
}

function loadMimoConfig(): MimoConfig {
  const apiKey =
    Deno.env.get("MIMO_API_KEY") ||
    Deno.env.get("XIAOMI_MIMO_API_KEY") ||
    Deno.env.get("XIAOMI_API_KEY") ||
    "";
  const defaultModel = resolveMimoModel(
    Deno.env.get("MIMO_MODEL") ||
      Deno.env.get("XIAOMI_MIMO_MODEL") ||
      Deno.env.get("AI_MODEL") ||
      "",
    defaultMimoModel,
  );

  return {
    baseUrl: normalizeBaseUrl(
      Deno.env.get("MIMO_BASE_URL") ||
        Deno.env.get("XIAOMI_MIMO_BASE_URL") ||
        defaultMimoBaseUrl,
    ),
    apiKey,
    defaultModel,
    requestTimeoutMs: parseIntWithBounds(
      Deno.env.get("MIMO_REQUEST_TIMEOUT_MS"),
      45000,
      3000,
      60000,
    ),
    maxTokens: parseIntWithBounds(
      Deno.env.get("MIMO_MAX_COMPLETION_TOKENS") || Deno.env.get("MIMO_MAX_TOKENS"),
      768,
      128,
      4096,
    ),
    temperature: parseFloatWithBounds(
      Deno.env.get("MIMO_TEMPERATURE"),
      0.7,
      0,
      2,
    ),
    topP: parseFloatWithBounds(Deno.env.get("MIMO_TOP_P"), 0.95, 0, 1),
    enableThinking: parseBooleanWithDefault(Deno.env.get("MIMO_ENABLE_THINKING"), false),
    clearThinking: parseBooleanWithDefault(Deno.env.get("MIMO_CLEAR_THINKING"), true),
  };
}

function parseConversationHistory(input: unknown): ConversationMessage[] {
  const rows = asArray(input).filter(isRecord).slice(-10);
  const parsed: ConversationMessage[] = [];

  for (const row of rows) {
    const role = asString(row.role).toLowerCase();
    const content = clampText(
      asString(row.content),
      maxHistoryMessageChars,
    ).trim();
    if (!content) {
      continue;
    }
    if (role === "user" || role === "assistant") {
      parsed.push({
        role: role as "user" | "assistant",
        content,
      });
    }
  }
  return parsed;
}

function parseSurahContext(input: unknown): SurahContext | null {
  if (!isRecord(input)) {
    return null;
  }

  const surahId = asPositiveInt(input.surah_id);
  const surahName = asString(input.surah_name);
  if (surahId === null || !surahName) {
    return null;
  }

  const ayahTranslations = asString(input.ayah_translations);
  const tafsirSnippets = asString(input.tafsir_snippets);

  return {
    surah_id: surahId,
    surah_name: surahName,
    ayah_translations: ayahTranslations || undefined,
    tafsir_snippets: tafsirSnippets || undefined,
  };
}

function parseProvider(input: unknown): Provider | null | "invalid" {
  if (input == null) {
    return null;
  }
  const value = asString(input).toLowerCase();
  if (!value) {
    return null;
  }
  if (value === "xiaomi" || value === "mimo" || value === "xiaomi_mimo") {
    return "xiaomi";
  }
  if (value === "nvidia" || value === "nim") {
    return "xiaomi";
  }
  return "invalid";
}

type CompletionAttempt = "primary" | "fallback";
type CompletionResult = {
  response: Response;
  errorBody?: unknown;
  modelUsed: string;
  attempt: CompletionAttempt;
};

async function requestChatCompletionWithFallback(params: {
  baseUrl: string;
  apiKey: string;
  model: string;
  messages: ConversationMessage[];
  timeoutMs: number;
  maxTokens: number;
  temperature: number;
  topP: number;
  enableThinking: boolean;
  clearThinking: boolean;
}): Promise<CompletionResult> {
  const primaryTimeoutMs = Math.max(
    10000,
    Math.min(params.timeoutMs, 22000),
  );

  const primary = await requestChatCompletion({
    ...params,
    timeoutMs: primaryTimeoutMs,
  });
  if (primary.response.ok || !shouldRetryUpstream(primary.response.status, primary.errorBody)) {
    return {
      ...primary,
      modelUsed: params.model,
      attempt: "primary",
    };
  }

  const fallbackModel = resolveMimoModel(
    Deno.env.get("MIMO_FALLBACK_MODEL") ||
      Deno.env.get("XIAOMI_MIMO_FALLBACK_MODEL") ||
      "",
    params.model,
  );
  const fallbackTimeoutMs = Math.max(
    8000,
    Math.min(18000, params.timeoutMs - primaryTimeoutMs + 6000),
  );
  const fallback = await requestChatCompletion({
    ...params,
    model: fallbackModel,
    messages: buildFallbackMessages(params.messages),
    timeoutMs: fallbackTimeoutMs,
    maxTokens: Math.max(192, Math.min(384, Math.floor(params.maxTokens * 0.5))),
    temperature: Math.min(params.temperature, 0.3),
    topP: Math.min(params.topP, 0.85),
    enableThinking: false,
    clearThinking: true,
  });

  return {
    ...fallback,
    modelUsed: fallbackModel,
    attempt: "fallback",
  };
}

async function requestChatCompletion(params: {
  baseUrl: string;
  apiKey: string;
  model: string;
  messages: ConversationMessage[];
  timeoutMs: number;
  maxTokens: number;
  temperature: number;
  topP: number;
  enableThinking: boolean;
  clearThinking: boolean;
}): Promise<{ response: Response; errorBody?: unknown }> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort("upstream_timeout"), params.timeoutMs);

  const payload: Record<string, unknown> = {
    model: params.model,
    messages: params.messages,
    stream: false,
    max_completion_tokens: params.maxTokens,
  };
  if (!params.enableThinking) {
    payload.temperature = params.temperature;
    payload.top_p = params.topP;
  }
  payload.thinking = {
    type: params.enableThinking ? "enabled" : "disabled",
  };

  try {
    const response = await fetch(`${params.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "api-key": params.apiKey,
        Authorization: `Bearer ${params.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (response.ok) {
      return { response };
    }
    return { response, errorBody: await safeJson(response) };
  } catch (error) {
    const timedOut = isAbortError(error);
    const body = {
      error: {
        code: timedOut ? 408 : 502,
        message: timedOut ? "MiMo request timeout" : String(error),
      },
    };
    return {
      response: new Response(JSON.stringify(body), {
        status: timedOut ? 408 : 502,
        headers: { "Content-Type": "application/json" },
      }),
      errorBody: body,
    };
  } finally {
    clearTimeout(timeoutId);
  }
}

function clearThinkingBlocks(input: string): string {
  return input.replace(/<\s*think[\s\S]*?<\/\s*think\s*>/gi, "").trim();
}

function coerceTextContent(content: unknown): string | null {
  if (typeof content === "string") {
    return content.trim();
  }

  if (Array.isArray(content)) {
    const merged = content
      .map((part) => {
        if (typeof part === "string") {
          return part;
        }
        if (isRecord(part)) {
          return asString(part.text);
        }
        return "";
      })
      .join("")
      .trim();
    return merged || null;
  }

  if (isRecord(content)) {
    const text = asString(content.text);
    return text || null;
  }
  return null;
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function resolveModel(input: string, fallback: string): string {
  const normalized = normalizeModelId(input);
  return normalized || fallback;
}

function resolveMimoModel(input: string, fallback: string): string {
  const normalized = normalizeModelId(input).replace(/^xiaomi\//i, "");
  if (!normalized) {
    return fallback;
  }
  if (normalized.startsWith("mimo-")) {
    return normalized;
  }
  return fallback;
}

function normalizeBaseUrl(url: string): string {
  return url.replace(/\/+$/, "");
}

function normalizeModelId(model: string): string {
  return model.replace(/\\/g, "/").trim();
}

function parseIntWithBounds(
  value: string | undefined,
  fallback: number,
  min: number,
  max: number,
): number {
  if (!value) {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, parsed));
}

function parseFloatWithBounds(
  value: string | undefined,
  fallback: number,
  min: number,
  max: number,
): number {
  if (!value) {
    return fallback;
  }
  const parsed = Number.parseFloat(value);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, parsed));
}

function parseBooleanWithDefault(value: string | undefined, fallback: boolean): boolean {
  if (!value) {
    return fallback;
  }
  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }
  return fallback;
}

function asString(value: unknown): string {
  if (typeof value === "string") {
    return value.trim();
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  return "";
}

function asPositiveInt(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function isAbortError(error: unknown): boolean {
  if (!error) {
    return false;
  }
  if (error instanceof DOMException) {
    return error.name === "AbortError";
  }
  return String(error).toLowerCase().includes("abort");
}

function buildFallbackMessages(messages: ConversationMessage[]): ConversationMessage[] {
  if (messages.length <= 3) {
    return messages;
  }

  const systemMessages = messages.filter((entry) => entry.role === "system").slice(0, 2);
  const dialogue = messages.filter((entry) => entry.role !== "system");
  const tail = dialogue.slice(-3);
  return [...systemMessages, ...tail];
}

function shouldRetryUpstream(statusCode: number, errorBody?: unknown): boolean {
  if ([408, 429, 500, 502, 503, 504].includes(statusCode)) {
    return true;
  }
  const codeFromBody = extractErrorCode(errorBody);
  return codeFromBody !== null && [408, 429, 500, 502, 503, 504].includes(codeFromBody);
}

function extractErrorCode(errorBody: unknown): number | null {
  if (!isRecord(errorBody)) {
    return null;
  }
  const nested = errorBody.error;
  if (isRecord(nested)) {
    const rawCode = nested.code;
    if (typeof rawCode === "number" && Number.isFinite(rawCode)) {
      return Math.trunc(rawCode);
    }
    if (typeof rawCode === "string") {
      const parsed = Number.parseInt(rawCode, 10);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }
  return null;
}

function clampText(value: string, maxChars: number): string {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return `${normalized.slice(0, maxChars)}...`;
}

async function safeJson<T>(response: Response): Promise<T | null> {
  try {
    return (await response.json()) as T;
  } catch {
    return null;
  }
}
