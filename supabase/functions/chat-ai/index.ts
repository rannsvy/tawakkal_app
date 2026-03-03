import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const defaultNimBaseUrl = "https://integrate.api.nvidia.com/v1";
const defaultNimModel = "z-ai/glm4.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Provider = "nvidia";
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

type NimConfig = {
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
    return jsonResponse({ error: "Invalid provider. Allowed values: nvidia." }, 400);
  }

  const userMessage = asString(body.message).trim();
  if (!userMessage) {
    return jsonResponse({ error: "Missing or empty 'message' field." }, 400);
  }

  const config = loadNimConfig();
  if (!config.apiKey) {
    return jsonResponse(
      {
        error: "NVIDIA_NIM_API_KEY is not configured for chat-ai function.",
      },
      500,
    );
  }

  const model = resolveModel(asString(body.model), config.defaultModel);
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
    const completion = await requestChatCompletion({
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
      return jsonResponse(
        {
          error: "AI upstream request failed.",
          details: completion.errorBody ?? null,
        },
        502,
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

    const modelUsed = asString(responseBody?.model) || model;
    return jsonResponse(
      {
        reply,
        model: modelUsed,
        meta: {
          provider_used: provider ?? "nvidia",
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
  const parts = [
    `Current Surah Context:`,
    `- Surah ID: ${context.surah_id}`,
    `- Surah Name: ${context.surah_name}`,
  ];

  if (context.ayah_translations && context.ayah_translations.trim().length > 0) {
    parts.push(`\nAyah Translations:\n${context.ayah_translations.trim()}`);
  }
  if (context.tafsir_snippets && context.tafsir_snippets.trim().length > 0) {
    parts.push(`\nTafsir Snippets:\n${context.tafsir_snippets.trim()}`);
  }

  return parts.join("\n");
}

function loadNimConfig(): NimConfig {
  const apiKey = Deno.env.get("NVIDIA_NIM_API_KEY") || Deno.env.get("NIM_API_KEY") || "";
  const defaultModel = resolveModel(
    Deno.env.get("AI_MODEL") || Deno.env.get("NVIDIA_NIM_MODEL") || "",
    defaultNimModel,
  );

  return {
    baseUrl: normalizeBaseUrl(Deno.env.get("NVIDIA_NIM_BASE_URL") || defaultNimBaseUrl),
    apiKey,
    defaultModel,
    requestTimeoutMs: parseIntWithBounds(
      Deno.env.get("NVIDIA_NIM_REQUEST_TIMEOUT_MS"),
      28000,
      3000,
      60000,
    ),
    maxTokens: parseIntWithBounds(
      Deno.env.get("NVIDIA_NIM_MAX_TOKENS"),
      1024,
      128,
      4096,
    ),
    temperature: parseFloatWithBounds(
      Deno.env.get("NVIDIA_NIM_TEMPERATURE"),
      0.4,
      0,
      1.5,
    ),
    topP: parseFloatWithBounds(Deno.env.get("NVIDIA_NIM_TOP_P"), 0.9, 0, 1),
    enableThinking: parseBooleanWithDefault(Deno.env.get("NVIDIA_NIM_ENABLE_THINKING"), false),
    clearThinking: parseBooleanWithDefault(Deno.env.get("NVIDIA_NIM_CLEAR_THINKING"), true),
  };
}

function parseConversationHistory(input: unknown): ConversationMessage[] {
  const rows = asArray(input).filter(isRecord).slice(-10);
  const parsed: ConversationMessage[] = [];

  for (const row of rows) {
    const role = asString(row.role).toLowerCase();
    const content = asString(row.content).trim();
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
  if (value === "nvidia") {
    return "nvidia";
  }
  return "invalid";
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
    max_tokens: params.maxTokens,
    temperature: params.temperature,
    top_p: params.topP,
    chat_template_kwargs: {
      enable_thinking: params.enableThinking,
      clear_thinking: params.clearThinking,
    },
  };

  try {
    const response = await fetch(`${params.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
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
        message: timedOut ? "NVIDIA request timeout" : String(error),
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

async function safeJson<T>(response: Response): Promise<T | null> {
  try {
    return (await response.json()) as T;
  } catch {
    return null;
  }
}
