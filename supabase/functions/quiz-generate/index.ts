import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const quizJsonSchema = {
  type: "object",
  additionalProperties: true,
  required: [
    "quiz_id",
    "surah_id",
    "surah_name",
    "difficulty",
    "language",
    "version",
    "questions",
    "scoring",
  ],
  properties: {
    quiz_id: { type: "string" },
    surah_id: { type: "integer" },
    surah_name: { type: "string" },
    difficulty: { type: "string", enum: ["easy", "medium", "hard"] },
    language: { type: "string" },
    version: { type: "integer" },
    questions: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        additionalProperties: true,
        required: [
          "id",
          "type",
          "prompt",
          "ayah_refs",
          "choices",
          "correct_choice_id",
          "explanation",
          "feedback",
          "grounding_refs",
        ],
        properties: {
          id: { type: "string" },
          type: {
            type: "string",
            enum: ["multiple_choice", "matching", "ordering", "reflection"],
          },
          prompt: { type: "string" },
          ayah_refs: { type: "array", items: { type: "string" } },
          choices: {
            type: "array",
            minItems: 2,
            items: {
              type: "object",
              additionalProperties: true,
              required: ["id", "text"],
              properties: {
                id: { type: "string" },
                text: { type: "string" },
              },
            },
          },
          correct_choice_id: { type: "string" },
          explanation: { type: "string" },
          feedback: {
            type: "object",
            additionalProperties: true,
            required: ["correct", "incorrect"],
            properties: {
              correct: { type: "string" },
              incorrect: { type: "string" },
            },
          },
          grounding_refs: {
            type: "array",
            minItems: 1,
            items: {
              type: "object",
              additionalProperties: true,
              required: ["type", "ref"],
              properties: {
                type: { type: "string" },
                ref: { type: "string" },
              },
            },
          },
        },
      },
    },
    scoring: {
      type: "object",
      additionalProperties: true,
      required: ["xp_per_correct", "completion_bonus"],
      properties: {
        xp_per_correct: { type: "integer" },
        completion_bonus: { type: "integer" },
      },
    },
  },
};

const defaultSystemInstruction = `
You are an Islamic learning assistant for Tawakkal.
Never modify, rewrite, or invent Arabic Quran text.
Use only grounding material provided by the user payload.
Return valid JSON only.
Tone must be respectful, gentle, and educational.
`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "Method not allowed." },
      405,
    );
  }

  const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openAiApiKey) {
    return jsonResponse(
      { error: "OPENAI_API_KEY is not configured in function secrets." },
      500,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON payload." }, 400);
  }

  const surahId = Number(body.surah_id ?? 0);
  const surahName = String(body.surah_name ?? "");
  const difficulty = String(body.difficulty ?? "easy");
  const language = String(body.language ?? "id");
  const model = String(
    body.model ?? Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini",
  );
  const prompt = String(body.prompt ?? "");
  const systemInstruction = String(
    body.system_instruction ?? defaultSystemInstruction,
  );

  if (!surahId || !surahName || !prompt) {
    return jsonResponse(
      {
        error:
          "Missing required fields. Required: surah_id, surah_name, prompt.",
      },
      400,
    );
  }

  const openAiPayload = {
    model,
    temperature: 0.3,
    messages: [
      {
        role: "system",
        content: systemInstruction,
      },
      {
        role: "user",
        content: prompt,
      },
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "tawakkal_quiz_payload",
        strict: true,
        schema: quizJsonSchema,
      },
    },
  };

  const openAiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(openAiPayload),
  });

  if (!openAiResponse.ok) {
    const errBody = await safeJson(openAiResponse);
    return jsonResponse(
      {
        error: "OpenAI request failed.",
        details: errBody,
      },
      502,
    );
  }

  const completion = await safeJson(openAiResponse);
  const content = completion?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.length === 0) {
    return jsonResponse(
      { error: "OpenAI returned empty quiz content." },
      502,
    );
  }

  let quiz;
  try {
    quiz = JSON.parse(content);
  } catch {
    return jsonResponse(
      { error: "OpenAI returned invalid JSON in quiz content." },
      502,
    );
  }

  quiz.surah_id ??= surahId;
  quiz.surah_name ??= surahName;
  quiz.difficulty ??= difficulty;
  quiz.language ??= language;
  quiz.version ??= 1;

  if (!Array.isArray(quiz.questions) || quiz.questions.length === 0) {
    return jsonResponse(
      { error: "Generated quiz has no questions." },
      502,
    );
  }

  return jsonResponse(quiz, 200);
});

function jsonResponse(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function safeJson(response: Response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

