# Witt — AI Routing Decision Matrix

**Version:** 1.0  
**Date:** February 2026  
**Status:** Approved — authoritative reference for all Phase 3 AI wiring

---

## Provider Assignment

| Provider | Tier | Features | Model | Limits |
|----------|------|----------|-------|--------|
| **Anthropic Claude** | Free + Paid | Exam/standardized test question generation ONLY. Free: serve from pre-generated pool (10-15 Qs). Paid exam sub: on-demand generation. | Claude 3.5 Sonnet | Free: static pool. Paid: unlimited on-demand. |
| **Groq AI (Llama)** | Free users | Sage chat, homework helper, quiz generation (non-exam), flashcard generation, note summarization, study planning | Llama 3.1 70B | 10 msgs/day Sage, 500 char input, ~500 word output, 300 msgs/month soft cap. Reset 00:00 UTC. |
| **OpenAI** | Paid users | Sage chat (GPT-4o), homework helper, quiz generation, flashcard generation, note summarization, study planning, voice dictation (Whisper), image generation (DALL-E 3), TTS | GPT-4o / GPT-4o-mini / Whisper / DALL-E 3 | Unlimited. Daily reset 00:00 UTC. Monthly reset 1st of month. |

---

## Routing Decision Tree

```
AI Feature Request
    │
    ├─ Exam/standardized test question generation?
    │       YES → Claude (Edge Fn: ai-exam-generate)
    │             Free: serve pre-gen pool
    │             Paid exam sub: generate on-demand
    │
    └─ General AI feature (non-exam)
            │
            ├─ Free user → Groq (Edge Fn: ai-chat / ai-homework / ai-quiz-generate / ai-flashcard-generate / ai-summarize)
            │               Enforce daily + monthly limits
            │
            └─ Paid user → OpenAI (same Edge Fns, provider param = openai)
                            No hard cap
```

---

## Edge Function Slugs (final)

| Slug | Provider(s) | Purpose |
|------|-------------|---------|
| `ai-chat` | Groq (free) / OpenAI (paid) | Sage chat — SSE streaming |
| `ai-exam-generate` | Claude | Exam question generation |
| `ai-homework` | Groq (free) / OpenAI (paid) | Homework step-by-step solver |
| `ai-quiz-generate` | Groq (free) / OpenAI (paid) | Quiz generation from topic/text |
| `ai-flashcard-generate` | Groq (free) / OpenAI (paid) | Flashcard deck generation |
| `ai-summarize` | Groq (free) / OpenAI (paid) | Note / lecture summarization |
| `ai-transcribe` | OpenAI Whisper (paid only) | Voice dictation / lecture transcription |
| `ai-tts` | OpenAI TTS (paid only) | Text-to-speech |

---

## Per-Module Provider Assignment

| Module | Free Provider | Paid Provider | Notes |
|--------|--------------|---------------|-------|
| M1 Test Prep (exam Qs) | Claude (pre-gen pool) | Claude (on-demand) | Always Claude regardless of plan |
| M2 Flashcard AI gen | Groq | OpenAI | Non-exam content |
| M3 Homework Helper | Groq | OpenAI | Step-by-step solver |
| M7 Note Summarization | Groq | OpenAI | Summarize + Q gen from notes |
| M8 Quiz Generator | Groq (non-exam) / Claude (exam) | OpenAI (non-exam) / Claude (exam) | Exam source → Claude |
| M13 Lecture Transcription | — (not available) | OpenAI Whisper | Paid only |
| M13 Lecture Summarization | Groq | OpenAI | After transcription |
| Sage Chat | Groq | OpenAI GPT-4o | SSE streaming |

---

## Free-Tier Limits (enforced in `sage_usage` table)

| Limit | Value | Reset |
|-------|-------|-------|
| Sage messages/day | 10 | 00:00 UTC daily |
| Sage messages/month soft cap | 300 | 1st of month |
| Sage input chars | 500 | Per message |
| Sage output words | ~500 | Per response |
| Homework solves/day | 5 | 00:00 UTC daily |
| Quiz generations/day | 1 | 00:00 UTC daily |
| Quiz questions per gen | 5 | Per generation |
| AI quiz Qs/month | 30 | 1st of month |
| Flashcard AI gen/day | 1 | 00:00 UTC daily |
| Note summarizations/day | 3 | 00:00 UTC daily |
| Lecture transcription | Not available | — |
| Attachments (Sage) | 1/day | 00:00 UTC daily |

---

## Resolved Spec Conflicts

1. **M2 flashcard AI gen provider:** Groq (free) / OpenAI (paid) — NOT Claude. Claude is exam questions only.
2. **M8 quiz gen:** Claude only when `source == QuizSource.fromExam` AND `examId` is set. All other sources → Groq/OpenAI.
3. **Catalog Milestone C:** 100+ exams — deferred to Session 3.4 (purchase flows). Pre-gen question pool expansion happens in 3.3.
4. **Subrail SDK:** Implemented as a local stub (no external SDK dependency) since `/Documents/Projects/subrail` is internal. Entitlement checks via `isPaidUserProvider` and `isExamUnlockedProvider`.

---

## Known Limitations & Future Work

### Usage Limit Persistence (Medium Priority)
`UsageNotifier` (in `witt_ai/src/providers/ai_providers.dart`) tracks daily/monthly usage counts **in-memory only**. Limits reset on app restart and are not enforced cross-device.

**Current behaviour:** Free-tier limits (e.g. 10 Sage messages/day) are enforced within a single app session only.

**Production fix required:** Persist usage records to Supabase `user_usage` table and hydrate on app start. The `UsageRecord` model and `recordUsage()` / `canUse()` / `limitMessage()` API are already designed to support this — only the persistence layer is missing.

### Purchase Flow (Medium Priority)
`PurchaseFlowNotifier.purchase()` is a local simulation (delay + grant trial). Real Subrail/RevenueCat SDK integration is required before App Store submission.

### Progress XP & Badges (Low Priority)
XP and badge state is in-memory (Riverpod `NotifierProvider`). Persisting to Supabase or Hive is needed for cross-session continuity.
