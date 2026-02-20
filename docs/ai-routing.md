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
4. **Subrail SDK:** Billing SDK at `/Documents/Projects/subrail` (not yet populated). Currently implemented as a simulated stub in `PurchaseFlowNotifier`. Entitlement checks via `isPaidUserProvider` and `isExamUnlockedProvider`. Integration blocked until Subrail SDK is populated.

---

## Known Limitations & Future Work

### Usage Limit Persistence ✅ Resolved
`HiveUsageNotifier` (`apps/witt_app/lib/core/persistence/persistent_notifiers.dart`) persists all daily/monthly usage counters to Hive box `ai_usage`. Hydrates on app start, flushes on every `recordUsage()` call. Daily and monthly resets are preserved correctly across restarts.

### Progress XP, Badges, Streak & Activity ✅ Resolved
All progress state is now Hive-persisted via subclasses in `persistent_notifiers.dart`:
- `HiveXpNotifier` → `kBoxProgress / xp`
- `HiveBadgeNotifier` → `kBoxProgress / badges`
- `HiveStreakNotifier` → `kBoxProgress / streak_*`
- `HiveDailyActivityNotifier` → `kBoxProgress / daily_activity` (JSON-encoded map)

All 5 in-memory providers are overridden at `ProviderScope` level in `main.dart` — zero call-site changes required.

### Purchase Flow ✅ Resolved
`PurchaseFlowNotifier` (`packages/witt_monetization/lib/src/providers/entitlement_provider.dart`) now calls the real Subrail Flutter SDK. All 3 methods are wired:

- `purchase()` → `Subrail.getProducts()` + `Subrail.purchaseProduct()` + `_applyCustomerInfo()`
- `restore()` → `Subrail.restorePurchases()` + `_applyCustomerInfo()`
- `purchaseExam()` → `Subrail.getProducts()` + `Subrail.purchaseProduct()` + `unlockExam()`

`_applyCustomerInfo()` maps Subrail `CustomerInfo` entitlements to the app's `Entitlement` model (handles `premium_monthly`, `premium_yearly`, `lifetime`, trial period detection).

**SDK initialization:** `Subrail.configure()` is called in `bootstrap.dart` on app start (sandbox in debug, warn log level in prod). Supabase user identity is synced via `Subrail.logIn(userId)` / `Subrail.logOut()` on every auth state change.

**Runtime requirement:** `SUBRAIL_API_KEY` must be set in `.env.dev` / `.env.staging` / `.env.prod`. SDK silently skips initialization if the key is missing (purchase calls will surface an error state). See `docs/env` for key location.

**Remaining pre-launch work:**
- Cross-device entitlement hydration on app start (currently only updated on purchase/restore — requires calling `Subrail.getCustomerInfo()` on auth and applying the result via `_applyCustomerInfo()`).
- App Store / Play Store product IDs must match the identifiers configured in the Subrail dashboard (`witt_premium_monthly`, `witt_premium_yearly`, `exam_<examId>`).
