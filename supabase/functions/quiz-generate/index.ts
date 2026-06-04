import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const defaultMimoBaseUrl = "https://api.xiaomimimo.com/v1";
const defaultMimoQuizModel = "mimo-v2-flash";
const defaultEquranBaseUrl = "https://equran.id/api/v2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type SupportedLanguage = "id" | "en";
type Difficulty = "easy" | "medium" | "hard";

type AyahContext = {
  surahId: number;
  ayahNumber: number;
  arabic: string;
  translationId: string;
  translationEn: string;
  tafsir: string;
};

type SurahContext = {
  surahId: number;
  surahNameLatin: string;
  surahNameArabic: string;
  ayahs: AyahContext[];
};

type EquranFetchResult =
  | { ok: true; context: SurahContext; latencyMs: number; source: string; warnings?: string[] }
  | { ok: false; error: Record<string, unknown>; latencyMs: number };

type FetchJsonResult =
  | { ok: true; data: unknown }
  | { ok: false; error: Record<string, unknown> };

type MimoConfig = {
  baseUrl: string;
  apiKey: string;
  defaultModel: string;
  requestTimeoutMs: number;
  maxTokens: number;
  enableThinking: boolean;
};

type EnrichmentResult = {
  attempted: boolean;
  success: boolean;
  timedOut: boolean;
  latencyMs: number;
  enhancedCount: number;
  modelUsed: string | null;
  error?: Record<string, unknown>;
};

type FullGenerationResult = {
  attempted: boolean;
  success: boolean;
  timedOut: boolean;
  latencyMs: number;
  modelUsed: string | null;
  questionCount: number;
  quiz?: Record<string, unknown>;
  error?: Record<string, unknown>;
};

const enrichmentSystemInstruction = `
You are an Islamic learning assistant for Tawakkal.
Never modify, rewrite, or invent Arabic Quran text.
You only rewrite explanation and feedback fields.
Return valid JSON only.
Tone must be respectful, gentle, and educational.
Keep explanation concise (max 1-2 short sentences).
Keep feedback concise (max 1 short sentence per correct/incorrect).
`;

const fullGenerationSystemInstruction = `
You are an Islamic learning assistant for Tawakkal.
Generate cognitive, grounded Quran quiz questions.
Never modify Arabic Quran text. Use educational text only in requested language.
Return strict JSON only.
Each question must be multiple_choice with exactly 4 choices.
correct_choice_text must exactly match the text at correct_choice_id.
Every question must include ayah_refs and grounding_refs that cite provided context only.
Keep explanation <= 180 chars and feedback.correct/feedback.incorrect <= 120 chars.
`;

Deno.serve(async (req: Request) => {
  const startedAt = Date.now();
  const functionBudgetMs = parseIntWithBounds(
    Deno.env.get("MIMO_QUIZ_FUNCTION_BUDGET_MS") ??
      Deno.env.get("MIMO_FUNCTION_BUDGET_MS"),
    42000,
    10000,
    44000,
  );

  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed." }, 405);

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

  const surahId = asPositiveInt(body.surah_id);
  if (surahId === null) {
    return jsonResponse({ error: "Missing required fields. Required: surah_id." }, 400);
  }

  const language = normalizeLanguage(body.language);
  const difficulty = normalizeDifficulty(asString(body.difficulty));
  const questionCount = resolveQuestionCount(body.question_count, difficulty);
  const requestedSurahName = asString(body.surah_name);
  const generationMode = normalizeGenerationMode(
    body.generation_mode,
    Deno.env.get("QUIZ_GENERATION_MODE"),
  );
  const requestId = asString(body.request_id) || `req_${Date.now()}_${randomInt(1_000_000)}`;
  const recentSignatures = parseRecentSignatures(body.recent_signatures);
  const recentAyahRefs = extractRecentAyahRefs(recentSignatures);

  const remainingBeforeEquran = getRemainingBudgetMs({ startedAt, budgetMs: functionBudgetMs });
  if (remainingBeforeEquran <= 3500) {
    return jsonResponse(
      {
        error: "budget_exhausted_before_equran",
        details: { function_budget_ms: functionBudgetMs, elapsed_ms: Date.now() - startedAt },
      },
      502,
    );
  }

  const equranBaseUrl = normalizeBaseUrl(Deno.env.get("EQURAN_API_BASE") ?? defaultEquranBaseUrl);
  const equranTimeoutMs = Math.max(
    1500,
    Math.min(
      parseIntWithBounds(Deno.env.get("EQURAN_FETCH_TIMEOUT_MS"), 6000, 1500, 10000),
      remainingBeforeEquran - 2000,
    ),
  );

  const equran = await fetchEquranContext({
    baseUrl: equranBaseUrl,
    surahId,
    timeoutMs: equranTimeoutMs,
  });
  if (isEquranFetchFailure(equran)) {
    return jsonResponse(
      {
        error: "EQuran fetch failed.",
        details: { equran: equran.error, latency_ms: equran.latencyMs },
      },
      502,
    );
  }

  const resolvedSurahName = requestedSurahName || equran.context.surahNameLatin || `Surah ${surahId}`;
  let quiz: Record<string, unknown> | null = null;
  let generationInfo: FullGenerationResult = {
    attempted: false,
    success: false,
    timedOut: false,
    latencyMs: 0,
    modelUsed: null,
    questionCount: 0,
  };
  let fallbackReason: string | null = null;

  if (generationMode === "ai_first") {
    generationInfo = await maybeGenerateQuizWithAI({
      context: equran.context,
      surahName: resolvedSurahName,
      language,
      difficulty,
      questionCount,
      startedAt,
      functionBudgetMs,
      recentAyahRefs,
      requestId,
    });
    if (generationInfo.success && generationInfo.quiz) {
      quiz = generationInfo.quiz;
    } else {
      fallbackReason = asString(generationInfo.error?.reason) || "ai_generation_failed";
    }
  }

  if (quiz == null) {
    quiz = buildDeterministicQuiz({
      context: equran.context,
      surahName: resolvedSurahName,
      language,
      difficulty,
      questionCount,
      recentAyahRefs,
      requestId,
    });
    if (generationMode === "ai_first" && !fallbackReason) {
      fallbackReason = "ai_unavailable";
    }
  }

  const validation = validateAndRepairQuizPayload({
    quiz,
    language,
    difficulty,
    expectedQuestionCount: questionCount,
  });

  const meta: Record<string, unknown> = {
    provider_used: generationInfo.success ? "xiaomi_mimo" : "deterministic",
    model_used: generationInfo.success ? generationInfo.modelUsed : null,
    generation_mode: generationInfo.success ? "ai_first" : "deterministic",
    request_id: requestId,
    cognitive_profile: "bloom_ladder",
    anti_repeat_applied: recentAyahRefs.size > 0,
    equran_fetch: {
      source: equran.source,
      latency_ms: equran.latencyMs,
      ayah_count: equran.context.ayahs.length,
      warnings: equran.warnings ?? [],
    },
    validation,
  };
  if (fallbackReason) {
    meta.fallback_reason = fallbackReason;
  }
  if (generationInfo.attempted) {
    meta.ai_generation = {
      attempted: generationInfo.attempted,
      success: generationInfo.success,
      timed_out: generationInfo.timedOut,
      latency_ms: generationInfo.latencyMs,
      question_count: generationInfo.questionCount,
      error: generationInfo.error ?? null,
    };
  }

  const shouldRunEnrichment = !generationInfo.success;
  const aiResult = shouldRunEnrichment
    ? await maybeEnrichQuiz({
      quiz,
      language,
      difficulty,
      startedAt,
      functionBudgetMs,
    })
    : {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      enhancedCount: 0,
      modelUsed: null,
      error: { reason: "skipped_for_ai_generated_quiz" },
    };

  meta.ai_enrichment = {
    attempted: aiResult.attempted,
    success: aiResult.success,
    timed_out: aiResult.timedOut,
    latency_ms: aiResult.latencyMs,
    enhanced_count: aiResult.enhancedCount,
    error: aiResult.error ?? null,
  };

  if (aiResult.success && aiResult.modelUsed) {
    meta.provider_used = "xiaomi_mimo";
    meta.model_used = aiResult.modelUsed;
    meta.generation_mode = "deterministic_ai_enhanced";
  }

  meta.compaction = enforceQuizTextCompactness(quiz);

  meta.latency_ms = Date.now() - startedAt;
  meta.timed_out = false;

  return jsonResponse({ quiz, meta }, 200);
});

async function fetchEquranContext(params: {
  baseUrl: string;
  surahId: number;
  timeoutMs: number;
}): Promise<EquranFetchResult> {
  const startedAt = Date.now();

  const detailResponse = await fetchJsonWithTimeout(
    `${params.baseUrl}/surat/${params.surahId}`,
    params.timeoutMs,
  );
  if (isFetchJsonFailure(detailResponse)) {
    return {
      ok: false,
      error: { stage: "surah_detail", details: detailResponse.error },
      latencyMs: Date.now() - startedAt,
    };
  }

  const detailData = getEquranDataMap(detailResponse.data);
  if (!detailData) {
    return {
      ok: false,
      error: { stage: "surah_detail", details: "Invalid EQuran detail payload shape." },
      latencyMs: Date.now() - startedAt,
    };
  }

  const ayahs = asArray(detailData.ayat)
    .filter(isRecord)
    .map((item) => parseAyahContext(item, params.surahId))
    .filter((item): item is AyahContext => item !== null);

  if (ayahs.length === 0) {
    return {
      ok: false,
      error: { stage: "surah_detail", details: "No ayah data found from EQuran response." },
      latencyMs: Date.now() - startedAt,
    };
  }

  const warnings: string[] = [];
  const tafsirMap = new Map<number, string>();
  const tafsirResponse = await fetchJsonWithTimeout(
    `${params.baseUrl}/tafsir/${params.surahId}`,
    Math.max(1200, Math.floor(params.timeoutMs * 0.5)),
  );

  if (!isFetchJsonFailure(tafsirResponse)) {
    const tafsirData = getEquranDataMap(tafsirResponse.data);
    const tafsirRaw = tafsirData ? asArray(tafsirData.tafsir).filter(isRecord) : [];
    for (const row of tafsirRaw) {
      const ayahNumber = asPositiveInt(row.ayat);
      const text = asString(row.teks);
      if (ayahNumber !== null && text) tafsirMap.set(ayahNumber, text);
    }
  } else {
    warnings.push("tafsir_unavailable");
  }

  for (const ayah of ayahs) {
    ayah.tafsir = tafsirMap.get(ayah.ayahNumber) ?? "";
  }

  const context: SurahContext = {
    surahId: asPositiveInt(detailData.nomor) ?? params.surahId,
    surahNameLatin: asString(detailData.namaLatin),
    surahNameArabic: asString(detailData.nama),
    ayahs,
  };

  return {
    ok: true,
    context,
    latencyMs: Date.now() - startedAt,
    source: params.baseUrl,
    warnings: warnings.length > 0 ? warnings : undefined,
  };
}

function buildDeterministicQuiz(params: {
  context: SurahContext;
  surahName: string;
  language: SupportedLanguage;
  difficulty: Difficulty;
  questionCount: number;
  recentAyahRefs: Set<string>;
  requestId: string;
}): Record<string, unknown> {
  const selectedAyahs = pickAyahsForQuestions(
    params.context.ayahs,
    params.questionCount,
    params.recentAyahRefs,
  );
  const questions = selectedAyahs.map((ayah, index) =>
    buildDeterministicQuestion({
      context: params.context,
      ayah,
      index,
      language: params.language,
      difficulty: params.difficulty,
      surahName: params.surahName,
    })
  );

  const scoring = params.difficulty === "hard"
    ? { xp_per_correct: 16, completion_bonus: 40 }
    : params.difficulty === "medium"
    ? { xp_per_correct: 12, completion_bonus: 30 }
    : { xp_per_correct: 8, completion_bonus: 20 };

  return {
    quiz_id:
      `qz_s${String(params.context.surahId).padStart(3, "0")}_${params.difficulty}_${Date.now()}_${sanitizeIdFragment(params.requestId)}`,
    surah_id: params.context.surahId,
    surah_name: params.surahName,
    difficulty: params.difficulty,
    language: params.language,
    version: 1,
    questions,
    scoring,
  };
}

function buildDeterministicQuestion(params: {
  context: SurahContext;
  ayah: AyahContext;
  index: number;
  language: SupportedLanguage;
  difficulty: Difficulty;
  surahName: string;
}): Record<string, unknown> {
  const ref = `${params.context.surahId}:${params.ayah.ayahNumber}`;
  const correctText = selectTranslation(params.ayah, params.language);
  const grounded = buildGroundedExplanationAndFeedback({
    ayah: params.ayah,
    language: params.language,
    difficulty: params.difficulty,
    ref,
    translation: correctText,
  });
  const distractors = pickDistractors({
    ayahs: params.context.ayahs,
    excludeRef: ref,
    correctText,
    language: params.language,
  });
  const options = placeCorrectOption({ correctText, distractors });

  const groundingRefs: Array<Record<string, string>> = [
    { type: "ayah_ref", ref },
    { type: "translation_id", ref: `EQURAN:${ref}` },
  ];
  if (grounded.usedTafsir) {
    groundingRefs.push({ type: "tafsir_id", ref: `EQURAN_TAFSIR:${ref}` });
  }

  return {
    id: `q${params.index + 1}`,
    type: "multiple_choice",
    prompt: buildPrompt({
      language: params.language,
      difficulty: params.difficulty,
      surahName: params.surahName,
      ref,
    }),
    ayah_refs: [ref],
    choices: options.choices,
    correct_choice_id: options.correctChoiceId,
    correct_choice_text: options.correctChoiceText,
    explanation: grounded.explanation,
    feedback: grounded.feedback,
    grounding_refs: groundingRefs,
  };
}
function pickAyahsForQuestions(
  ayahs: AyahContext[],
  count: number,
  recentAyahRefs: Set<string>,
): AyahContext[] {
  if (ayahs.length === 0) return [];

  const deduped = dedupeAyahs(ayahs);
  const unseen = deduped.filter((ayah) => !recentAyahRefs.has(`${ayah.surahId}:${ayah.ayahNumber}`));
  const seen = deduped.filter((ayah) => recentAyahRefs.has(`${ayah.surahId}:${ayah.ayahNumber}`));
  shuffleInPlace(unseen);
  shuffleInPlace(seen);
  const pool = [...unseen, ...seen];
  if (pool.length === 0) {
    return [];
  }
  if (pool.length >= count) {
    return pool.slice(0, count);
  }
  const selected = [...pool];
  while (selected.length < count) {
    selected.push(pool[randomInt(pool.length)]);
  }
  return selected;
}

function pickDistractors(params: {
  ayahs: AyahContext[];
  excludeRef: string;
  correctText: string;
  language: SupportedLanguage;
}): string[] {
  const pool = params.ayahs
    .filter((ayah) => `${ayah.surahId}:${ayah.ayahNumber}` !== params.excludeRef)
    .map((ayah) => selectTranslation(ayah, params.language))
    .filter((text) => {
      const normalized = normalizeText(text);
      return normalized.length > 0 && normalized !== normalizeText(params.correctText);
    })
    .filter((text, index, arr) =>
      arr.findIndex((item) => normalizeText(item) === normalizeText(text)) === index
    );

  shuffleInPlace(pool);
  const picked = pool.slice(0, 3);

  while (picked.length < 3) picked.push(defaultDistractorText(params.language, picked.length));
  return picked.slice(0, 3);
}

function placeCorrectOption(params: {
  correctText: string;
  distractors: string[];
}): { choices: Array<Record<string, string>>; correctChoiceId: string; correctChoiceText: string } {
  const ids = ["a", "b", "c", "d"];
  const correctIndex = randomInt(4);
  const choices: Array<Record<string, string>> = [];
  let distractorCursor = 0;

  for (let i = 0; i < 4; i++) {
    if (i === correctIndex) {
      choices.push({ id: ids[i], text: params.correctText });
      continue;
    }
    choices.push({ id: ids[i], text: params.distractors[distractorCursor] ?? params.correctText });
    distractorCursor++;
  }

  return { choices, correctChoiceId: ids[correctIndex], correctChoiceText: params.correctText };
}

function buildPrompt(params: {
  language: SupportedLanguage;
  difficulty: Difficulty;
  surahName: string;
  ref: string;
}): string {
  if (params.language === "en") {
    const easyTemplates = [
      `Which translation best matches ayah ${params.ref} in Surah ${params.surahName}?`,
      `What is the closest meaning of ayah ${params.ref}?`,
      `The main message of ayah ${params.ref} is...`,
      `Which statement captures the direct meaning of ayah ${params.ref}?`,
      `Ayah ${params.ref} mainly teaches believers to understand...`,
    ];
    const mediumTemplates = [
      `In the context of Surah ${params.surahName}, ayah ${params.ref} emphasizes...`,
      `Which statement best reflects the meaning of ayah ${params.ref}?`,
      `Ayah ${params.ref} guides believers to...`,
      `How should the meaning of ayah ${params.ref} be applied in practice?`,
      `Which option best connects ayah ${params.ref} with everyday conduct?`,
    ];
    const hardTemplates = [
      `Which reflection is most aligned with the meaning of ayah ${params.ref}?`,
      `Based on ayah ${params.ref}, which interpretation is strongest?`,
      `What practical lesson is most consistent with ayah ${params.ref}?`,
      `Which evaluative conclusion is most defensible from ayah ${params.ref}?`,
      `How does ayah ${params.ref} most strongly shape moral judgment?`,
    ];
    const pool = params.difficulty === "hard"
      ? hardTemplates
      : params.difficulty === "medium"
      ? mediumTemplates
      : easyTemplates;
    return pool[randomInt(pool.length)];
  }

  const easyTemplates = [
    `Terjemahan yang paling sesuai untuk ayat ${params.ref} dalam Surah ${params.surahName} adalah...`,
    `Makna yang paling tepat dari ayat ${params.ref} adalah...`,
    `Pesan utama ayat ${params.ref} adalah...`,
    `Pernyataan yang paling menggambarkan makna langsung ayat ${params.ref} adalah...`,
    `Ayat ${params.ref} terutama mengajarkan...`,
  ];
  const mediumTemplates = [
    `Dalam konteks Surah ${params.surahName}, ayat ${params.ref} menekankan...`,
    `Pernyataan yang paling mencerminkan ayat ${params.ref} adalah...`,
    `Ayat ${params.ref} membimbing kita untuk...`,
    `Penerapan makna ayat ${params.ref} dalam kehidupan sehari-hari yang paling tepat adalah...`,
    `Pilihan yang paling menghubungkan ayat ${params.ref} dengan perilaku nyata adalah...`,
  ];
  const hardTemplates = [
    `Refleksi yang paling sejalan dengan makna ayat ${params.ref} adalah...`,
    `Berdasarkan ayat ${params.ref}, penafsiran yang paling kuat adalah...`,
    `Pelajaran praktik yang paling sesuai dari ayat ${params.ref} adalah...`,
    `Kesimpulan evaluatif yang paling kuat dari ayat ${params.ref} adalah...`,
    `Ayat ${params.ref} paling menuntun penilaian akhlak melalui...`,
  ];
  const pool = params.difficulty === "hard"
    ? hardTemplates
    : params.difficulty === "medium"
    ? mediumTemplates
    : easyTemplates;
  return pool[randomInt(pool.length)];
}

function buildGroundedExplanationAndFeedback(params: {
  language: SupportedLanguage;
  difficulty: Difficulty;
  ayah: AyahContext;
  translation: string;
  ref: string;
}): {
  explanation: string;
  feedback: Record<string, string>;
  usedTafsir: boolean;
} {
  const tafsirSummary = summarizeTafsir({
    tafsir: params.ayah.tafsir,
    language: params.language,
    difficulty: params.difficulty,
  });
  const usedTafsir = tafsirSummary.length > 0;

  if (params.language === "en") {
    const explanation = usedTafsir
      ? params.difficulty === "hard"
        ? `Ayah ${params.ref} teaches: "${params.translation}". Tafsir context highlights: ${tafsirSummary}. Reflect on how this guidance shapes worship and character.`
        : params.difficulty === "medium"
        ? `Ayah ${params.ref} means: "${params.translation}". Tafsir context: ${tafsirSummary}.`
        : `Ayah ${params.ref} means: "${params.translation}". Tafsir context: ${tafsirSummary}.`
      : params.difficulty === "hard"
      ? `Ayah ${params.ref} teaches: "${params.translation}". Reflect on how this guidance shapes worship and character.`
      : params.difficulty === "medium"
      ? `Ayah ${params.ref} means: "${params.translation}".`
      : `This answer follows the translation provided for ayah ${params.ref}.`;

    const feedback = usedTafsir
      ? {
        correct: `Correct. Your answer aligns with both the translation and tafsir context of ayah ${params.ref}.`,
        incorrect: `Not quite yet. Re-read ayah ${params.ref} and compare it with the tafsir context before choosing.`,
      }
      : {
        correct: `Correct. Your answer matches the translation of ayah ${params.ref}.`,
        incorrect: `Not quite yet. Re-read the translation of ayah ${params.ref} and choose the most direct meaning.`,
      };

    return { explanation, feedback, usedTafsir };
  }

  const explanation = usedTafsir
    ? params.difficulty === "hard"
      ? `Ayat ${params.ref} mengajarkan: "${params.translation}". Tafsir menekankan: ${tafsirSummary}. Renungkan penerapannya dalam ibadah dan akhlak.`
      : params.difficulty === "medium"
      ? `Makna ayat ${params.ref}: "${params.translation}". Konteks tafsir: ${tafsirSummary}.`
      : `Ayat ${params.ref} bermakna: "${params.translation}". Tafsir ringkas: ${tafsirSummary}.`
    : params.difficulty === "hard"
    ? `Ayat ${params.ref} mengajarkan: "${params.translation}". Renungkan penerapannya dalam ibadah dan akhlak.`
    : params.difficulty === "medium"
    ? `Makna ayat ${params.ref}: "${params.translation}".`
    : `Jawaban ini mengikuti terjemahan yang disediakan untuk ayat ${params.ref}.`;

  const feedback = usedTafsir
    ? {
      correct: `Benar. Jawaban Anda sejalan dengan terjemahan dan penjelasan tafsir ayat ${params.ref}.`,
      incorrect: `Belum tepat. Baca ulang terjemahan ayat ${params.ref}, lalu cermati petunjuk tafsirnya dengan tenang.`,
    }
    : {
      correct: `Benar. Jawaban Anda sesuai dengan terjemahan ayat ${params.ref}.`,
      incorrect: `Belum tepat. Baca ulang terjemahan ayat ${params.ref}, lalu pilih makna yang paling langsung.`,
    };

  return { explanation, feedback, usedTafsir };
}

function summarizeTafsir(params: {
  tafsir: string;
  language: SupportedLanguage;
  difficulty: Difficulty;
}): string {
  const raw = normalizeWhitespace(params.tafsir);
  if (!raw) {
    return "";
  }

  // Keep language consistency: avoid using Indonesian tafsir text in English mode.
  if (params.language === "en") {
    return "";
  }

  const maxChars = params.difficulty === "hard"
    ? 240
    : params.difficulty === "medium"
    ? 200
    : 160;

  if (raw.length <= maxChars) {
    return raw;
  }

  const trimmed = raw.slice(0, maxChars);
  const lastSentence = Math.max(
    trimmed.lastIndexOf("."),
    trimmed.lastIndexOf("!"),
    trimmed.lastIndexOf("?"),
  );
  const cutoff = lastSentence > maxChars * 0.6 ? lastSentence + 1 : trimmed.lastIndexOf(" ");
  const safe = cutoff > maxChars * 0.5 ? trimmed.slice(0, cutoff) : trimmed;
  return `${safe.trim()}...`;
}

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function deterministicExplanation(params: {
  language: SupportedLanguage;
  difficulty: Difficulty;
  translation: string;
  ref: string;
}): string {
  // Legacy helper kept for compatibility in case old call sites are restored.
  // New deterministic flow uses buildGroundedExplanationAndFeedback().
  if (params.language === "en") {
    if (params.difficulty === "hard") {
      return `This choice aligns with the core message of ayah ${params.ref}. Reflect on how this guidance applies in daily life.`;
    }
    if (params.difficulty === "medium") {
      return `This option matches the meaning of ayah ${params.ref}: "${params.translation}".`;
    }
    return `This answer follows the translation provided for ayah ${params.ref}.`;
  }

  if (params.difficulty === "hard") {
    return `Pilihan ini sejalan dengan pesan inti ayat ${params.ref}. Renungkan penerapannya dalam kehidupan sehari-hari.`;
  }
  if (params.difficulty === "medium") {
    return `Pilihan ini sesuai dengan makna ayat ${params.ref}: "${params.translation}".`;
  }
  return `Jawaban ini mengikuti terjemahan yang disediakan untuk ayat ${params.ref}.`;
}

function defaultFeedback(language: SupportedLanguage): Record<string, string> {
  if (language === "en") {
    return {
      correct: "Correct. Your understanding is on the right track.",
      incorrect: "Not quite right yet. Review the verse meaning calmly, then try again.",
    };
  }
  return {
    correct: "Benar. Pemahaman Anda sudah di jalur yang tepat.",
    incorrect: "Belum tepat. Tinjau kembali makna ayat dengan tenang, lalu coba lagi.",
  };
}

function defaultDistractorText(language: SupportedLanguage, index: number): string {
  if (language === "en") {
    const variants = [
      "A meaning that is not stated in the referenced ayah context.",
      "A statement from a different context than this ayah.",
      "An interpretation that does not match the requested verse.",
    ];
    return variants[index % variants.length];
  }
  const variants = [
    "Makna yang tidak disebutkan pada konteks ayat yang dirujuk.",
    "Pernyataan dari konteks yang berbeda dengan ayat ini.",
    "Penafsiran yang tidak sesuai dengan ayat yang ditanyakan.",
  ];
  return variants[index % variants.length];
}

function validateAndRepairQuizPayload(params: {
  quiz: Record<string, unknown>;
  language: SupportedLanguage;
  difficulty: Difficulty;
  expectedQuestionCount: number;
}): Record<string, number> {
  const quiz = params.quiz;
  const sourceQuestions = asArray(quiz.questions).filter(isRecord);
  const repairedQuestions: Record<string, unknown>[] = [];
  let repaired = 0;
  let dropped = 0;

  for (let index = 0; index < sourceQuestions.length; index++) {
    const question = sourceQuestions[index];
    const prompt = asString(question.prompt);
    if (!prompt) {
      dropped++;
      continue;
    }

    const choiceSource = (
      asArray(question.choices).filter(isRecord).length > 0
        ? asArray(question.choices).filter(isRecord)
        : asArray(question.options).filter(isRecord)
    );
    const uniqueTexts = new Set<string>();
    const choices: Array<Record<string, string>> = [];
    const choiceIds = ["a", "b", "c", "d"];
    for (let i = 0; i < choiceSource.length && choices.length < 4; i++) {
      const text = asString(choiceSource[i].text);
      if (!text) continue;
      const normalized = normalizeText(text);
      if (!normalized || uniqueTexts.has(normalized)) continue;
      uniqueTexts.add(normalized);
      choices.push({ id: choiceIds[choices.length], text });
    }
    while (choices.length < 4) {
      choices.push({
        id: choiceIds[choices.length],
        text: defaultDistractorText(params.language, choices.length),
      });
      repaired++;
    }

    const requestedCorrectId = asString(question.correct_choice_id).toLowerCase();
    let correctIndex = choiceIds.indexOf(requestedCorrectId);
    if (correctIndex < 0 || correctIndex >= choices.length) {
      const requestedCorrectText = asString(question.correct_choice_text);
      if (requestedCorrectText) {
        const byText = choices.findIndex((choice) => normalizeText(choice.text) === normalizeText(requestedCorrectText));
        correctIndex = byText >= 0 ? byText : 0;
      } else {
        correctIndex = 0;
      }
      repaired++;
    }
    const correctChoice = choices[correctIndex];

    const rawAyahRefs = asArray(question.ayah_refs).map((item) => asString(item)).filter((item) => item);
    const ayahRefs = rawAyahRefs.length > 0 ? rawAyahRefs.slice(0, 3) : ["-"];
    if (rawAyahRefs.length === 0) {
      repaired++;
    }

    const groundingRaw = asArray(question.grounding_refs).filter(isRecord);
    const groundingRefs = groundingRaw.length > 0
      ? groundingRaw.slice(0, 4).map((entry) => ({
        type: asString(entry.type) || "ayah_ref",
        ref: asString(entry.ref) || ayahRefs[0],
      }))
      : [{ type: "ayah_ref", ref: ayahRefs[0] }];
    if (groundingRaw.length === 0) {
      repaired++;
    }

    const feedbackInput = isRecord(question.feedback) ? question.feedback : {};
    const fallbackFeedback = defaultFeedback(params.language);
    const feedback = {
      correct: asString(feedbackInput.correct) || fallbackFeedback.correct,
      incorrect: asString(feedbackInput.incorrect) || fallbackFeedback.incorrect,
    };

    const fallbackExplanation = params.language === "en"
      ? params.difficulty === "hard"
        ? "This answer is most defensible when evaluated against the ayah context."
        : params.difficulty === "medium"
        ? "This answer aligns with the ayah meaning in its context."
        : "This answer matches the direct meaning of the ayah."
      : params.difficulty === "hard"
      ? "Jawaban ini paling kuat saat dievaluasi berdasarkan konteks ayat."
      : params.difficulty === "medium"
      ? "Jawaban ini selaras dengan makna ayat dalam konteksnya."
      : "Jawaban ini sesuai dengan makna langsung ayat.";
    const explanation = asString(question.explanation) || fallbackExplanation;
    if (!asString(question.explanation)) {
      repaired++;
    }

    repairedQuestions.push({
      id: asString(question.id) || `q${repairedQuestions.length + 1}`,
      type: "multiple_choice",
      prompt,
      ayah_refs: ayahRefs,
      choices,
      correct_choice_id: correctChoice.id,
      correct_choice_text: correctChoice.text,
      explanation,
      feedback,
      grounding_refs: groundingRefs,
    });
  }

  while (repairedQuestions.length < params.expectedQuestionCount && repairedQuestions.length > 0) {
    const seed = repairedQuestions[randomInt(repairedQuestions.length)];
    repairedQuestions.push({
      ...seed,
      id: `q${repairedQuestions.length + 1}`,
    });
    repaired++;
  }

  quiz.questions = repairedQuestions.slice(0, params.expectedQuestionCount);
  return { dropped_questions: dropped, repaired_questions: repaired };
}

function enforceQuizTextCompactness(quiz: Record<string, unknown>): Record<string, number> {
  const questions = asArray(quiz.questions).filter(isRecord);
  let explanation_clipped = 0;
  let feedback_clipped = 0;
  let answer_clipped = 0;

  for (const question of questions) {
    const rawExplanation = asString(question.explanation);
    const compactExplanation = compactEducationalText(rawExplanation, {
      maxChars: 180,
      maxSentences: 2,
    });
    if (compactExplanation && compactExplanation !== rawExplanation) {
      explanation_clipped++;
    }
    question.explanation = compactExplanation;

    const feedback = isRecord(question.feedback) ? question.feedback : {};
    const rawCorrect = asString(feedback.correct);
    const rawIncorrect = asString(feedback.incorrect);

    const compactCorrect = compactEducationalText(rawCorrect, {
      maxChars: 120,
      maxSentences: 1,
    });
    const compactIncorrect = compactEducationalText(rawIncorrect, {
      maxChars: 120,
      maxSentences: 1,
    });
    if (compactCorrect && compactCorrect !== rawCorrect) {
      feedback_clipped++;
    }
    if (compactIncorrect && compactIncorrect !== rawIncorrect) {
      feedback_clipped++;
    }
    question.feedback = {
      correct: compactCorrect,
      incorrect: compactIncorrect,
    };

    const rawAnswer = asString(question.correct_choice_text);
    const compactAnswer = compactEducationalText(rawAnswer, {
      maxChars: 90,
      maxSentences: 1,
    });
    if (compactAnswer && compactAnswer !== rawAnswer) {
      answer_clipped++;
    }
    question.correct_choice_text = compactAnswer;
  }

  return { explanation_clipped, feedback_clipped, answer_clipped };
}

function compactEducationalText(
  source: string,
  options: { maxChars: number; maxSentences: number },
): string {
  const normalized = normalizeWhitespace(source);
  if (!normalized) {
    return "";
  }

  const sentences = splitIntoSentences(normalized);
  let compact = sentences.length > 0
    ? sentences.slice(0, options.maxSentences).join(" ").trim()
    : normalized;

  if (compact.length > options.maxChars) {
    let clipped = compact.slice(0, options.maxChars).trim();
    const lastSpace = clipped.lastIndexOf(" ");
    if (lastSpace > Math.floor(options.maxChars * 0.6)) {
      clipped = clipped.slice(0, lastSpace).trim();
    }
    compact = clipped;
  }

  const truncated = compact.length < normalized.length;
  if (truncated) {
    const cleaned = compact.replace(/[\s.!?]+$/g, "").trim();
    return `${cleaned || compact}...`;
  }

  return compact;
}

function splitIntoSentences(source: string): string[] {
  const results: string[] = [];
  let cursor = "";
  for (let i = 0; i < source.length; i++) {
    const char = source[i];
    cursor += char;
    const isTerminal = char === "." || char === "!" || char === "?";
    const nextIsSpace = i + 1 >= source.length || source[i + 1] === " ";
    if (isTerminal && nextIsSpace) {
      const sentence = cursor.trim();
      if (sentence) {
        results.push(sentence);
      }
      cursor = "";
    }
  }
  const tail = cursor.trim();
  if (tail) {
    results.push(tail);
  }
  return results;
}

async function maybeGenerateQuizWithAI(params: {
  context: SurahContext;
  surahName: string;
  language: SupportedLanguage;
  difficulty: Difficulty;
  questionCount: number;
  startedAt: number;
  functionBudgetMs: number;
  recentAyahRefs: Set<string>;
  requestId: string;
}): Promise<FullGenerationResult> {
  const enabled = parseBooleanWithDefault(
    Deno.env.get("MIMO_QUIZ_ENABLE_FULL_GENERATION"),
    true,
  );
  if (!enabled) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      modelUsed: null,
      questionCount: 0,
      error: { reason: "full_generation_disabled" },
    };
  }

  const apiKey =
    Deno.env.get("MIMO_API_KEY") ??
    Deno.env.get("XIAOMI_MIMO_API_KEY") ??
    Deno.env.get("XIAOMI_API_KEY") ??
    "";
  if (!apiKey) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      modelUsed: null,
      questionCount: 0,
      error: { reason: "missing_mimo_api_key" },
    };
  }

  const remaining = getRemainingBudgetMs({ startedAt: params.startedAt, budgetMs: params.functionBudgetMs });
  if (remaining <= 6500) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      modelUsed: null,
      questionCount: 0,
      error: { reason: "insufficient_budget_for_full_generation" },
    };
  }

  const mimo: MimoConfig = {
    baseUrl: normalizeBaseUrl(
      Deno.env.get("MIMO_BASE_URL") ??
        Deno.env.get("XIAOMI_MIMO_BASE_URL") ??
        defaultMimoBaseUrl,
    ),
    apiKey,
    defaultModel: resolveMimoModel(
      Deno.env.get("MIMO_QUIZ_MODEL") ?? "",
      defaultMimoQuizModel,
    ),
    requestTimeoutMs: parseIntWithBounds(Deno.env.get("MIMO_QUIZ_FULL_TIMEOUT_MS"), 12000, 3000, 18000),
    maxTokens: parseIntWithBounds(
      Deno.env.get("MIMO_QUIZ_FULL_MAX_COMPLETION_TOKENS") ??
        Deno.env.get("MIMO_QUIZ_FULL_MAX_TOKENS"),
      2200,
      900,
      4096,
    ),
    enableThinking: parseBooleanWithDefault(Deno.env.get("MIMO_QUIZ_ENABLE_THINKING"), false),
  };

  const model = mimo.defaultModel;
  const timeoutMs = Math.max(2000, Math.min(mimo.requestTimeoutMs, remaining - 2200));
  const startedAt = Date.now();

  const contextCap = Math.max(
    params.questionCount * 3,
    params.difficulty === "hard" ? 20 : params.difficulty === "medium" ? 16 : 12,
  );
  const selectedContextAyahs = pickAyahsForQuestions(
    params.context.ayahs,
    Math.min(contextCap, Math.max(params.questionCount, params.context.ayahs.length)),
    params.recentAyahRefs,
  ).slice(0, contextCap);
  const ayahContext = selectedContextAyahs.map((ayah) => ({
    ref: `${ayah.surahId}:${ayah.ayahNumber}`,
    translation: selectTranslation(ayah, params.language),
    tafsir: summarizeTafsir({
      tafsir: ayah.tafsir,
      language: params.language,
      difficulty: params.difficulty,
    }),
  }));
  const cognitivePolicy = buildCognitivePolicy(params.language, params.difficulty);
  const nonce = `${Date.now()}_${randomInt(1_000_000)}`;

  const payload = {
    model,
    max_completion_tokens: mimo.maxTokens,
    stream: false,
    thinking: {
      type: mimo.enableThinking ? "enabled" : "disabled",
    },
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          `${fullGenerationSystemInstruction}\n${buildLanguageInstruction(params.language)}\n${cognitivePolicy}\nOutput JSON only with shape: {"questions":[{"id":"q1","type":"multiple_choice","prompt":"...","ayah_refs":["2:1"],"choices":[{"id":"a","text":"..."},{"id":"b","text":"..."},{"id":"c","text":"..."},{"id":"d","text":"..."}],"correct_choice_id":"a","correct_choice_text":"...","explanation":"...","feedback":{"correct":"...","incorrect":"..."},"grounding_refs":[{"type":"ayah_ref","ref":"2:1"},{"type":"translation_id","ref":"EQURAN:2:1"}]}]}.`,
      },
      {
        role: "user",
        content: JSON.stringify({
          task:
            "Generate randomized cognitive quiz questions. Avoid repeating stem phrasing across questions. Keep all claims grounded to provided context.",
          request_id: params.requestId,
          randomness_nonce: nonce,
          language: params.language,
          difficulty: params.difficulty,
          question_count: params.questionCount,
          recent_ayah_refs_to_avoid: Array.from(params.recentAyahRefs),
          surah: {
            id: params.context.surahId,
            name_latin: params.surahName,
          },
          ayah_context: ayahContext,
        }),
      },
    ],
  };

  const completion = await requestChatCompletion({
    baseUrl: mimo.baseUrl,
    apiKey: mimo.apiKey,
    payload,
    timeoutMs,
  });

  if (!completion.response.ok) {
    const body = completion.errorBody;
    return {
      attempted: true,
      success: false,
      timedOut: extractStatusCode(body) === 408,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_request_failed", details: body },
    };
  }

  const raw = await safeJson(completion.response);
  const content = coerceTextContent(raw?.choices?.[0]?.message?.content);
  if (!content) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_empty_content" },
    };
  }

  const jsonCandidate = extractLikelyJsonObject(sanitizeModelContent(content));
  if (!jsonCandidate) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_non_json" },
    };
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(jsonCandidate) as Record<string, unknown>;
  } catch (error) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_invalid_json", details: String(error) },
    };
  }

  const parsedQuiz = coerceQuizFromModelOutput({
    parsed,
    context: params.context,
    surahName: params.surahName,
    language: params.language,
    difficulty: params.difficulty,
    requestId: params.requestId,
  });
  if (!parsedQuiz) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_missing_quiz_structure" },
    };
  }

  const validation = validateAndRepairQuizPayload({
    quiz: parsedQuiz,
    language: params.language,
    difficulty: params.difficulty,
    expectedQuestionCount: params.questionCount,
  });
  const finalQuestions = asArray(parsedQuiz.questions).filter(isRecord);
  if (finalQuestions.length === 0) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      modelUsed: model,
      questionCount: 0,
      error: { reason: "mimo_full_generation_empty_after_repair", validation },
    };
  }

  return {
    attempted: true,
    success: true,
    timedOut: false,
    latencyMs: Date.now() - startedAt,
    modelUsed: model,
    questionCount: finalQuestions.length,
    quiz: parsedQuiz,
  };
}

async function maybeEnrichQuiz(params: {
  quiz: Record<string, unknown>;
  language: SupportedLanguage;
  difficulty: Difficulty;
  startedAt: number;
  functionBudgetMs: number;
}): Promise<EnrichmentResult> {
  const enabled = parseBooleanWithDefault(
    Deno.env.get("MIMO_QUIZ_ENABLE_EXPLANATION_ENRICHMENT"),
    false,
  );
  if (!enabled) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      enhancedCount: 0,
      modelUsed: null,
      error: { reason: "disabled_by_config" },
    };
  }

  const apiKey =
    Deno.env.get("MIMO_API_KEY") ??
    Deno.env.get("XIAOMI_MIMO_API_KEY") ??
    Deno.env.get("XIAOMI_API_KEY") ??
    "";
  if (!apiKey) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      enhancedCount: 0,
      modelUsed: null,
      error: { reason: "missing_mimo_api_key" },
    };
  }

  const remaining = getRemainingBudgetMs({ startedAt: params.startedAt, budgetMs: params.functionBudgetMs });
  if (remaining <= 6000) {
    return {
      attempted: false,
      success: false,
      timedOut: false,
      latencyMs: 0,
      enhancedCount: 0,
      modelUsed: null,
      error: { reason: "insufficient_budget_for_enrichment" },
    };
  }

  const mimo: MimoConfig = {
    baseUrl: normalizeBaseUrl(
      Deno.env.get("MIMO_BASE_URL") ??
        Deno.env.get("XIAOMI_MIMO_BASE_URL") ??
        defaultMimoBaseUrl,
    ),
    apiKey,
    defaultModel: resolveMimoModel(
      Deno.env.get("MIMO_QUIZ_MODEL") ?? "",
      defaultMimoQuizModel,
    ),
    requestTimeoutMs: parseIntWithBounds(Deno.env.get("MIMO_QUIZ_ENRICH_TIMEOUT_MS"), 9000, 2000, 15000),
    maxTokens: parseIntWithBounds(
      Deno.env.get("MIMO_QUIZ_MAX_COMPLETION_TOKENS") ??
        Deno.env.get("MIMO_QUIZ_MAX_TOKENS"),
      900,
      256,
      2048,
    ),
    enableThinking: parseBooleanWithDefault(Deno.env.get("MIMO_QUIZ_ENABLE_THINKING"), false),
  };

  const model = mimo.defaultModel;
  const timeoutMs = Math.max(1500, Math.min(mimo.requestTimeoutMs, remaining - 2000));

  const startedAt = Date.now();
  const compactQuestions = asArray(params.quiz.questions)
    .filter(isRecord)
    .map((question) => ({
      id: asString(question.id),
      prompt: asString(question.prompt),
      correct_choice_text: asString(question.correct_choice_text),
      ayah_refs: asArray(question.ayah_refs).map((item) => asString(item)),
    }));

  const payload = {
    model,
    max_completion_tokens: mimo.maxTokens,
    stream: false,
    thinking: {
      type: mimo.enableThinking ? "enabled" : "disabled",
    },
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          `${enrichmentSystemInstruction}\n${buildLanguageInstruction(params.language)}\nOutput JSON only with shape: {\"items\":[{\"id\":\"q1\",\"explanation\":\"...\",\"feedback\":{\"correct\":\"...\",\"incorrect\":\"...\"}}]}.\nKeep explanation <= 180 characters and each feedback <= 120 characters.`,
      },
      {
        role: "user",
        content: JSON.stringify({
          task:
            "Improve only explanation and feedback text for each question. Do not change answer keys. Keep explanation to 1-2 short sentences and feedback to 1 short sentence each.",
          language: params.language,
          difficulty: params.difficulty,
          questions: compactQuestions,
        }),
      },
    ],
  };

  const completion = await requestChatCompletion({
    baseUrl: mimo.baseUrl,
    apiKey: mimo.apiKey,
    payload,
    timeoutMs,
  });

  if (!completion.response.ok) {
    const body = completion.errorBody;
    return {
      attempted: true,
      success: false,
      timedOut: extractStatusCode(body) === 408,
      latencyMs: Date.now() - startedAt,
      enhancedCount: 0,
      modelUsed: model,
      error: { message: "mimo enrichment request failed", details: body },
    };
  }

  const raw = await safeJson(completion.response);
  const content = coerceTextContent(raw?.choices?.[0]?.message?.content);
  if (!content) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      enhancedCount: 0,
      modelUsed: model,
      error: { message: "mimo enrichment returned empty content" },
    };
  }

  const jsonCandidate = extractLikelyJsonObject(sanitizeModelContent(content));
  if (!jsonCandidate) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      enhancedCount: 0,
      modelUsed: model,
      error: { message: "mimo enrichment returned non-JSON content" },
    };
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(jsonCandidate) as Record<string, unknown>;
  } catch (error) {
    return {
      attempted: true,
      success: false,
      timedOut: false,
      latencyMs: Date.now() - startedAt,
      enhancedCount: 0,
      modelUsed: model,
      error: { message: "mimo enrichment returned invalid JSON", details: String(error) },
    };
  }

  const updates = asArray(parsed.items).filter(isRecord);
  const questions = asArray(params.quiz.questions).filter(isRecord);
  const questionMap = new Map<string, Record<string, unknown>>();
  for (const question of questions) {
    const id = asString(question.id);
    if (id) questionMap.set(id, question);
  }

  let enhancedCount = 0;
  for (const update of updates) {
    const id = asString(update.id);
    if (!id || !questionMap.has(id)) continue;

    const target = questionMap.get(id)!;
    const nextExplanation = asString(update.explanation);
    const nextFeedback = isRecord(update.feedback) ? update.feedback : null;
    const nextCorrect = nextFeedback ? asString(nextFeedback.correct) : "";
    const nextIncorrect = nextFeedback ? asString(nextFeedback.incorrect) : "";

    let updated = false;
    if (nextExplanation && !isMostlyArabic(nextExplanation)) {
      target.explanation = compactEducationalText(nextExplanation, {
        maxChars: 180,
        maxSentences: 2,
      });
      updated = true;
    }

    if (nextFeedback) {
      const existingFeedback = isRecord(target.feedback) ? target.feedback : defaultFeedback(params.language);
      const defaults = defaultFeedback(params.language);
      target.feedback = {
        correct: compactEducationalText(
          nextCorrect && !isMostlyArabic(nextCorrect)
            ? nextCorrect
            : asString(existingFeedback.correct) || defaults.correct,
          { maxChars: 120, maxSentences: 1 },
        ),
        incorrect: compactEducationalText(
          nextIncorrect && !isMostlyArabic(nextIncorrect)
            ? nextIncorrect
            : asString(existingFeedback.incorrect) || defaults.incorrect,
          { maxChars: 120, maxSentences: 1 },
        ),
      };
      updated = true;
    }

    if (updated) enhancedCount++;
  }

  return {
    attempted: true,
    success: enhancedCount > 0,
    timedOut: false,
    latencyMs: Date.now() - startedAt,
    enhancedCount,
    modelUsed: model,
    error: enhancedCount > 0 ? undefined : { message: "mimo enrichment produced no applicable updates" },
  };
}
function parseAyahContext(source: Record<string, unknown>, fallbackSurahId: number): AyahContext | null {
  const ayahNumber = asPositiveInt(source.nomorAyat);
  if (ayahNumber === null) return null;
  return {
    surahId: asPositiveInt(source.nomorSurat) ?? fallbackSurahId,
    ayahNumber,
    arabic: asString(source.teksArab),
    translationId: asString(source.teksIndonesia),
    translationEn: asString(source.teksInggris),
    tafsir: "",
  };
}

function selectTranslation(ayah: AyahContext, language: SupportedLanguage): string {
  if (language === "en") return ayah.translationEn || ayah.translationId || ayah.arabic;
  return ayah.translationId || ayah.translationEn || ayah.arabic;
}

function getEquranDataMap(payload: unknown): Record<string, unknown> | null {
  if (!isRecord(payload)) return null;
  const nested = payload.data;
  return isRecord(nested) ? nested : null;
}

async function fetchJsonWithTimeout(
  url: string,
  timeoutMs: number,
): Promise<FetchJsonResult> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort("upstream_timeout"), timeoutMs);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: { Accept: "application/json" },
      signal: controller.signal,
    });

    if (!response.ok) {
      return {
        ok: false,
        error: {
          code: response.status,
          message: `Upstream request failed for ${url}`,
          body: await safeJson(response),
        },
      };
    }
    return { ok: true, data: await response.json() };
  } catch (error) {
    const timeoutError = isAbortError(error);
    return {
      ok: false,
      error: {
        code: timeoutError ? 408 : 502,
        message: timeoutError ? `Upstream request timed out for ${url}` : String(error),
      },
    };
  } finally {
    clearTimeout(timeoutId);
  }
}

function isEquranFetchFailure(result: EquranFetchResult): result is {
  ok: false;
  error: Record<string, unknown>;
  latencyMs: number;
} {
  return result.ok === false;
}

function isFetchJsonFailure(result: FetchJsonResult): result is {
  ok: false;
  error: Record<string, unknown>;
} {
  return result.ok === false;
}

function jsonResponse(payload: unknown, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function requestChatCompletion(params: {
  baseUrl: string;
  apiKey: string;
  payload: Record<string, unknown>;
  timeoutMs?: number;
}) {
  const timeoutMs = params.timeoutMs ?? 30000;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort("upstream_timeout"), timeoutMs);
  let response: Response;

  try {
    response = await fetch(`${params.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "api-key": params.apiKey,
        Authorization: `Bearer ${params.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(params.payload),
      signal: controller.signal,
    });
  } catch (error) {
    const timeoutError = isAbortError(error);
    const statusCode = timeoutError ? 408 : 502;
    const failurePayload = {
      error: {
        code: statusCode,
        message: timeoutError ? "upstream request timed out" : String(error),
      },
    };

    return {
      response: new Response(JSON.stringify(failurePayload), {
        status: statusCode,
        headers: { "Content-Type": "application/json" },
      }),
      errorBody: failurePayload,
    };
  } finally {
    clearTimeout(timeoutId);
  }

  const errorBody = response.ok ? null : await safeJson(response);
  return { response, errorBody };
}

function buildLanguageInstruction(language: SupportedLanguage): string {
  if (language === "en") {
    return "Language policy: Use English only for prompt, explanation, and feedback text. Do not use Arabic in educational text fields.";
  }
  return "Language policy: Gunakan Bahasa Indonesia saja untuk prompt, explanation, dan feedback. Jangan gunakan bahasa Arab pada teks edukasi.";
}

function normalizeLanguage(input: unknown): SupportedLanguage {
  const raw = typeof input === "string" ? input.trim().toLowerCase() : "id";
  return raw === "en" ? "en" : "id";
}

function normalizeDifficulty(input: string): Difficulty {
  const value = input.trim().toLowerCase();
  if (value === "hard") return "hard";
  if (value === "medium") return "medium";
  return "easy";
}

function normalizeGenerationMode(
  input: unknown,
  envDefault: string | undefined,
): "ai_first" | "deterministic" {
  const fromBody = asString(input).toLowerCase();
  if (fromBody === "deterministic") return "deterministic";
  if (fromBody === "ai_first") return "ai_first";
  const fallback = asString(envDefault).toLowerCase();
  return fallback === "deterministic" ? "deterministic" : "ai_first";
}

function parseRecentSignatures(input: unknown): string[] {
  return asArray(input)
    .map((item) => asString(item))
    .map((item) => item.trim())
    .filter((item) => item.length > 0)
    .slice(0, 80);
}

function extractRecentAyahRefs(signatures: string[]): Set<string> {
  const refs = new Set<string>();
  for (const signature of signatures) {
    const matches = signature.match(/\b\d+:\d+\b/g) ?? [];
    for (const ref of matches) {
      refs.add(ref);
    }
  }
  return refs;
}

function resolveQuestionCount(input: unknown, difficulty: Difficulty): number {
  const requested = asPositiveInt(input);
  if (requested !== null) return Math.max(1, Math.min(10, requested));
  if (difficulty === "hard") return 6;
  if (difficulty === "medium") return 5;
  return 3;
}

function buildCognitivePolicy(language: SupportedLanguage, difficulty: Difficulty): string {
  if (language === "en") {
    if (difficulty === "easy") {
      return "Cognitive policy: Easy level must target recall/comprehension with clear direct meaning questions.";
    }
    if (difficulty === "medium") {
      return "Cognitive policy: Medium level must target application/analysis with context-based or practical inference questions.";
    }
    return "Cognitive policy: Hard level must target evaluation/reflection with defensible interpretation and moral judgment reasoning.";
  }
  if (difficulty === "easy") {
    return "Kebijakan kognitif: Level mudah fokus pada ingatan/pemahaman dengan pertanyaan makna langsung.";
  }
  if (difficulty === "medium") {
    return "Kebijakan kognitif: Level menengah fokus pada aplikasi/analisis dengan konteks dan penerapan.";
  }
  return "Kebijakan kognitif: Level sulit fokus pada evaluasi/refleksi dengan penafsiran yang dapat dipertanggungjawabkan.";
}

function coerceQuizFromModelOutput(params: {
  parsed: Record<string, unknown>;
  context: SurahContext;
  surahName: string;
  language: SupportedLanguage;
  difficulty: Difficulty;
  requestId: string;
}): Record<string, unknown> | null {
  const root = isRecord(params.parsed.quiz) ? params.parsed.quiz : params.parsed;
  if (!isRecord(root)) {
    return null;
  }

  const rootQuestions = asArray(root.questions).filter(isRecord);
  const itemQuestions = asArray(root.items).filter(isRecord);
  if (rootQuestions.length === 0 && itemQuestions.length > 0) {
    root.questions = itemQuestions;
  }
  if (asArray(root.questions).length === 0) {
    return null;
  }

  root.quiz_id ??=
    `qz_s${String(params.context.surahId).padStart(3, "0")}_${params.difficulty}_${Date.now()}_${sanitizeIdFragment(params.requestId)}`;
  root.surah_id ??= params.context.surahId;
  root.surah_name ??= params.surahName;
  root.difficulty ??= params.difficulty;
  root.language ??= params.language;
  root.version ??= 1;
  root.scoring ??= params.difficulty === "hard"
    ? { xp_per_correct: 16, completion_bonus: 40 }
    : params.difficulty === "medium"
    ? { xp_per_correct: 12, completion_bonus: 30 }
    : { xp_per_correct: 8, completion_bonus: 20 };

  return root;
}

function resolveMimoModel(input: string, fallback: string): string {
  const model = normalizeModelId(input).replace(/^xiaomi\//i, "");
  if (!model) return fallback;
  return model.startsWith("mimo-") ? model : fallback;
}

function parseProvider(input: unknown): "xiaomi" | "invalid" | null {
  if (input == null) return null;
  if (typeof input !== "string") return "invalid";
  const value = input.trim().toLowerCase();
  if (!value) return null;
  if (value === "xiaomi" || value === "mimo" || value === "xiaomi_mimo") return "xiaomi";
  if (value === "nvidia" || value === "nim") return "xiaomi";
  return "invalid";
}

function parseIntWithBounds(value: string | undefined, fallback: number, min: number, max: number): number {
  if (!value) return fallback;
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(min, Math.min(max, parsed));
}

function parseBooleanWithDefault(value: string | undefined, fallback: boolean): boolean {
  if (!value) return fallback;
  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) return true;
  if (["0", "false", "no", "off"].includes(normalized)) return false;
  return fallback;
}

function dedupeAyahs(ayahs: AyahContext[]): AyahContext[] {
  const seen = new Set<string>();
  const results: AyahContext[] = [];
  for (const ayah of ayahs) {
    const key = `${ayah.surahId}:${ayah.ayahNumber}`;
    if (seen.has(key)) continue;
    seen.add(key);
    results.push(ayah);
  }
  return results;
}

function shuffleInPlace<T>(items: T[]): void {
  for (let i = items.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [items[i], items[j]] = [items[j], items[i]];
  }
}

function randomInt(maxExclusive: number): number {
  if (maxExclusive <= 1) return 0;
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return array[0] % maxExclusive;
}

function sanitizeIdFragment(value: string): string {
  const cleaned = value.replace(/[^a-zA-Z0-9]/g, "");
  if (!cleaned) {
    return String(Date.now()).slice(-8);
  }
  return cleaned.slice(-8);
}

function getRemainingBudgetMs(params: { startedAt: number; budgetMs: number }): number {
  const elapsed = Date.now() - params.startedAt;
  return Math.max(0, params.budgetMs - elapsed);
}

function normalizeBaseUrl(baseUrl: string): string {
  return baseUrl.replace(/\/+$/, "");
}

function normalizeModelId(model: string): string {
  return model.replace(/\\/g, "/").trim();
}

function asString(value: unknown): string {
  if (typeof value === "string") return value.trim();
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  return "";
}

function asPositiveInt(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) return Math.trunc(value);
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed) && parsed > 0) return parsed;
  }
  return null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function normalizeText(value: string): string {
  return value.replace(/\s+/g, " ").trim().toLowerCase();
}

function isMostlyArabic(value: string): boolean {
  if (!value || value.trim().length < 4) return false;

  let letters = 0;
  let arabicLetters = 0;
  for (const ch of value) {
    if (/\p{L}/u.test(ch)) {
      letters++;
      if (/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/u.test(ch)) arabicLetters++;
    }
  }

  if (letters === 0) return false;
  return arabicLetters / letters >= 0.45;
}

function extractStatusCode(source: unknown): number | null {
  if (!isRecord(source)) return null;
  const err = source.error;
  if (!isRecord(err)) return null;
  const code = err.code;
  if (typeof code === "number" && Number.isFinite(code)) return code;
  if (typeof code === "string") {
    const parsed = Number.parseInt(code, 10);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function coerceTextContent(content: unknown): string | null {
  if (typeof content === "string") return content;

  if (content && typeof content === "object") {
    const candidate = content as { text?: unknown };
    if (typeof candidate.text === "string") {
      const text = candidate.text.trim();
      return text.length > 0 ? text : null;
    }
  }

  if (Array.isArray(content)) {
    const text = content
      .map((part) => {
        if (typeof part === "string") return part;
        if (part && typeof part === "object") {
          const candidate = part as { text?: unknown };
          if (typeof candidate.text === "string") return candidate.text;
        }
        return "";
      })
      .join("")
      .trim();

    return text.length > 0 ? text : null;
  }

  return null;
}

function sanitizeModelContent(content: string): string {
  let sanitized = content.trim();
  if (!sanitized) return sanitized;
  sanitized = sanitized.replace(/<\s*think[\s\S]*?<\/\s*think\s*>/gi, "").trim();
  sanitized = sanitized.replace(/```json/gi, "```");
  if (!sanitized) return sanitized;
  return extractJsonBlock(sanitized);
}

function extractJsonBlock(content: string): string {
  const trimmed = content.trim();
  if (!trimmed.startsWith("```")) return trimmed;
  const withoutOpenFence = trimmed.replace(/^```(?:json)?\s*/i, "");
  return withoutOpenFence.replace(/\s*```$/, "").trim();
}

function extractLikelyJsonObject(content: string): string | null {
  const trimmed = content.trim();
  if (!trimmed) return null;
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) return trimmed;

  const firstBrace = trimmed.indexOf("{");
  if (firstBrace < 0) return null;

  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = firstBrace; i < trimmed.length; i++) {
    const ch = trimmed[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      escaped = true;
      continue;
    }
    if (ch === "\"") {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (ch === "{") {
      depth++;
    } else if (ch === "}") {
      depth--;
      if (depth === 0) return trimmed.slice(firstBrace, i + 1);
    }
  }
  return null;
}

function isAbortError(error: unknown): boolean {
  if (!error) return false;
  if (error instanceof DOMException) return error.name === "AbortError";
  return String(error).toLowerCase().includes("abort");
}

async function safeJson(response: Response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}
