# Witt — Comprehensive Implementation Plan

**Version:** 1.0  
**Date:** February 2026  
**Reference:** `docs/main.md`  
**Repository:** [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)  
**Methodology:** Sequential phases → sessions → deliverables

> 6 phases, ~30 sessions. Each session = 1–3 days of dev effort with clear deliverables and acceptance criteria.

---

## Dependency Map

```text
Phase 0: Project Scaffold & Infrastructure
    │
    ▼
Phase 1: Core App Shell & Auth
    │
    ├─────────────────────────────┐
    ▼                             ▼
Phase 2: Core Learning       Phase 3: AI & Monetization
    │                             │
    └────────────┬────────────────┘
                 ▼
Phase 4: Social, Games & Secondary
                 │
                 ▼
Phase 5: Polish, Platform & Launch
```

---

## Phase 0 — Project Scaffold & Infrastructure

**Goal:** Monorepo, CI/CD, Supabase, database schema, foundational packages. No feature UI — a blank 5-tab navigation scaffold is acceptable as the app shell placeholder.  
**Duration:** 3 sessions (~1 week)

---

### Session 0.1 — Monorepo & Flutter Project Setup

**Ref:** `main.md §2.1, §2.6`

- [ ] Melos monorepo: `apps/witt_app`, `packages/` (witt_core, witt_ui, witt_api, witt_ai, witt_auth, witt_storage, witt_monetization), `supabase/`
- [ ] Flutter 3.x stable, Dart 3.x, Riverpod, GoRouter with 5-tab placeholder routes
- [ ] `build_runner`, `freezed`, `json_serializable`, `flutter_lints` (strict)

**Done when:** `melos bootstrap` succeeds, app launches on iOS sim + Android emulator with blank 5-tab scaffold.

---

### Session 0.2 — Supabase Project & Database Schema

**Ref:** `main.md §3.4, §2.5`

- [ ] All 30+ tables from §3.4 created via migrations with RLS policies
- [ ] Auth configured: Email/password, Google, Apple, Phone OTP, Anonymous
- [ ] Storage buckets: `avatars`, `audio`, `images`, `exports`, `content-packs`
- [ ] Seed data: exam catalog for 5 initial exams (SAT, GRE, WAEC, JAMB, IELTS) — **Catalog Milestone A**
- [ ] Exam catalog schema supports all 5 pricing tiers (§9.3) and bundle discount rules

> **Supabase MCP enabled** — use the Supabase MCP server throughout this session to create tables, apply migrations, generate RLS policies, and manage the database. All schema changes must be applied via MCP-driven migrations (not manual SQL in the dashboard) to keep the migration history clean and reproducible.

**Done when:** Migrations applied, RLS active, auth providers configured, seed data queryable.

> **Catalog Rollout Plan** (tracked across sessions):
> - **Milestone A** (Session 0.2): 5 exams seeded (SAT, GRE, WAEC, JAMB, IELTS)
> - **Milestone B** (Session 2.1): 30 exams across all regions — at least 3 per pricing tier, covering US/UK/Africa/India/Latin America
> - **Milestone C** (Session 3.4): 100+ exams — full §7 catalog with tier mapping, bundle config, and per-exam scoring methodology

---

### Session 0.3 — CI/CD, Error Tracking & Analytics

**Ref:** `main.md §2.5, §2.6`

- [ ] GitHub Actions: lint → test → build (iOS + Android)
- [ ] Codemagic for release builds
- [ ] Sentry, Mixpanel/PostHog SDKs integrated
- [ ] **OneSignal SDK integrated** — single SDK handles push for all 5 platforms: APNs (iOS/macOS), FCM (Android), Huawei Push Kit (HuaweiOS), Windows Toast (Windows). Configure OneSignal app ID in all environment configs.
- [ ] Environment configs: `.env.dev`, `.env.staging`, `.env.prod` (include `ONESIGNAL_APP_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`)

**Done when:** Push to `main` triggers CI, Sentry captures test crash, analytics logs `app_open`, OneSignal test notification delivered on iOS and Android.

> **Phase 0 — GitHub Push**  
> Commit all scaffold, schema migrations, CI config, and environment files.  
> `git add . && git commit -m "phase-0: project scaffold, supabase schema, ci/cd" && git push origin main`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Phase 1 — Core App Shell & Auth

**Goal:** Onboarding, auth, bottom nav, Home tab, design system. User can install → onboard → auth → Home.  
**Duration:** 5 sessions (~2 weeks)

---

### Session 1.1 — Design System & Theme

**Ref:** `main.md §4.1, §4.4`

- [ ] `witt_ui`: brand colors, typography, spacing, light/dark/system themes
- [ ] Shared widgets: WittButton, WittCard, WittChip, WittBadge, WittAvatar, WittProgressBar, WittBottomSheet
- [ ] Bottom nav bar (5 tabs) with active/inactive states, badge indicators
- [ ] Tablet/Desktop: left sidebar rail variant
- [ ] Sound effect utility (placeholder audio files)

**Done when:** Themed bottom nav renders on all platforms. Light/dark toggle works.

---

### Session 1.2 — Onboarding Flow (Screens 1–4)

**Ref:** `main.md §5.1 (Screens 1-4)`

- [ ] Boot Screen (flutter_native_splash)
- [ ] Splash/Marketing: 4 swipeable slides, Lottie/Rive, dot indicators, Skip, auto-advance
- [ ] Language Picker: 21 languages, GeoIP pre-selection, native script + flags
- [ ] Setup Wizard Q1–Q10: varied UI formats (cards, radio, dropdown, chips, date picker, slider, toggles)
- [ ] Progress bar, back nav, Hive persistence, `onboarding_step` tracking

**Done when:** Full wizard offline. Kill/relaunch resumes at exact screen.

---

### Session 1.3 — Auth Screen & Supabase Auth

**Ref:** `main.md §5.1 (Screen 5), §2.5`

- [ ] Auth UI: Apple, Google, Email, Phone OTP, Skip (anonymous)
- [ ] `witt_auth` package: AuthRepository with all auth methods
- [ ] On auth: wizard data syncs Hive → Supabase `users`
- [ ] Token management (Secure Storage), silent refresh
- [ ] Anonymous → full account conversion flow

**Done when:** All 4 auth methods + anonymous work. Token persists. Wizard data syncs.

---

### Session 1.4 — Paywall Screens (6, 7, 8) & Subrail

**Ref:** `main.md §5.1 (Screens 6-8), §9.1–9.6`

- [ ] `witt_monetization`: WittMonetization class, AIProvider enum, entitlement checks
- [ ] Screen 6 — General Paywall (Free/Monthly $9.99/Yearly $59.99)
- [ ] Screen 7 — Feature Comparison (14-feature checklist)
- [ ] Screen 8 — Free Trial Explainer (timeline, 7-day trial CTA)
- [ ] Paywall state flags, skip logic, GeoIP currency display

**Done when:** Paywall sequence works. "Continue with Free" → Home. Paid → store sheet (sandbox).

---

### Session 1.5 — Home Tab & Subsequent Access

**Ref:** `main.md §4.3 (Tab 1), §4.2, §5.2`

- [ ] Home Screen: streak banner, study plan, continue studying, exam countdowns, daily challenge, word of the day, quick actions, recent activity, recommendations (all placeholder where modules not built)
- [ ] Home Header: greeting, 🔍 Search, 🔔 Notifications, 🎮 Play Hub
- [ ] GoRouter redirect with paywall state flags
- [ ] Subsequent access: Boot → auth check → Home or Onboarding

**Done when:** Full onboarding → Home end-to-end. Subsequent launches skip onboarding.

> **Phase 1 — GitHub Push**  
> Commit design system, onboarding screens, auth, paywall, and Home tab.  
> `git add . && git commit -m "phase-1: design system, onboarding, auth, paywall, home tab" && git push origin main`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Phase 2 — Core Learning Modules

**Goal:** Test prep, flashcards, homework helper, mock tests, notes, vocabulary, quiz gen, study planner.  
**Duration:** 8 sessions (~3 weeks)

---

### Session 2.1 — Question Engine & Exam Data Model

**Ref:** `main.md §8, §7`

- [ ] Question model (all types: MCQ, T/F, fill-blank, short answer, essay, passage-based, etc.)
- [ ] Full-screen interactive question widget: LaTeX, code blocks, passage rendering, audio/visual feedback, timer, explanation panel, bookmark
- [ ] QuestionAttempt model, exam catalog data (5 exams), 10-15 pre-generated Qs per exam — **Catalog Milestone A live**
- [ ] Expand catalog to 30 exams across US/UK/Africa/India/Latin America with tier pricing assigned — **Catalog Milestone B**
- [ ] Per-exam scoring methodology, section structure, and timing rules configured for all 30 exams

**Done when:** User answers a SAT Math question with full interactive UX. Attempt logged and synced. 30-exam catalog queryable with correct tier pricing.

---

### Session 2.2 — M1: Test Prep Engine

**Ref:** `main.md M1, §5.3`

- [ ] Learn → My Exams grid → Exam Hub (readiness, sections, topics, history, bookmarks)
- [ ] Topic Drill: pre-generated pool (free) / AI placeholder (paid)
- [ ] TestPrepEngine: getPreGeneratedQuestions, generateAdaptiveQuestions (placeholder), updateProficiency (IRT)
- [ ] Session Results, paywall trigger after free pool exhausted

**Done when:** Free user practices SAT with pre-gen Qs, sees results, hits paywall.

---

### Session 2.3 — M2: Flashcard System

**Ref:** `main.md M2, §5.4`

- [ ] Deck CRUD, 5 card types, 5 study modes (Flashcard, Learn, Write, Match, Test)
- [ ] SM-2 spaced repetition algorithm
- [ ] Import/Export (CSV, TSV), session complete screen, offline caching

**Done when:** Create deck → study in all modes → SM-2 scheduling works across sessions.

---

### Session 2.4 — M7: Notes & M6: Vocabulary

**Ref:** `main.md M7, M6`

- [ ] **Notes:** Rich text editor, organization, templates, export (PDF/DOCX/MD), free limits (10 notes, 2K words)
- [ ] **Vocabulary:** Dictionary with audio, Word of the Day, subject lists, personal lists, auto-flashcard gen, quiz, offline DB, free limits (3 lists, 25 words)

**Done when:** Notes with rich formatting export to PDF. Dictionary works with audio. Saved words auto-generate flashcards.

---

### Session 2.5 — M4: Mock Tests

**Ref:** `main.md M4, §5.6`

- [ ] ExamConfig model, full-length simulation with section timers, exam conditions mode
- [ ] Scoring per exam methodology, post-test analytics, score trajectory chart
- [ ] Free: 1 mock/exam. Paid: unlimited (AI-gen wired in Phase 3)

**Done when:** Full SAT mock test with timed sections, scoring, and analytics.

---

### Session 2.6 — M8: Quiz Generator & M3: Homework Helper (UI)

**Ref:** `main.md M8, M3, §5.5`

- [ ] **Quiz Gen:** All input methods, generation config, customization, sharing, library. AI = placeholder.
- [ ] **Homework Helper:** Camera scan, OCR, AI processing placeholder, step-by-step solution view, actions.

**Done when:** Quiz gen UI complete. Homework camera + OCR works. AI returns mock data (real AI in Phase 3).

---

### Session 2.7 — Learn Tab Assembly & Offline Sync

**Ref:** `main.md §4.3 (Tab 2), §3.3, §11`

- [ ] Learn Tab: filter chips, card grid, search, FAB. All module screens accessible.
- [ ] `witt_storage`: offline sync engine (outbox queue, conflict resolver, content downloader)
- [ ] SQLite local mirror, connectivity listener, Downloads screen

**Done when:** Learn tab features work offline. Pending changes sync on reconnect.

---

### Session 2.8 — M15: Study & Exam Planner

**Ref:** `main.md M15`

- [ ] Smart Schedule Builder, auto-redistribution, syllabus upload, daily goals, assignment tracking, calendar view
- [ ] Exam Tracker: registry, history, trends, countdowns, target tracking, deadline reminders
- [ ] Home Tab "Today's Study Plan" now shows real data

**Done when:** Study plan generates from exam dates, shows on Home. Calendar renders. Score trends visible.

---

### Session 2.9 — M12: Offline Mode & Content Pack Manager

**Ref:** `main.md M12, §11`

- [ ] **Content Pack types** implemented: Exam Pack (Free, 1-5MB), Exam Pack (Premium, 10-50MB), Dictionary Pack (~200MB), Language Pack (30-80MB), Vocabulary Pack (5-20MB), Flashcard Pack (1-10MB)
- [ ] **Download Manager UI:** browse available packs with size estimates, Wi-Fi-only toggle, pause/resume, storage usage display, auto-update on connect
- [ ] **Offline Feature Matrix parity** verified against `main.md §M12` table: pre-gen questions, flashcard modes, cached homework solutions, downloaded mocks, brain challenges, dictionary, notes, cached quizzes, dashboard, single-player games, study planner, offline translation all work without network
- [ ] **Storage Management:** total usage display in Settings, per-pack breakdown, Clear Cache option (preserves user data), Delete Pack per pack, low-storage warning at < 500MB free
- [ ] **Sync Protocol** end-to-end: write-local-first → outbox queue → connectivity listener → push on reconnect → pull remote changes → conflict resolution (server authority for shared, last-write-wins for personal) → sync timestamp update
- [ ] Free tier: 1 content pack at a time. Paid: unlimited downloads.

**Done when:** App fully functional in airplane mode using downloaded packs. Offline activity syncs correctly on reconnect. Storage manager shows accurate usage.

> **Phase 2 — GitHub Push**  
> Commit all core learning modules (M1–M9, M12, M15), question engine, offline sync, and study planner.  
> `git add . && git commit -m "phase-2: core learning modules, question engine, offline mode, study planner" && git push origin main`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Phase 3 — AI Integration & Monetization

**Goal:** Wire Groq/OpenAI/Claude, AI routing layer, Subrail purchases, all AI features live.  
**Duration:** 6 sessions (~2 weeks)

---

### Session 3.0 — Spec Reconciliation Gate

**Ref:** `main.md §2.2, §9.3, §9.6, M1, M2, M3, M8, M13`

> **Gate session** — no code shipped. Resolve all spec ambiguities before AI wiring begins.

- [ ] **AI provider table audit:** confirm every module's provider assignment is consistent across §2.2, §9.6, and each module definition (M1–M13). Document final routing table: Groq (free, general) / OpenAI (paid, general) / Claude (exam generation, both tiers)
- [ ] **M2 flashcard AI generation:** confirm provider is Groq (free) / OpenAI (paid) — not Claude. Update `main.md M2` if stale reference found.
- [ ] **M8 exam-specific quiz generation:** confirm Claude is used when `examId` is set, Groq/OpenAI otherwise. Verify this is consistent in §M8 and §9.6.
- [ ] **Catalog Milestone C readiness:** confirm all 100+ exams from §7 are mapped to pricing tiers (§9.3) before Session 3.4 purchase flow implementation
- [ ] **Free-tier limits table (§9.4) sign-off:** all limits confirmed by product owner before enforcement is coded
- [ ] **Edge Function naming convention agreed:** finalize function slugs (`ai-chat`, `ai-exam-generate`, etc.) before Session 3.1 scaffolds them
- [ ] Produce a one-page **AI Routing Decision Matrix** (stored in `docs/ai-routing.md`) as the authoritative reference for all AI wiring sessions

**Done when:** AI Routing Decision Matrix document exists and is approved. No open spec conflicts remain. All team members aligned before coding begins.

---

### Session 3.1 — AI Provider Routing Layer

**Ref:** `main.md §2.2`

- [ ] `witt_ai`: AIRouter, GroqClient, OpenAIClient, ClaudeClient (all via Supabase Edge Functions)
- [ ] Edge Functions: `ai-chat`, `ai-exam-generate`, `ai-homework`, `ai-quiz-generate`, `ai-summarize`, `ai-flashcard-generate`, `ai-transcribe`, `ai-image-generate`, `ai-tts`
- [ ] Rate limiting middleware (check `sage_usage`, enforce caps)
- [ ] Daily reset cron (00:00 UTC), monthly reset cron (1st of month)

**Done when:** Requests route to Groq (free) / OpenAI (paid) / Claude (exam). Rate limits enforced. Crons work.

---

### Session 3.2 — Sage AI Chat Bot (Tab 3)

**Ref:** `main.md §4.3 (Tab 3: Sage)`

- [ ] Full chat interface: SSE streaming, rich rendering (markdown, LaTeX, code, images)
- [ ] Conversation history, suggested prompts, context injection
- [ ] All modes: Chat, Explain, Homework, Quiz, Planning, Flashcard Gen, Lecture Summary
- [ ] Free: Groq, 10 msgs/day, limited modes, mic greyed out
- [ ] Paid: GPT-4o, unlimited, dictation (Whisper), all modes
- [ ] Message count badge, upgrade banner, offline queue

**Done when:** Free user chats with Groq, hits limit. Paid user gets GPT-4o + dictation. All modes work.

---

### Session 3.3 — AI-Powered Feature Wiring

**Ref:** `main.md M1, M2, M3, M7, M8, M13`

- [ ] M1: Claude exam generation for paid exam subs
- [ ] M3: Real AI homework solving (Groq free / OpenAI paid)
- [ ] M8: Real AI quiz generation with limits
- [ ] M2: AI flashcard deck generation
- [ ] M7: AI note summarization
- [ ] M13: Lecture recording, Whisper transcription (paid), AI summarization, notes view, export

**Done when:** All AI features end-to-end with correct provider routing and limits.

---

### Session 3.4 — Subrail Full Integration & Purchase Flows

**Ref:** `main.md §9.1–9.8, §5.9`

- [ ] Subrail SDK: StoreKit 2 (iOS), Play Billing (Android), Huawei IAP, MS Store (placeholders)
- [ ] General Premium purchase flow (§5.9a)
- [ ] Exam subscription purchase flow (§5.9b) — weekly/monthly/yearly, 5 pricing tiers
- [ ] Bundle discounts (3-exam 20% off, 5-exam 30% off, Regional Bundle, All-Access Exam Pass)
- [ ] Currency/pricing strategy: GeoIP detection, USD base, EUR/GBP 1:1 parity, daily exchange rate cache
- [ ] Restore purchases, subscription management in Profile
- [ ] **Catalog Milestone C:** all 100+ exams from §7 live in catalog with correct tier mapping, bundle config, and per-exam scoring methodology — **Catalog Milestone C**

**Done when:** Premium + exam subscriptions purchasable via store sandbox. Entitlements activate. Currency correct per region. Full 100+ exam catalog live with tier pricing.

---

### Session 3.5 — M9: Progress Dashboard & Analytics

**Ref:** `main.md M9`

- [ ] Dashboard: streak, XP/level, study hours, exam analytics, topic breakdown, study habits
- [ ] Gamification: XP, levels, badges, streak calendar
- [ ] Leaderboards: global, friends, school
- [ ] Export progress report as PDF
- [ ] Home Tab streak/XP now real data

**Done when:** Dashboard shows real data. Charts render. XP/badges accumulate. Leaderboard populates.

> **Phase 3 — GitHub Push**  
> Commit AI routing layer, all AI-wired features, Subrail purchase flows, full exam catalog, and progress dashboard.  
> `git add . && git commit -m "phase-3: ai routing, groq/openai/claude wiring, subrail purchases, full exam catalog" && git push origin main`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Phase 4 — Social, Games & Secondary Modules

**Goal:** Community, games, teacher/parent portals, translation.  
**Duration:** 5 sessions (~2 weeks)

---

### Session 4.1 — M10: Community & Social (Tab 4)

**Ref:** `main.md M10, §4.3 (Tab 4)`

- [ ] Social Tab: Feed / Groups / Forum / Marketplace segments
- [ ] Study Groups, Q&A Forum, Deck Marketplace, Friend System
- [ ] Content moderation (AI + reports)
- [ ] Free limits: read-only feed, 2 groups, 1 post/day

**Done when:** Groups, forum, marketplace, friends all functional. Moderation works. Free limits enforced.

---

### Session 4.2 — M11: Teacher & Parent Portal

**Ref:** `main.md M11, §5.10, §5.11`

- [ ] **Teacher:** Class management, student roster, assignments, grading dashboard, class leaderboard
- [ ] **Parent:** Link to child, activity overview, progress reports, notification digest
- [ ] Role-based routing from onboarding Q1

**Done when:** Teacher creates class, assigns work, views grades. Parent links to child, views reports.

---

### Session 4.3 — M14: Games & M5: Brain Challenges

**Ref:** `main.md M14, M5, §5.7`

- [ ] Play Hub: featured game, games library, daily challenge, multiplayer lobby, brain challenges, stats, leaderboards
- [ ] 9 games: Word Duel, Quiz Royale, Equation Rush, Fact or Fiction, Crossword Builder, Memory Match, Timeline Challenge, Spelling Bee, Subject Boss Battles
- [ ] Brain Challenges: daily challenge, categories, difficulty tiers, streaks
- [ ] Multiplayer via Supabase Realtime
- [ ] Free: 3 games/day, single-player. Paid: unlimited, multiplayer.

**Done when:** All 9 games playable. Daily challenge works. Multiplayer connects. XP/leaderboards update.

---

### Session 4.4 — Realtime Translation System

**Ref:** `main.md §10, §2.4`

- [ ] Online: Google Cloud Translation / DeepL integration
- [ ] Offline: TF Lite / ML Kit on-device models, language pack manager (~30-80MB/pair)
- [ ] Translation for AI content, community content, exam content
- [ ] Language switcher in Settings, 21 languages

**Done when:** Language switch shows translated content. Offline translation works with downloaded packs.

---

### Session 4.5 — Profile Tab Assembly & Settings

**Ref:** `main.md §4.3 (Tab 5)`

- [ ] Profile: header, dashboard, exam tracker, achievements, stats, subscriptions, downloads
- [ ] Settings: account, notifications, language, currency, theme, sound, accessibility
- [ ] Help & Support, About

**Done when:** Profile fully functional with real data. Settings changes persist immediately.

> **Phase 4 — GitHub Push**  
> Commit social/community, games, teacher/parent portals, translation system, and profile tab.  
> `git add . && git commit -m "phase-4: social, games, teacher/parent portals, translation, profile" && git push origin main`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Phase 5 — Polish, Platform-Specific & Launch

**Goal:** Security, platform optimization, performance, accessibility, testing, store submission.  
**Duration:** 4 sessions (~1.5 weeks)

---

### Session 5.1 — Security, Privacy & Compliance

**Ref:** `main.md §12`

- [ ] RLS audit, API key security (server-side only), encryption (at-rest + in-transit)
- [ ] GDPR: data export, account deletion, consent. COPPA: age-gating, parental consent.
- [ ] Privacy policy, Terms of Service, content moderation review
- [ ] Secure Storage for tokens

**Done when:** Security audit passes. GDPR export works. Account deletion purges data.

---

### Session 5.2 — Platform-Specific Optimization

**Ref:** `main.md §13`

- [ ] **iOS (§13.1)**
  - [ ] Min iOS 15+, App Store metadata (screenshots, description, keywords)
  - [ ] StoreKit 2 via Subrail SDK, Apple Sign-In enforced
  - [ ] APNs push via OneSignal
  - [ ] `BGTaskScheduler` for background sync and content downloads
  - [ ] iOS home screen widgets: daily challenge, streak counter, exam countdown
  - [ ] Siri Shortcuts: "Start studying [exam]"
  - [ ] iPad: split-screen multitasking, keyboard shortcuts, Apple Pencil support for M7 notes
  - [ ] Universal Links configured

- [ ] **macOS (§13.2)**
  - [ ] Min macOS 12+, Mac App Store + notarized DMG (direct download)
  - [ ] StoreKit 2 (App Store) + Stripe integration (direct download path)
  - [ ] Native menu bar, keyboard shortcuts, multi-window support
  - [ ] Drag-and-drop file import (lectures, PDFs), system-level notifications
  - [ ] Touch Bar support (legacy Macs), full file system access for lecture import/export
  - [ ] Wider editor layout for M7 note-taking

- [ ] **Android (§13.3)**
  - [ ] Min Android 7.0+ (API 24), Google Play metadata
  - [ ] Google Play Billing via Subrail SDK
  - [ ] FCM push via OneSignal
  - [ ] WorkManager for background sync
  - [ ] Android home screen widgets (daily challenge, streak, countdown)
  - [ ] Material You dynamic color theming (Android 12+)
  - [ ] Adaptive icons, App Links, back-button handling
  - [ ] Multi-pane responsive layout for tablets

- [ ] **HuaweiOS / HarmonyOS (§13.4)**
  - [ ] HMS Core integration, HMS Push Kit routed through OneSignal (replaces direct FCM)
  - [ ] Huawei IAP via Subrail SDK
  - [ ] AppGallery metadata and submission
  - [ ] HMS Account Kit for auth (Google Sign-In not available)

- [ ] **Windows (§13.5)**
  - [ ] MS Store metadata and submission
  - [ ] MS Store IAP integration
  - [ ] Windows Toast notifications via OneSignal
  - [ ] Native title bar, window resizing, keyboard-first navigation
  - [ ] Tablet/Desktop sidebar rail navigation (all desktop platforms)

**Done when:** App runs natively and passes smoke tests on all 5 platforms. All store metadata prepared. Platform-specific features verified per checklist above.

---

### Session 5.3 — Performance, Accessibility & Testing

**Ref:** `main.md §2.6, §4.4, §5.10–§5.13, §9`

- [ ] **Performance:** Startup < 2s, 60fps scrolling, lazy loading, SQLite indexes, memory profiling

- [ ] **Accessibility:** VoiceOver/TalkBack, semantic labels, touch targets (48x48dp), WCAG AA contrast, dynamic type

- [ ] **Unit & Widget Tests:** Unit tests (80%+ coverage), widget tests (critical flows), integration tests (Patrol), AI routing tests, offline sync tests

- [ ] **Deep-Link Conformance Tests (§4.4)**
  - [ ] `witt://home` → Home tab
  - [ ] `witt://learn/exam/sat` → SAT Exam Hub
  - [ ] `witt://sage` → Sage AI tab
  - [ ] `witt://home/play/quiz-royale` → Play Hub → Quiz Royale (nested under Home stack)
  - [ ] `witt://community` → Social tab
  - [ ] `witt://profile` → Profile tab
  - [ ] Deep link while unauthenticated → onboarding → auth → intended destination
  - [ ] Deep link while onboarding incomplete → resume onboarding at saved step
  - [ ] Push notification deep links resolve correctly on cold start and from background

- [ ] **User-Flow Conformance Tests**
  - [ ] **§5.10 Teacher Flow:** sign-up as Teacher → class creation → assign quiz → view grades → class analytics
  - [ ] **§5.11 Parent Flow:** sign-up as Parent → link to child via invite code → view activity overview → receive weekly report
  - [ ] **§5.12 Offline Flow:** go offline → use pre-downloaded content → all offline-capable features work → reconnect → pending changes sync → no data loss
  - [ ] **§5.13 Summary Map:** end-to-end smoke test covering all 9 onboarding steps → auth → paywall → Home → Learn → Sage → Social → Profile

- [ ] **Monetization Edge-Case Test Matrix**
  - [ ] Free user hits exam question limit → paywall shown → "Continue Free" → returns to app
  - [ ] Free user purchases exam subscription → entitlement activates → AI questions unlock immediately
  - [ ] Premium subscription purchase → entitlement activates → all premium features unlock
  - [ ] Restore purchases → correct entitlements restored on new device / reinstall
  - [ ] Subscription expires mid-session → graceful downgrade, no crash, paywall shown on next AI request
  - [ ] 7-day trial starts → trial reminder notification fires at day 5 → trial ends → downgrade to free
  - [ ] 3-exam bundle discount applied correctly → 20% off combined price
  - [ ] All-Access Exam Pass → all exam entitlements active → individual exam paywalls suppressed
  - [ ] GeoIP currency detection → correct local currency shown on paywall screens
  - [ ] Manual currency override in Settings → pricing display updates immediately
  - [ ] Annual-to-monthly plan change → correct billing period, no double-charge
  - [ ] Huawei IAP purchase flow (HMS) → entitlement activates same as iOS/Android

**Done when:** Benchmarks met. Accessibility audit passes. All deep-link routes verified. All user-flow conformance tests pass. Monetization edge-case matrix fully green. Test suite at 80%+ coverage.

---

### Session 5.4 — Store Submission & Launch

- [ ] Submit to: App Store, Google Play, Huawei AppGallery, Microsoft Store
- [ ] Production Supabase, API keys, Subrail, OneSignal, Sentry, analytics
- [ ] Launch monitoring dashboards, rollback plan documented

**Done when:** App live on all 5 stores. Monitoring active. No P0 crashes in first 24 hours.

> **Phase 5 — GitHub Push**  
> Commit security hardening, platform-specific optimizations, test suite, and final store submission assets. Tag the release.  
> `git add . && git commit -m "phase-5: security, platform polish, testing, store submission" && git tag v1.0.0 && git push origin main --tags`  
> Repo: [https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

---

## Appendix A — Session Dependency Graph

```text
0.1 → 0.2 → 0.3
               │
               ▼
      1.1 → 1.2 → 1.3 → 1.4 → 1.5
                                 │
               ┌─────────────────┤
               ▼                 ▼
      2.1 → 2.2 → 2.3      3.1 → 3.2
        │     │      │        │
        ▼     ▼      ▼        ▼
      2.4   2.5    2.6      3.3 → 3.4
        │     │      │        │     │
        └──┬──┘      │        ▼     │
           ▼         │      3.5     │
         2.7 ←───────┘        │     │
           │                  │     │
           ▼                  │     │
         2.8                  │     │
           │                  │     │
           └──────┬───────────┘     │
                  ▼                 │
         4.1 → 4.2                 │
           │     │                  │
           ▼     ▼                  │
         4.3   4.4 ←────────────────┘
           │     │
           └──┬──┘
              ▼
            4.5
              │
              ▼
      5.1 → 5.2 → 5.3 → 5.4
```

---

## Appendix B — Milestone Summary

| Milestone | After Session | What's Working |
|-----------|--------------|----------------|
| **M0: Skeleton** | 0.3 | Monorepo, CI/CD, Supabase, empty app shell |
| **M1: Onboarding** | 1.5 | Full onboarding → auth → paywall → Home |
| **M2: Core Learning** | 2.8 | Test prep, flashcards, notes, vocab, mocks, quizzes, planner |
| **M3: AI Live** | 3.5 | All AI features working (Groq/OpenAI/Claude), purchases live |
| **M4: Full App** | 4.5 | Social, games, teacher/parent, translation, profile complete |
| **M5: Launch** | 5.4 | All platforms optimized, tested, submitted to stores |

---

## Appendix C — Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Groq API rate limits too restrictive for free tier | Free user experience degrades | Cache common responses, implement smart queuing |
| Claude API latency for exam generation | Slow question loading | Pre-generate question batches, background generation |
| Subrail SDK not ready for all platforms | Blocked purchases on some stores | Fallback to direct StoreKit/Play Billing integration |
| Offline sync conflicts with multiplayer data | Data corruption | Server-authority for shared data, last-write-wins for personal |
| App Store rejection (paywall compliance) | Launch delay | Follow Apple's latest paywall guidelines, test with TestFlight |
| COPPA compliance for under-13 users | Legal risk | Age gate at onboarding, parental consent flow, no PII collection for minors |
| Language pack download size (~30-80MB) | Storage complaints | Lazy download, clear size warnings, compress aggressively |

---

## Appendix D — Team Allocation Suggestion

| Role | Phase 0-1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|------|-----------|---------|---------|---------|---------|
| **Flutter Dev (Senior)** | Architecture, routing, auth | Question engine, test prep | AI routing, Sage | Games, multiplayer | Performance, testing |
| **Flutter Dev (Mid)** | Design system, onboarding UI | Flashcards, notes, vocab | AI feature wiring | Social, teacher/parent | Platform-specific |
| **Backend Dev** | Supabase schema, RLS, CI/CD | Offline sync engine | Edge Functions, AI APIs | Realtime (games), translation | Security audit |
| **Designer** | Brand, theme, onboarding | Question UX, study modes | Sage chat UI, paywalls | Games, social | Store assets, polish |
| **QA** | — | Manual testing begins | AI edge cases | Multiplayer testing | Full regression, accessibility |
