# Witt — Main Technical & Architectural Document

**Version:** 1.0  
**Date:** February 2026  
**App Name:** Witt  
**Tagline:** The AI-Powered Study Companion for Every Student, Everywhere  
**Repository:** [https://github.com/webblabsorg/witt](https://github.com/webblabsorg/witt)

> Witt is a cross-platform AI-powered education super-app designed to help students prepare for standardized tests, master coursework, and build lasting knowledge through adaptive learning, interactive flashcards, AI tutoring, educational games, and comprehensive study planning — with full offline support for students in low-connectivity regions.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Tech Stack](#2-tech-stack)
3. [System Architecture](#3-system-architecture)
4. [Navigation & Bottom Tabs](#4-navigation--bottom-tabs)
5. [User Flows](#5-user-flows)
6. [Module Definitions](#6-module-definitions)
7. [Standardized Test Catalog](#7-standardized-test-catalog)
8. [Question Engine Design](#8-question-engine-design)
9. [Monetization & Pricing](#9-monetization--pricing)
10. [Realtime Translation System](#10-realtime-translation-system)
11. [Offline Architecture](#11-offline-architecture)
12. [Security, Privacy & Compliance](#12-security-privacy--compliance)
13. [Platform-Specific Notes](#13-platform-specific-notes)
14. [Appendices](#14-appendices)

---

## 1. Executive Summary

### 1.1 Vision

Witt is built to be the single study app a student needs — from high school entrance exams in Lagos to GRE prep in New York to Gaokao preparation in Beijing. It combines AI-powered test generation, adaptive learning, interactive flashcards, a homework tutor, lecture capture, educational games, and a full study planner into one unified experience that works online and offline.

### 1.2 Target Platforms

| Platform | OS | Framework | Notes |
|----------|----|-----------|-------|
| **iOS** | iOS 15+ | Flutter | Full feature set, App Store distribution |
| **macOS** | macOS 12+ | Flutter | Desktop-optimized UI, native menu bar |
| **Android** | Android 7.0+ (API 24) | Flutter | Google Play distribution |
| **HuaweiOS** | HarmonyOS / EMUI 10+ | Flutter | Huawei AppGallery, HMS Core integration |
| **Windows** | Windows 10+ | Flutter | Microsoft Store + direct download |

### 1.3 Core Principles

- **Offline-First**: Every core feature works without internet. Sync when connected.
- **Adaptive Learning**: AI tracks weaknesses and adjusts content delivery.
- **Global by Default**: Multi-language, multi-currency, multi-exam from day one.
- **No Firebase**: Supabase is the sole backend platform.
- **Sound & Interactivity**: Every question interaction has audio feedback, animations, and full-screen immersive UX.

---

## 2. Tech Stack

### 2.1 Core Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Cross-Platform Framework** | Flutter (Dart) | Single codebase for iOS, macOS, Android, HuaweiOS, Windows |
| **Backend & Database** | Supabase (PostgreSQL) | Auth, database, storage, edge functions, realtime |
| **AI — Exam Generation** | Anthropic Claude API | Standardized test & exam question generation only (both free and paid tiers). Pre-generates 10-15 free questions per exam; paid exam subscribers get unlimited AI-generated questions. |
| **AI — Free Users (General)** | Groq AI (Llama) | All AI-powered general features for free users: Sage chat, homework helper, quiz generation, flashcard generation, lecture summarization, study planning. Subject to daily/monthly limits and word caps. |
| **AI — Paid Users (General)** | OpenAI API | All AI-powered general features for paid (Premium) users: Sage chat (GPT-4o), homework helper, quiz generation, flashcard generation, lecture summarization, study planning, voice dictation (Whisper), image generation (DALL-E 3), TTS. Maximum usage with reset windows. |
| **Monetization** | Subrail | In-app subscriptions, per-exam purchases, paywall management (replaces RevenueCat) |
| **Realtime Translation** | Online + Offline stack | API-based translation (online) + on-device models (offline) |
| **Local Database** | Hive + SQLite (sqflite) | Offline data storage, cached content, user progress |
| **State Management** | Riverpod | Reactive state management across the app |
| **Routing** | GoRouter | Declarative routing with deep link support |
| **Networking** | Dio + Supabase Flutter SDK | HTTP client with interceptors, retry logic, offline queue |

### 2.2 AI Stack Detail

#### AI Provider Routing Policy

Witt uses three AI providers with strict routing rules based on feature type and user plan:

| Provider | Tier | Feature Scope | Models | Limits |
|----------|------|--------------|--------|--------|
| **Anthropic Claude** | Both (Free + Paid) | Exam/standardized test question generation ONLY. Free: 10-15 pre-generated questions per exam (static, not on-demand). Paid exam subscribers: unlimited AI-generated exam questions on-demand. | Claude 3.5 Sonnet / Claude 3 Opus | Paid exam sub: unlimited. Free: static pre-gen only. |
| **Groq AI (Llama)** | Free users only | All general AI features: Sage chat, homework helper, quiz generation (non-exam), flashcard generation, lecture summarization, study planning. Fast inference, cost-efficient for free tier. | Llama 3.1 70B / Llama 3.1 8B | 10 msgs/day (Sage), 500 char input, ~500 word output, 300 msgs/month soft cap. Daily reset 00:00 UTC. |
| **OpenAI** | Paid users only | All general AI features: Sage chat (GPT-4o), homework helper, quiz generation, flashcard generation, lecture summarization, study planning, voice dictation (Whisper), image generation for flashcards (DALL-E 3), text-to-speech (TTS). | GPT-4o / GPT-4o-mini / Whisper / DALL-E 3 / TTS | Unlimited messages. Daily reset 00:00 UTC. Monthly reset 1st of month. |

#### Non-Exam Question Generation (Free vs Paid)

- **Free users** can generate questions for non-standardized-test topics (e.g., custom quiz on Chapter 5 Biology) via **Groq AI**, subject to limits:
  - Max 5 generated questions per quiz
  - Max 1 quiz generation per day
  - Max 30 AI-generated questions per month
- **Paid users** get unlimited question generation for any topic via **OpenAI GPT-4o**
- **Exam/standardized test questions** always use **Claude** regardless of plan (free gets static pre-gen, paid gets on-demand generation)

#### AI Routing Decision Tree

```
AI Feature Request
    │
    ├─ Is it exam/standardized test question generation?
    │       │
    │       ├─ YES → Claude API (Supabase Edge Function)
    │       │         Free: serve from pre-generated pool (10-15 Qs)
    │       │         Paid exam sub: generate on-demand
    │       │
    │       └─ NO (general AI feature)
    │               │
    │               ├─ Free user? → Groq AI (Llama)
    │               │               Check daily/monthly limits
    │               │               Enforce word/char caps
    │               │
    │               └─ Paid user? → OpenAI (GPT-4o / Whisper / DALL-E)
    │                               Reset windows apply
    │                               No hard message cap
```

### 2.3 Subrail Monetization Stack

Subrail is an internal subscription management and paywall experimentation platform that replaces RevenueCat and Superwall. Source code: `/Documents/Projects/subrail`.

| Component | Function |
|-----------|----------|
| **Subrail Flutter SDK** | In-app purchase management, entitlement checking, paywall display |
| **Subrail Backend** | Receipt validation (Apple StoreKit 2 + Google Play Billing), subscription lifecycle |
| **Subrail Paywall Engine** | A/B tested paywalls, campaign targeting, audience segmentation |
| **Subrail Analytics** | Revenue metrics, conversion tracking, LTV prediction |

**Store Integration Points:**

- App Store (StoreKit 2) for iOS/macOS
- Google Play Billing for Android
- Huawei IAP Kit for HuaweiOS
- Microsoft Store for Windows
- Stripe for web purchases (future)

### 2.4 Realtime Translation Stack

| Mode | Technology | Use Case |
|------|------------|----------|
| **Online** | Google Cloud Translation API / DeepL API | Full-fidelity translation with context awareness |
| **Offline** | On-device ML models (TensorFlow Lite / ML Kit) | Pre-downloaded language packs for offline translation |
| **Language Packs** | Compressed model files (~30-80MB per language pair) | Downloadable via content manager for offline use |

### 2.5 Infrastructure & Services

| Service | Provider | Purpose |
|---------|----------|---------|
| **Database** | Supabase PostgreSQL | Primary data store with RLS |
| **Auth** | Supabase Auth | Email/password, Google, Apple, phone OTP |
| **File Storage** | Supabase Storage | Audio recordings, images, exported files |
| **Edge Functions** | Supabase Edge Functions | Server-side AI calls, webhook handlers |
| **Database Tooling** | Supabase MCP | AI-assisted schema creation, migrations, RLS policy generation, and database management during development |
| **Push Notifications** | OneSignal | Cross-platform push for all 5 platforms: APNs (iOS/macOS), FCM (Android), Huawei Push Kit (HuaweiOS), Windows Toast (Windows) |
| **Analytics** | Mixpanel / PostHog | Product analytics, funnel tracking |
| **Error Tracking** | Sentry | Crash reporting, performance monitoring |
| **CDN** | Supabase Storage CDN + Cloudflare | Static assets, downloadable content packs |
| **GeoIP** | MaxMind GeoIP2 | Currency detection, regional content |

### 2.6 Development Tools

| Tool | Purpose |
|------|---------|
| **Flutter** | 3.x stable channel |
| **Dart** | 3.x |
| **CI/CD** | GitHub Actions + Codemagic |
| **Testing** | flutter_test, integration_test, Patrol |
| **Linting** | flutter_lints (strict) |
| **Code Generation** | build_runner, freezed, json_serializable |
| **Monorepo** | Melos (multi-package management) |

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Witt Client App                                │
│                          (Flutter — All Platforms)                           │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   UI Layer   │  │  State Mgmt  │  │  Local DB    │  │  Sync Engine │   │
│  │  (Widgets)   │  │  (Riverpod)  │  │ (Hive+SQLite)│  │  (Offline Q) │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         └──────────────────┴─────────────────┴─────────────────┘           │
│                                    │                                        │
│  ┌─────────────────────────────────┴──────────────────────────────────┐    │
│  │                      Repository / Service Layer                     │    │
│  │   AuthRepo • TestRepo • FlashcardRepo • ProgressRepo • SyncRepo   │    │
│  └─────────────────────────────────┬──────────────────────────────────┘    │
│                                    │                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Supabase    │  │  Anthropic   │  │   OpenAI     │  │   Subrail    │   │
│  │  SDK         │  │  Client      │  │   Client     │  │   SDK        │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
└─────────┼──────────────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │                  │
          ▼                  ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│    Supabase      │ │  Anthropic   │ │   OpenAI     │ │     Subrail      │
│  ┌────────────┐  │ │  Claude API  │ │   GPT/DALL-E │ │    Backend       │
│  │ PostgreSQL │  │ │              │ │   Whisper    │ │  ┌────────────┐  │
│  │ Auth       │  │ └──────────────┘ │   TTS        │ │  │ Receipts   │  │
│  │ Storage    │  │                  └──────────────┘ │  │ Entitle.   │  │
│  │ Edge Funcs │  │                                   │  │ Paywalls   │  │
│  │ Realtime   │  │                                   │  │ Analytics  │  │
│  └────────────┘  │                                   │  └────────────┘  │
└──────────────────┘                                   └──────────────────┘
```

### 3.2 Data Flow — Question Generation (Paid User)

```
Student                    Witt App                  Supabase Edge Fn          Anthropic API
  │                          │                            │                        │
  │ 1. Select exam           │                            │                        │
  │ ────────────────────────>│                            │                        │
  │                          │ 2. Check entitlement       │                        │
  │                          │    (Subrail SDK)           │                        │
  │                          │ 3. Request questions        │                        │
  │                          │ ──────────────────────────>│                        │
  │                          │                            │ 4. Call Claude with    │
  │                          │                            │    exam-specific prompt│
  │                          │                            │ ──────────────────────>│
  │                          │                            │ 5. Return structured   │
  │                          │                            │    questions (JSON)    │
  │                          │                            │ <──────────────────────│
  │                          │ 6. Return questions        │                        │
  │                          │ <──────────────────────────│                        │
  │ 7. Display interactive   │                            │                        │
  │    full-screen question  │                            │                        │
  │ <────────────────────────│                            │                        │
```

### 3.3 Offline Sync Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Witt Client App                           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Sync Engine                             │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  Outbox     │  │  Conflict   │  │  Content    │      │   │
│  │  │  Queue      │  │  Resolver   │  │  Downloader │      │   │
│  │  │ (pending    │  │ (last-write │  │ (exam packs │      │   │
│  │  │  writes)    │  │  wins +     │  │  lang packs │      │   │
│  │  │             │  │  server     │  │  vocab)     │      │   │
│  │  │             │  │  authority) │  │             │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌───────────────────────────┴──────────────────────────────┐   │
│  │                    Local Storage                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │   SQLite    │  │    Hive     │  │  File System │      │   │
│  │  │ (questions, │  │ (prefs,     │  │ (audio,      │      │   │
│  │  │  progress,  │  │  cache,     │  │  images,     │      │   │
│  │  │  flashcards)│  │  tokens)    │  │  content pks)│      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 Database Schema Overview

**Supabase PostgreSQL (Cloud — Source of Truth):**

| Table | Purpose |
|-------|---------|
| `users` | User profiles, preferences, home country |
| `user_progress` | Per-exam, per-topic progress tracking |
| `exams` | Exam catalog (SAT, GRE, WAEC, etc.) |
| `exam_sections` | Sections within each exam |
| `questions` | Pre-generated + AI-generated questions |
| `question_attempts` | User answers, time spent, correctness |
| `flashcard_decks` | Deck metadata, ownership, sharing |
| `flashcards` | Individual cards with multimedia |
| `flashcard_progress` | SM-2 spaced repetition state per card |
| `notes` | User notes organized by subject |
| `study_plans` | Generated study schedules |
| `study_sessions` | Logged study time |
| `bookmarks` | Bookmarked questions |
| `saved_questions` | Save-for-later queue |
| `achievements` | Badges, XP, streaks |
| `leaderboards` | Global and friend-group rankings |
| `community_posts` | Q&A forum posts |
| `community_replies` | Replies to posts |
| `study_groups` | Group metadata and membership |
| `lectures` | Recorded/uploaded lecture metadata |
| `lecture_transcripts` | AI-generated transcripts |
| `lecture_summaries` | AI-generated summaries |
| `game_scores` | Educational game results |
| `exam_registrations` | Upcoming exam dates and targets |
| `vocab_lists` | Personal vocabulary lists |
| `vocab_words` | Words with definitions, audio, examples |
| `content_packs` | Downloadable offline content metadata |
| `user_content_downloads` | Track which packs a user has downloaded |
| `pricing` | Per-exam pricing in USD base |
| `currency_rates` | Exchange rates cache |
| `teacher_classes` | Teacher-managed classrooms |
| `class_assignments` | Assigned quizzes/homework |
| `parent_links` | Parent-child account connections |

**Local SQLite (Device):** Mirrors a subset of the above tables relevant to the user's downloaded content and progress. The sync engine handles bidirectional sync with conflict resolution (server authority for shared data, last-write-wins for personal data).

---

## 4. Navigation & Bottom Tabs

Witt uses a 5-tab bottom navigation bar as the primary navigation structure. Each tab serves as an entry point to a cluster of related modules. Games and challenges are accessed via the Play icon in the Home header — keeping the bottom bar focused on the core learning experience.

### 4.1 Tab Layout

```
┌──────────────────────────────────────────────────────────┐
│  Home Header (shown on Home tab):                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Screen Title              🔍  🔔  🎮              │  │
│  │  (left)              (search)(notif)(play)         │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│                    [ Active Screen ]                     │
│                                                          │
├──────────┬──────────┬──────────┬──────────┬──────────────┤
│  🏠 Home │ 📚 Learn │ 🤖 Sage  │ 👥 Social│ 👤 Profile  │
└──────────┴──────────┴──────────┴──────────┴──────────────┘
```

### 4.2 Home Header

The Home tab has a custom header bar that provides quick access to global actions.

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   Home                                    🔍  🔔  🎮    │
│                                                          │
└──────────────────────────────────────────────────────────┘
 ▲ Left                                         Right ▲
 Screen Title                           Action Icons
```

| Position | Element | Behavior |
|----------|---------|----------|
| **Left** | **Screen Title** | Displays "Home" (or contextual greeting: "Good morning, Ade"). Static, non-tappable. |
| **Right** | **🔍 Search Icon** | Opens global search overlay — search across exams, flashcard decks, notes, vocabulary, games, community posts. Results grouped by type. |
| **Right** | **🔔 Notification Icon** | Opens notification center (slide-in panel or full screen). Shows study reminders, streak alerts, friend activity, assignment due dates, exam registration deadlines. Red badge dot when unread. |
| **Right** | **🎮 Play Icon** | Navigates to the **Play Hub** — the full games and challenges experience (M5, M14). This is the primary entry point for all games, daily challenges, multiplayer, brain puzzles, and leaderboards. |

**Play Hub (accessed via 🎮 icon):**

The Play Hub is a full-screen page (not a tab) pushed onto the Home navigation stack. It contains all game and challenge content that was previously in the Play tab:

| Section | Content | Source Module |
|---------|---------|---------------|
| **Daily Challenge** | Today's brain teaser with countdown timer and leaderboard | M5 |
| **Quick Play** | Jump into a random game instantly | M14 |
| **Games Library** | All 9 games: Word Duel, Quiz Royale, Equation Rush, Fact or Fiction, Crossword Builder, Memory Match, Timeline Challenge, Spelling Bee, Subject Boss Battles | M14 |
| **Multiplayer Lobby** | Active rooms for Word Duel and Quiz Royale. Create or join. | M14 |
| **Brain Challenges** | Logic puzzles, pattern recognition, lateral thinking — categorized by type | M5 |
| **My Game Stats** | Games played, win rate, high scores, favorite game | M9, M14 |
| **Leaderboards** | Global, friends, school — daily/weekly/all-time | M10 |

**Play Hub Layout:**
- Top: featured game or active challenge (large hero card)
- Below: horizontal scroll of game tiles with icons and player counts
- "Challenge a Friend" prominent CTA
- Offline: single-player games available; multiplayer greyed out with "Requires internet" label
- Back arrow returns to Home tab

---

### 4.3 Tab Definitions

#### Tab 1: Home

**Icon:** House / Home  
**Label:** Home  
**Purpose:** The student's personalized daily command center — what to do today, at a glance.

| Section | Content | Source Module |
|---------|---------|---------------|
| **Daily Streak Banner** | Current streak count, XP earned today, streak freeze status | M9 |
| **Today's Study Plan** | Today's scheduled subjects/topics from the planner. Tap to start. | M15 |
| **Continue Studying** | Resume last active session (test prep, flashcards, mock test, quiz) | M1, M2, M4, M8 |
| **Exam Countdowns** | Cards showing days remaining for each registered exam with readiness % | M15 |
| **Daily Brain Challenge** | Today's puzzle/challenge — one tap to play (opens Play Hub) | M5 |
| **Word of the Day** | Vocabulary card with definition, pronunciation, example | M6 |
| **Quick Actions Row** | Icon buttons: Scan Homework, Record Lecture, Create Flashcard, Start Mock Test | M3, M13, M2, M4 |
| **Recent Activity Feed** | Last 5 activities (completed quiz, reviewed flashcards, etc.) | M9 |
| **Recommended for You** | AI-suggested next study action based on weak areas and upcoming exams | M1, M9, M15 |

**Behavior:**
- Scrollable vertical feed
- Pull-to-refresh updates study plan and recommendations
- Greeting changes by time of day ("Good morning, Ade — 12 days until your SAT")
- Offline: shows cached plan, streak, and downloaded content

---

#### Tab 2: Learn

**Icon:** Open Book / Graduation Cap  
**Label:** Learn  
**Purpose:** All study and learning tools in one place — the academic engine of the app.

| Section | Content | Source Module |
|---------|---------|---------------|
| **My Exams** | Grid of exams the student is preparing for. Tap to enter exam-specific prep. | M1 |
| **Flashcards** | My decks, recently studied, community decks, create new | M2 |
| **Mock Tests** | Available mock tests by exam. Start new or resume in-progress. | M4 |
| **AI Homework Helper** | Camera scan button + text input for homework questions | M3 |
| **AI Quiz Generator** | Generate quiz from text, PDF, notes, or topic | M8 |
| **Lecture Notes** | Recorded/uploaded lectures with AI summaries | M13 |
| **My Notes** | Note-taking workspace organized by subject | M7 |
| **Vocabulary** | Word lists, saved words, dictionary | M6 |
| **Downloads** | Offline content packs — manage and browse | M12 |

**Layout:**
- Top: horizontal scrollable chips to filter (All, Test Prep, Flashcards, Notes, Vocabulary)
- Below: card-based grid/list of the selected category
- Search bar at top for finding any exam, deck, note, or word
- FAB (Floating Action Button): "+" to create (new deck, new note, new quiz, record lecture)

---

#### Tab 3: Sage (AI Chat Bot)

**Icon:** Sparkle / Brain / Robot  
**Label:** Sage  
**Purpose:** Witt's AI-powered conversational assistant — a personal tutor, study companion, and knowledge engine available 24/7.

**Why "Sage":** A sage is a wise mentor and teacher — exactly what this AI chat represents. Short, memorable, and universally understood across cultures.

| Section | Content | Source Module |
|---------|---------|---------------|
| **Chat Interface** | Full-screen conversational UI. User types or speaks, Sage responds with rich formatted answers (markdown, LaTeX, code, images). | Core AI |
| **Conversation History** | Scrollable list of past conversations, searchable, organized by topic/date | Core AI |
| **Suggested Prompts** | Quick-tap prompt chips: "Explain this concept", "Quiz me on [topic]", "Summarize my notes", "Help me solve this" | Core AI |
| **Context Awareness** | Sage knows the user's exams, weak areas, study history, and current progress — responses are personalized | M1, M9, M15 |
| **Homework Mode** | Camera scan or paste a question → Sage provides step-by-step solution with explanations | M3 |
| **Quiz Mode** | "Quiz me on SAT Math" → Sage generates interactive questions inline in the chat | M8 |
| **Explain Mode** | Paste or reference any question from the app → Sage explains it in detail | M1 |
| **Study Planning** | "Make me a study plan for GRE in 3 months" → Sage generates and saves a plan | M15 |
| **Flashcard Generation** | "Create flashcards for Chapter 5 Biology" → Sage generates a deck | M2 |
| **Lecture Summarization** | Share lecture recording or notes → Sage summarizes and extracts key points | M13 |

**Technical Stack:**
- **Free Users LLM:** Groq AI (fast inference, cost-efficient for free tier)
- **Paid Users LLM:** OpenAI GPT-4o (higher quality, larger context window)
- **Streaming:** Server-Sent Events (SSE) for real-time token streaming
- **Context window:** Conversation history + user profile + exam data injected as system prompt
- **Offline:** Cached conversations viewable. New messages queued with "Will send when online" indicator.
- **Dictation (Paid only):** Voice-to-text input via OpenAI Whisper API. Paid users can tap the microphone icon to dictate messages. Transcription happens server-side via Supabase Edge Function. Free users see the mic icon greyed out with "Upgrade to Premium" tooltip.

**Free vs Paid Limits:**

| Feature | Free Users | Paid Users (Premium) |
|---------|-----------|---------------------|
| **AI Provider** | Groq AI | OpenAI GPT-4o |
| **Messages per day** | 10 messages | Unlimited |
| **Daily reset window** | Resets at 00:00 UTC | N/A |
| **Max input length** | 500 characters per message | 4,000 characters per message |
| **Max output length** | ~500 words per response | ~2,000 words per response |
| **Conversation history** | Last 5 conversations retained | Unlimited history |
| **Context window** | Last 4 messages in thread | Full conversation thread (up to model limit) |
| **Dictation (voice input)** | Not available | Unlimited (Whisper API) |
| **Attachments (camera/file)** | 1 per day | Unlimited |
| **Modes available** | Chat, Explain | All modes (Chat, Explain, Homework, Quiz, Planning, Flashcard Gen, Lecture Summary) |
| **Weekly reset** | Message count resets daily at 00:00 UTC | N/A |
| **Monthly soft cap** | 300 messages/month (after cap: degraded response speed) | No cap |

**Rate Limit Enforcement:**
- Message count tracked per user in Supabase `sage_usage` table
- Daily counter resets via scheduled Supabase Edge Function (cron) at 00:00 UTC
- Monthly counter resets on the 1st of each month at 00:00 UTC
- When free user hits daily limit: "You've used all 10 messages today. Upgrade to Premium for unlimited access." + countdown to reset
- When free user hits monthly soft cap: responses still work but with added latency (queued, not streamed)

**Layout:**
- Full-screen chat interface (similar to ChatGPT / Claude UI)
- Text input bar at bottom with send button + attachment (camera, file) + microphone (greyed out for free users, active for paid)
- Messages render rich content: markdown, LaTeX equations, syntax-highlighted code, images, interactive quiz cards
- Typing indicator with animated dots while Sage is generating
- Long-press message to copy, share, save to notes, or regenerate
- New conversation button in top-right
- Free users see remaining message count badge: "7/10 messages left today"
- Upgrade banner at bottom of chat when limits are near or reached

---

#### Tab 4: Social

**Icon:** People / Chat Bubbles  
**Label:** Social  
**Purpose:** Community, collaboration, and the teacher/parent portal entry point.

| Section | Content | Source Module |
|---------|---------|---------------|
| **Feed** | Activity from friends and study groups (opt-in) | M10 |
| **Study Groups** | My groups, discover groups, create new | M10 |
| **Q&A Forum** | Browse questions, post new, filter by subject/exam | M10 |
| **Deck Marketplace** | Browse, share, and discover community flashcard decks | M10 |
| **Friends** | Friend list, add friends (username/QR/contacts), challenge | M10 |
| **Leaderboards** | Friends, school, global — XP and exam scores | M10 |
| **Teacher Portal** | (If teacher role) Class management, assignments, grading, analytics | M11 |
| **Parent Portal** | (If parent role) Linked children, activity overview, progress reports | M11 |

**Layout:**
- Top: segmented control — Feed / Groups / Forum / Marketplace
- Each segment has its own scrollable content
- Teacher/Parent portal appears as a top banner or dedicated sub-tab if the user has that role
- Offline: cached posts and groups visible; new posts queued for sync

---

#### Tab 5: Profile

**Icon:** Person / Avatar  
**Label:** Profile  
**Purpose:** User identity, progress overview, settings, and account management.

| Section | Content | Source Module |
|---------|---------|---------------|
| **Profile Header** | Avatar, display name, level, XP bar, badge count, streak | M9 |
| **Progress Dashboard** | Score trends, topic mastery heatmap, study hours, predicted scores | M9 |
| **Exam Tracker** | All registered exams — scores, history, trends, target tracking | M15 |
| **Achievements & Badges** | All earned and locked badges with progress indicators | M9 |
| **Study Stats** | Total questions answered, hours studied, flashcards reviewed, games played | M9 |
| **My Subscriptions** | Current plan (Free/Premium), exam packs purchased, manage subscription | M-Monetization |
| **Downloads & Storage** | Manage offline content packs, storage usage | M12 |
| **Settings** | Account, notifications, language, currency, theme (light/dark/system), sound, accessibility | Core |
| **Help & Support** | FAQ, contact support, report bug | Core |
| **About** | Version, terms, privacy policy, licenses | Core |

**Layout:**
- Top: profile card with avatar, name, level badge, XP progress bar
- Below: vertical list of sections as tappable cards/rows
- Settings accessible via gear icon in top-right corner

---

### 4.4 Navigation Rules

- **Persistent bottom bar**: Visible on all primary screens. Hidden during full-screen experiences (answering questions, taking mock tests, playing games, recording lectures, Sage chat in immersive mode).
- **Active tab indicator**: Filled icon + label highlighted in primary brand color. Inactive tabs use outline icons in neutral gray.
- **Badge indicators**: Red dot on Social tab for unread messages/notifications. Number badge on Sage tab for unread AI responses. Number badge on Learn tab if assignments are due.
- **Notification badge (Home header)**: Red dot on 🔔 icon when unread notifications exist. Number badge on 🎮 icon when daily challenge is available.
- **Deep linking**: Each tab and sub-screen has a unique route for deep links and push notification navigation (e.g., `witt://learn/exam/sat`, `witt://sage`, `witt://home/play`, `witt://home/play/quiz-royale`). Play Hub routes are nested under `home` since it is accessed via the Home header icon, not a standalone tab.
- **State preservation**: Switching tabs preserves scroll position and state. Tapping the active tab scrolls to top.
- **Tablet/Desktop**: On iPad and desktop (macOS/Windows), the bottom tabs convert to a left sidebar rail with icons + labels for better use of horizontal space. Play Hub becomes a sidebar item.

### 4.5 GoRouter Configuration

```dart
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
      branches: [
        // Tab 1: Home
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
            routes: [
              // Play Hub (accessed via 🎮 icon in Home header)
              GoRoute(
                path: 'play',
                builder: (_, __) => const PlayHubScreen(),
                routes: [
                  GoRoute(path: 'game/:gameId', builder: (_, state) => GameScreen(gameId: state.pathParameters['gameId']!)),
                  GoRoute(path: 'daily-challenge', builder: (_, __) => const DailyChallengeScreen()),
                  GoRoute(path: 'multiplayer', builder: (_, __) => const MultiplayerLobbyScreen()),
                  GoRoute(path: 'brain-challenges', builder: (_, __) => const BrainChallengesScreen()),
                ],
              ),
              // Search (accessed via 🔍 icon in Home header)
              GoRoute(path: 'search', builder: (_, __) => const GlobalSearchScreen()),
              // Notifications (accessed via 🔔 icon in Home header)
              GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
            ],
          ),
        ]),
        // Tab 2: Learn
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/learn',
            builder: (_, __) => const LearnScreen(),
            routes: [
              GoRoute(path: 'exam/:examId', builder: (_, state) => ExamPrepScreen(examId: state.pathParameters['examId']!)),
              GoRoute(path: 'flashcards', builder: (_, __) => const FlashcardsScreen()),
              GoRoute(path: 'flashcards/:deckId', builder: (_, state) => DeckStudyScreen(deckId: state.pathParameters['deckId']!)),
              GoRoute(path: 'mock-tests', builder: (_, __) => const MockTestsScreen()),
              GoRoute(path: 'homework', builder: (_, __) => const HomeworkHelperScreen()),
              GoRoute(path: 'quiz-generator', builder: (_, __) => const QuizGeneratorScreen()),
              GoRoute(path: 'lectures', builder: (_, __) => const LecturesScreen()),
              GoRoute(path: 'notes', builder: (_, __) => const NotesScreen()),
              GoRoute(path: 'vocabulary', builder: (_, __) => const VocabularyScreen()),
              GoRoute(path: 'downloads', builder: (_, __) => const DownloadsScreen()),
            ],
          ),
        ]),
        // Tab 3: Sage (AI Chat Bot)
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/sage',
            builder: (_, __) => const SageScreen(),
            routes: [
              GoRoute(path: 'conversation/:conversationId', builder: (_, state) => SageConversationScreen(conversationId: state.pathParameters['conversationId']!)),
              GoRoute(path: 'new', builder: (_, __) => const SageNewConversationScreen()),
            ],
          ),
        ]),
        // Tab 4: Social
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/social',
            builder: (_, __) => const SocialScreen(),
            routes: [
              GoRoute(path: 'groups/:groupId', builder: (_, state) => GroupScreen(groupId: state.pathParameters['groupId']!)),
              GoRoute(path: 'forum', builder: (_, __) => const ForumScreen()),
              GoRoute(path: 'forum/:postId', builder: (_, state) => PostScreen(postId: state.pathParameters['postId']!)),
              GoRoute(path: 'marketplace', builder: (_, __) => const DeckMarketplaceScreen()),
              GoRoute(path: 'friends', builder: (_, __) => const FriendsScreen()),
              GoRoute(path: 'teacher', builder: (_, __) => const TeacherPortalScreen()),
              GoRoute(path: 'parent', builder: (_, __) => const ParentPortalScreen()),
            ],
          ),
        ]),
        // Tab 5: Profile
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'dashboard', builder: (_, __) => const ProgressDashboardScreen()),
              GoRoute(path: 'exam-tracker', builder: (_, __) => const ExamTrackerScreen()),
              GoRoute(path: 'achievements', builder: (_, __) => const AchievementsScreen()),
              GoRoute(path: 'subscriptions', builder: (_, __) => const SubscriptionsScreen()),
              GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
            ],
          ),
        ]),
      ],
    ),
  ],
);
```

### 4.6 Module-to-Tab Mapping

| Module | Primary Tab | Secondary Access |
|--------|-------------|-----------------|
| **M1** AI Test Prep | Learn | Home (Continue Studying, Recommended), Sage (Explain Mode) |
| **M2** Flashcards | Learn | Home (Quick Actions), Sage (Flashcard Generation) |
| **M3** Homework Helper | Learn | Home (Quick Actions), Sage (Homework Mode) |
| **M4** Mock Tests | Learn | Home (Continue Studying) |
| **M5** Brain Challenges | Home → Play Hub (🎮) | Home (Daily Challenge card) |
| **M6** Vocabulary | Learn | Home (Word of the Day) |
| **M7** Notes | Learn | — |
| **M8** Quiz Generator | Learn | Sage (Quiz Mode) |
| **M9** Dashboard & Analytics | Profile | Home (streak, XP) |
| **M10** Community & Social | Social | — |
| **M11** Teacher & Parent Portal | Social | — |
| **M12** Offline Mode | Learn (Downloads) | Profile (Storage) |
| **M13** Lecture Capture | Learn | Home (Quick Actions), Sage (Lecture Summarization) |
| **M14** Educational Games | Home → Play Hub (🎮) | — |
| **M15** Study & Exam Planner | Home (Today's Plan) | Profile (Exam Tracker), Sage (Study Planning) |

---

## 5. User Flows

This section defines the key user journeys through the app — from first launch to daily usage patterns. Each flow maps the screens, decisions, and module interactions a user encounters.

---

### 5.1 First Launch & Onboarding

This flow runs only once — on the very first app launch after install. Every screen must be completed in sequence. Progress is saved locally so if the user kills the app mid-onboarding, they resume where they left off.

```
App Install → First Launch
    │
    ▼
┌──────────────────────────────────────────────────────────┐
│  1. BOOT SCREEN                                          │
│                                                          │
│  • Native platform splash (LaunchScreen.storyboard on    │
│    iOS, launch_background.xml on Android)                │
│  • Witt logo centered, brand color background            │
│  • Duration: ~1-2s (system-controlled)                   │
│  • Purpose: app binary loading, framework init           │
│  • No user interaction                                   │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  2. SPLASH (MARKETING) SCREEN                            │
│                                                          │
│  Full-screen animated marketing experience:              │
│  • Witt logo animation (Lottie/Rive)                     │
│  • 3-4 swipeable slides showcasing key value props:      │
│    Slide 1: "AI-Powered Test Prep" — illustration +      │
│             headline + subtext                           │
│    Slide 2: "100+ Exams Worldwide" — globe animation     │
│             with exam pins                               │
│    Slide 3: "Learn Anywhere, Even Offline" — phone       │
│             with no-wifi icon + checkmark                │
│    Slide 4: "Free to Start" — unlock animation           │
│  • Dot indicators at bottom for slide position           │
│  • [Skip] button (top-right) to jump ahead               │
│  • [Get Started] button on final slide                   │
│  • Auto-advances every 4s if user doesn't swipe          │
│  • Parallax/fade transitions between slides              │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  3. LANGUAGE PICKER SCREEN                               │
│                                                          │
│  "Choose your language"                                  │
│  Full-screen grid/list of 21 supported languages:        │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  🇺🇸 English (US)        🇬🇧 English (UK)           │ │
│  │  🇪🇸 Espanol             🇫🇷 Francais               │ │
│  │  🇩🇪 Deutsch             🇵🇹 Portugues              │ │
│  │  🇮🇹 Italiano            🇳🇱 Nederlands             │ │
│  │  🇷🇺 Russkiy             🇵🇱 Polski                 │ │
│  │  🇹🇷 Turkce              🇸🇦 Al-Arabiyyah           │ │
│  │  🇮🇳 Hindi               🇮🇳 Bengali                │ │
│  │  🇨🇳 Zhongwen (Simplified)  🇹🇼 Zhongwen (Trad.)   │ │
│  │  🇯🇵 Nihongo             🇰🇷 Hangugeo               │ │
│  │  🇮🇩 Bahasa Indonesia    🇻🇳 Tieng Viet             │ │
│  │  🇰🇪 Kiswahili                                      │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  • Each language shown in its native script               │
│  • Flag icon + native name                               │
│  • GeoIP pre-selects the most likely language             │
│  • Tap to select → checkmark appears                     │
│  • [Continue] button at bottom                           │
│  • Selection immediately applies — all subsequent        │
│    screens render in the chosen language                  │
│  • Stored locally + synced to profile after auth         │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  4. INTERACTIVE SETUP WIZARD                             │
│                                                          │
│  7-10 questions presented one-per-screen in varied,      │
│  engaging formats. Each screen has a progress bar at     │
│  top. [Back] arrow to revisit previous answers.          │
│  Transitions: smooth slide/fade between questions.       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q1: "Who are you?"                                │  │
│  │  Format: Large illustrated cards (tap to select)   │  │
│  │  Options:                                          │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │ 🎓       │ │ 👨‍🏫       │ │ 👨‍👩‍👧       │           │  │
│  │  │ Student  │ │ Teacher  │ │ Parent   │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q2: "What's your education level?"                │  │
│  │  Format: Vertical list with radio buttons          │  │
│  │  Options: Middle School / High School / College /  │  │
│  │  Graduate School / Professional / Other            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q3: "Where are you based?"                        │  │
│  │  Format: Searchable dropdown with flag icons       │  │
│  │  Pre-filled via GeoIP — user confirms or changes   │  │
│  │  Sets home currency + suggests regional exams      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q4: "What are you preparing for?"                 │  │
│  │  Format: Multi-select chip grid (filterable)       │  │
│  │  Shows exams relevant to Q2 + Q3 answers           │  │
│  │  e.g., US + High School → SAT, ACT, AP, PSAT      │  │
│  │  Can search/browse all exams                       │  │
│  │  Select 1 or more exams                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q5: "When is your exam?"                          │  │
│  │  Format: Date picker per selected exam             │  │
│  │  Shows each selected exam with a calendar picker   │  │
│  │  "I don't know yet" option per exam                │  │
│  │  Feeds into study planner + countdown widgets      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q6: "What's your target score?"                   │  │
│  │  Format: Slider + numeric input per exam           │  │
│  │  Shows score range for each exam (e.g., SAT:       │  │
│  │  400-1600). User drags slider or types target.     │  │
│  │  "Not sure" option available                       │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q7: "How much time can you study daily?"          │  │
│  │  Format: Illustrated time blocks (tap to select)   │  │
│  │  Options:                                          │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐      │  │
│  │  │ 15 min │ │ 30 min │ │ 1 hour │ │ 2+ hrs │      │  │
│  │  │ Casual │ │Regular │ │Serious │ │Intense │      │  │
│  │  └────────┘ └────────┘ └────────┘ └────────┘      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q8: "What subjects do you want to focus on?"      │  │
│  │  Format: Toggle switches grouped by category       │  │
│  │  Categories: Math, Reading, Writing, Science,      │  │
│  │  History, Languages, etc.                          │  │
│  │  Dynamically filtered by selected exams            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q9: "How do you like to learn?" (Optional)        │  │
│  │  Format: Multi-select illustrated cards            │  │
│  │  Options: Flashcards / Practice Tests / Games /    │  │
│  │  Reading / Video & Lectures / AI Tutoring          │  │
│  │  Personalizes Home tab content ordering            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Q10: "Enable notifications?" (Optional)           │  │
│  │  Format: Illustrated permission prompt             │  │
│  │  • Study reminders                                 │  │
│  │  • Streak alerts                                   │  │
│  │  • Exam date reminders                             │  │
│  │  • New content alerts                              │  │
│  │  Toggle each on/off → triggers OS permission       │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  All wizard answers stored locally in Hive.              │
│  Synced to Supabase user profile after authentication.   │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  5. AUTH SCREEN                                          │
│                                                          │
│  "Create your account to save your progress"             │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  [  Sign in with Apple  ]     (iOS/macOS only)      │ │
│  │  [  Sign in with Google ]                           │ │
│  │  [  Continue with Email ]                           │ │
│  │  [  Continue with Phone ]     (OTP)                 │ │
│  │                                                     │ │
│  │  ─── or ───                                         │ │
│  │                                                     │ │
│  │  [  Skip for now  ]          (anonymous auth)       │ │
│  │                                                     │ │
│  │  "Already have an account? Log in"                  │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  • Apple Sign-In shown first on iOS (App Store policy)   │
│  • Anonymous users get full free-tier access              │
│  • Anonymous users prompted to create account when they  │
│    try: social features, purchases, or cross-device sync │
│  • On successful auth: wizard answers sync to Supabase,  │
│    study plan generated, GeoIP currency set               │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  6. PAYWALL SCREEN (General App Pricing)                 │
│                                                          │
│  "Unlock the full Witt experience"                       │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                                                     │ │
│  │  ┌─────────────────────────────────────────────┐    │ │
│  │  │  ✨ FREE PLAN                               │    │ │
│  │  │  • 10 Sage AI messages/day                  │    │ │
│  │  │  • 10-15 free questions per exam            │    │ │
│  │  │  • Basic flashcards & notes                 │    │ │
│  │  │  • Daily brain challenge                    │    │ │
│  │  │  • Limited games & community                │    │ │
│  │  │                                             │    │ │
│  │  │  [  Continue with Free  ]                   │    │ │
│  │  └─────────────────────────────────────────────┘    │ │
│  │                                                     │ │
│  │  ┌─────────────────────────────────────────────┐    │ │
│  │  │  🔥 PREMIUM MONTHLY — $9.99/mo              │    │ │
│  │  │  • Unlimited Sage AI (GPT-4o + dictation)   │    │ │
│  │  │  • Unlimited flashcards, notes, quizzes     │    │ │
│  │  │  • AI homework helper & lecture capture      │    │ │
│  │  │  • Full analytics & study planner           │    │ │
│  │  │  • Multiplayer games & full community       │    │ │
│  │  │  • Ad-free + cross-device sync              │    │ │
│  │  │  • 7-day free trial                         │    │ │
│  │  │                                             │    │ │
│  │  │  [  Start Free Trial  ]                     │    │ │
│  │  └─────────────────────────────────────────────┘    │ │
│  │                                                     │ │
│  │  ┌─────────────────────────────────────────────┐    │ │
│  │  │  💎 PREMIUM YEARLY — $59.99/yr ($5.00/mo)   │    │ │
│  │  │  ┌───────────────────────────────┐          │    │ │
│  │  │  │  SAVE 50%  — BEST VALUE       │          │    │ │
│  │  │  └───────────────────────────────┘          │    │ │
│  │  │  Everything in Premium Monthly              │    │ │
│  │  │  Billed annually                            │    │ │
│  │  │                                             │    │ │
│  │  │  [  Subscribe Yearly  ]                     │    │ │
│  │  └─────────────────────────────────────────────┘    │ │
│  │                                                     │ │
│  │  "Restore Purchases"                                │ │
│  │  "Exam-specific plans available inside the app"     │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  • Prices shown in user's local currency (GeoIP)         │
│  • Yearly plan highlighted as "Best Value" with badge    │
│  • 7-day free trial for Monthly (first-time only)        │
│  • "Continue with Free" always visible — no forced       │
│    purchase. User can always choose free.                 │
│  • Anonymous users see this screen too — selecting a      │
│    paid plan triggers account creation prompt first       │
│  • Managed via Subrail paywall experimentation           │
│    (A/B test layouts, copy, pricing emphasis)             │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  7. FEATURE COMPARISON SCREEN                            │
│                                                          │
│  "Go beyond your limits"                                 │
│  "Upgrade to Premium"                                    │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Hero banner: illustration + "Upgrade to Premium    │ │
│  │  for $9.99/mo" with brand gradient background       │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  "What you get"                                          │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Feature                        Free    Premium     │ │
│  │  ─────────────────────────────────────────────────  │ │
│  │  🤖 Sage AI (Unlimited)          ✗        ✓        │ │
│  │  🎙️ Sage Dictation               ✗        ✓        │ │
│  │  📸 AI Homework Helper           ✗        ✓        │ │
│  │  📝 Unlimited Notes & Decks      ✗        ✓        │ │
│  │  🧠 AI Study Planner             ✗        ✓        │ │
│  │  🎤 Lecture AI Summarization     ✗        ✓        │ │
│  │  📊 Full Analytics & Trends      ✗        ✓        │ │
│  │  🎮 Multiplayer Games            ✗        ✓        │ │
│  │  👥 Full Community Access        ✗        ✓        │ │
│  │  🔄 Cross-Device Sync            ✗        ✓        │ │
│  │  🚫 Ad-Free Experience           ✗        ✓        │ │
│  │  ❄️ Streak Freeze                ✗        ✓        │ │
│  │  📦 Unlimited Offline Packs      ✗        ✓        │ │
│  │  🎯 Priority Support             ✗        ✓        │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  [  Upgrade to Premium  ]                           │ │
│  │  Total price: $9.99/month                           │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  [✗ Close] button top-left to skip                       │
│                                                          │
│  • Scrollable feature list with icon + label per row     │
│  • Free column shows ✗ (grey), Premium shows ✓ (green)   │
│  • Features the user tried during wizard that are        │
│    Premium-only are highlighted with a subtle glow        │
│  • Tapping "Upgrade" proceeds to native store purchase   │
│  • Close/skip proceeds to next screen                    │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  8. FREE TRIAL EXPLAINER SCREEN                          │
│                                                          │
│  "HOW YOUR FREE TRIAL WORKS"                             │
│                                                          │
│  Vertical timeline with 3 steps:                         │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                                                     │ │
│  │  🟢 ─── Today                                       │ │
│  │  │      Get full access to all Premium              │ │
│  │  │      features and tools                          │ │
│  │  │                                                  │ │
│  │  🟡 ─── In 6 days                                   │ │
│  │  │      Get reminded about your                     │ │
│  │  │      trial's expiration                          │ │
│  │  │                                                  │ │
│  │  🔵 ─── In 7 days                                   │ │
│  │         You will be charged — cancel any            │ │
│  │         time earlier                                │ │
│  │                                                     │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  "7-day free trial"                                      │
│  "Then $59.99/year ($5.00/month)"                        │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  [  Start my Free Trial  ]                          │ │
│  │  (gradient button, prominent CTA)                   │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  "By subscribing, you agree to our"                      │
│  "Privacy Policy and Terms of Use"                       │
│                                                          │
│  [✗ Close] button top-left                               │
│  [RESTORE] link top-right                                │
│                                                          │
│  • Timeline uses colored dots (green → yellow → blue)    │
│    connected by a vertical line                          │
│  • Emphasizes the yearly plan (best value) with trial    │
│  • Push notification scheduled for Day 6 reminder        │
│  • If user already selected a plan on Screen 6, this     │
│    screen is skipped                                     │
│  • If user taps Close, they proceed as Free user         │
│  • "Start my Free Trial" triggers StoreKit/Play Billing  │
│    subscription flow with 7-day trial period             │
└──────────────────────┬───────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────┐
│  9. HOME SCREEN                                          │
│                                                          │
│  Personalized Home tab with bottom navigation visible.   │
│  Content shaped by wizard answers + selected plan:       │
│  • Study plan generated from exam dates + daily time     │
│  • Exam countdowns active                                │
│  • Recommended modules based on learning preferences     │
│  • Streak counter initialized (Day 1)                    │
│  • Welcome banner: "Welcome to Witt, [Name]!"           │
│  • Quick-start card: "Start your first practice session" │
│  • Free users see subtle upgrade prompts in-context      │
│  • Premium trial users see "Trial: 6 days remaining"     │
└──────────────────────────────────────────────────────────┘
```

**Key decisions:**
- Language picker comes before the wizard so all wizard screens render in the user's chosen language
- Wizard questions use varied UI formats (cards, radio lists, dropdowns, chips, sliders, toggles, date pickers) to keep the experience engaging and interactive
- GeoIP pre-fills country (Q3) and pre-selects language — user can always override
- Wizard answers are stored locally first (Hive) — no network required during onboarding
- Paywall is shown after auth so the user is already invested in the app before seeing pricing
- "Continue with Free" is always available — the paywall is informational, never blocking
- Anonymous auth ("Skip for now") is always available — converts later via soft prompts
- Onboarding state persisted locally — if user kills app mid-flow, they resume at the exact screen
- Exam-specific pricing is NOT shown during onboarding — it appears when the user taps into a specific exam

---

### 5.2 Subsequent App Access

This flow runs on every app launch after the initial onboarding is complete.

```
App Launch (not first time)
    │
    ▼
┌──────────────────────────────────────────────────────────┐
│  1. BOOT SCREEN                                          │
│                                                          │
│  • Same native splash as first launch                    │
│  • Witt logo, brand color background                     │
│  • Duration: ~1-2s                                       │
│  • During this time:                                     │
│    - Check local auth state (Hive / Secure Storage)      │
│    - Load cached user profile                            │
│    - Initialize local database                           │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
               ┌───────────────┐
               │  Auth state?  │
               └───┬───────┬───┘
                   │       │
            Logged in   Not logged in
            (token     (token expired,
             valid)     logged out, or
                   │    anonymous expired)
                   │       │
                   ▼       ▼
┌──────────────────┐  ┌───────────────────────────────────┐
│  HOME SCREEN     │  │  FIRST LAUNCH & ONBOARDING (§5.1) │
│                  │  │                                   │
│  Personalized    │  │  Full onboarding flow restarts    │
│  home tab with   │  │  from Splash (Marketing) Screen   │
│  bottom nav.     │  │  (Boot Screen already shown)      │
│                  │  │                                   │
│  • Streak banner │  │  If user previously had an        │
│  • Today's plan  │  │  account: "Log in" on Auth Screen │
│  • Continue      │  │  restores their data from         │
│    studying      │  │  Supabase after authentication.   │
│  • Exam          │  │                                   │
│    countdowns    │  │  If onboarding was partially      │
│  • Quick actions │  │  completed before: resumes at     │
│  • Recent        │  │  the exact screen where the user  │
│    activity      │  │  left off.                        │
└──────────────────┘  └───────────────────────────────────┘
```

**Routing logic (GoRouter):**

```dart
redirect: (context, state) {
  final isLoggedIn = authState.isAuthenticated;
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final onboardingStep = prefs.getInt('onboarding_step') ?? 0;

  // Paywall progression flags (persisted in SharedPreferences)
  final paywallSeen = prefs.getBool('paywall_seen') ?? false;
  final paywallCompareSeen = prefs.getBool('paywall_compare_seen') ?? false;
  final trialExplainerSeen = prefs.getBool('trial_explainer_seen') ?? false;
  final generalPlanSelected = prefs.getBool('general_plan_selected') ?? false;

  // First launch or logged out → onboarding (resume at last step)
  if (!onboardingComplete) {
    return onboardingRoutes[onboardingStep];
  }

  // Onboarding done but not authenticated → auth screen
  if (!isLoggedIn) {
    return '/auth';
  }

  // Auth done but paywall sequence not completed → resume paywall flow
  // Only shown once during initial onboarding; never re-shown on subsequent launches
  if (!paywallSeen) return '/onboarding/paywall';
  if (!paywallCompareSeen && !generalPlanSelected) return '/onboarding/paywall-compare';
  if (!trialExplainerSeen && !generalPlanSelected) return '/onboarding/trial-explainer';

  // All good → home
  return null; // no redirect, proceed to requested route
}
```

**Paywall state flags (SharedPreferences keys):**

| Key | Type | Set when |
|-----|------|----------|
| `paywall_seen` | bool | User views Screen 6 (General Paywall) |
| `paywall_compare_seen` | bool | User views Screen 6b (Feature Comparison) |
| `trial_explainer_seen` | bool | User views Screen 6c (Free Trial Explainer) |
| `general_plan_selected` | bool | User selects any plan (Free, Monthly, or Yearly) on Screen 6 — skips 6b/6c |
| `onboarding_complete` | bool | User reaches Home screen for the first time |
| `onboarding_step` | int | Index of last completed onboarding step (for mid-flow resume) |

**Key behaviors:**
- Boot screen is always shown (platform-native, cannot be skipped)
- Auth token checked locally — no network call needed for the happy path
- If token is expired but refresh token is valid, silent refresh happens during boot screen
- If refresh fails → user sees Auth Screen (not full onboarding) with "Log in" pre-selected
- Anonymous users who never created an account: `onboarding_complete` is true, they go straight to Home
- Paywall screens (6, 6b, 6c) are shown **once only** during initial onboarding — never re-shown on subsequent launches
- If user selects a plan on Screen 6, `general_plan_selected = true` and Screens 6b/6c are skipped
- Background sync starts silently after Home screen loads

---

### 5.3 Test Prep Flow (M1)

```
Learn Tab → My Exams → Select "SAT"
    │
    ▼
┌─────────────────────┐
│  SAT Exam Hub        │
│  • Overall readiness │
│  • Section scores    │
│  • Practice by topic │
│  • Full mock test    │
│  • Question history  │
│  • Bookmarked Qs     │
└──────────┬──────────┘
           │
     ┌─────┼──────┐
     │     │      │
     ▼     ▼      ▼
┌──────┐┌──────┐┌──────┐
│Topic ││Full  ││Review│
│Drill ││Mock  ││Saved │
│      ││Test  ││Qs    │
└──┬───┘└──┬───┘└──┬───┘
   │       │       │
   ▼       ▼       ▼
┌─────────────────────┐
│  Question Screen     │
│  (Exam-specific      │
│   format — see §8)   │
│                      │
│  Free user:          │
│  Pre-generated pool  │
│  (10-15 Qs)          │
│                      │
│  Paid exam sub:      │
│  AI-generated via    │
│  Claude (unlimited)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Per-Question Flow   │
│  1. Read question    │
│  2. Select answer    │
│  3. Submit           │
│  4. ✅ or ❌ feedback │
│     + sound effect   │
│  5. Explanation panel│
│     slides up        │
│  6. Bookmark? Save?  │
│  7. Next question    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Session Results     │
│  • Score: 18/25      │
│  • Time: 22 min      │
│  • Accuracy by topic │
│  • XP earned: +120   │
│  • Weak areas flagged│
│  • "Try again" or    │
│    "Next topic"      │
└─────────────────────┘
```

**Paywall trigger:** When a free user exhausts the 10-15 pre-generated questions for an exam, the next question tap shows the exam paywall (individual exam pack or premium upgrade).

---

### 5.4 Flashcard Study Flow (M2)

```
Learn Tab → Flashcards
    │
    ▼
┌─────────────────────┐
│  Flashcards Home     │
│  • My Decks          │
│  • Recently Studied  │
│  • Community Decks   │
│  • Create New Deck   │
└──────────┬──────────┘
           │
     ┌─────┴──────┐
     │            │
     ▼            ▼
┌─────────┐  ┌──────────┐
│ Select  │  │ Create   │
│ existing│  │ new deck │
│ deck    │  │ (manual  │
└────┬────┘  │ or AI    │
     │       │ generate)│
     │       └──────────┘
     ▼
┌─────────────────────┐
│  Study Mode Select   │
│  • Flashcard flip    │
│  • Learn (SM-2)      │
│  • Write (type ans)  │
│  • Match (drag)      │
│  • Test (quiz mode)  │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Study Session       │
│  Card 1 of 30        │
│                      │
│  [Front: Term]       │
│  Tap to flip         │
│  [Back: Definition]  │
│                      │
│  Rate: Again / Hard /│
│  Good / Easy         │
│  (feeds SM-2 algo)   │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Session Complete    │
│  • Cards reviewed: 30│
│  • Mastered: 22      │
│  • Still learning: 8 │
│  • Next review: 2h   │
│  • XP earned: +60    │
└─────────────────────┘
```

---

### 5.5 Homework Helper Flow (M3)

```
Home Tab → Quick Actions → "Scan Homework"
    │
    ▼
┌─────────────────────┐
│  Input Method        │
│  • 📷 Camera scan    │
│  • 📝 Type question  │
│  • 📎 Upload image   │
│  • 📄 Upload PDF     │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Camera / Input      │
│  Snap photo of       │
│  homework question   │
│  OCR extracts text   │
│  User confirms/edits │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  AI Processing       │
│  "Solving..."        │
│  Free: Groq (Llama)  │
│  Paid: OpenAI GPT-4o │
│  (via Edge Function) │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Step-by-Step        │
│  Solution            │
│  • Problem restated  │
│  • Step 1 → Step N   │
│  • Final answer      │
│  • Key concepts      │
│  • Related topics    │
│                      │
│  Actions:            │
│  • "Explain more"    │
│  • "Show different   │
│     approach"        │
│  • "Generate similar │
│     practice Qs"     │
│  • Save to notes     │
│  • Share             │
└─────────────────────┘
```

**Paywall trigger:** Free users get limited daily queries. After the limit, the premium paywall appears.

---

### 5.6 Mock Test Flow (M4)

```
Learn Tab → Mock Tests → Select Exam → Start
    │
    ▼
┌─────────────────────┐
│  Pre-Test Screen     │
│  • Exam: SAT         │
│  • Sections: 4       │
│  • Total time: 3h 15m│
│  • Questions: 154    │
│  • Rules & format    │
│  • [Start Test]      │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Full-Screen Test    │
│  Bottom nav HIDDEN   │
│  Top bar: timer,     │
│  section, Q number   │
│                      │
│  Section 1 → 2 → 3  │
│  Timed per section   │
│  Flag for review     │
│  Section review      │
│  screen between      │
│  sections            │
└──────────┬──────────┘
           │
     ┌─────┴──────┐
     │            │
     ▼            ▼
┌─────────┐  ┌──────────┐
│ Complete│  │ Pause    │
│ all     │  │ (timer   │
│ sections│  │ pauses,  │
│         │  │ resume   │
│         │  │ later)   │
└────┬────┘  └──────────┘
     │
     ▼
┌─────────────────────┐
│  Score Report        │
│  • Overall: 1320/1600│
│  • Per-section scores│
│  • Per-topic accuracy│
│  • Time analysis     │
│  • Comparison to     │
│    target score      │
│  • Comparison to     │
│    average Witt user │
│  • Review all Qs     │
│    with explanations │
│  • Retake option     │
│  • Share score       │
└─────────────────────┘
```

---

### 5.7 Game Flow (M14)

```
Home Tab → Header 🎮 (Play icon) → Play Hub (full-screen)
    │
    ▼
┌─────────────────────────────────────────┐
│  Play Hub                               │
│  • Daily Challenge (featured)           │
│  • Games Library (all game types)       │
│  • Leaderboards                         │
│  • Multiplayer Lobby                    │
│  • Brain Puzzles                        │
└──────────────────┬──────────────────────┘
                   │
         Select Game from Library
                   │
    ┌──────────────┴──────────────┐
    │                             │
    ▼                             ▼
┌─────────────────────────────────────────┐
│  Single-Player (e.g., Equation Rush)    │
│                                         │
│  Game Lobby → Countdown 3-2-1 → Play   │
│  → Score Screen → XP + Leaderboard     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Multiplayer (e.g., Quiz Royale)        │
│                                         │
│  Game Lobby → Create/Join Room →        │
│  Waiting for players (2-50) →           │
│  Countdown 3-2-1 → Simultaneous Qs →   │
│  Wrong = eliminated → Last standing     │
│  wins → Results + XP + Leaderboard      │
└─────────────────────────────────────────┘
```

**Access note:** Play Hub is not a bottom tab. It is a full-screen page pushed onto the Home navigation stack via the 🎮 icon in the Home header. Free users can play 3 games/day (single-player only). Paid users have unlimited games and multiplayer access.

---

### 5.8 Lecture Capture Flow (M13)

```
Home → Quick Actions → "Record Lecture"
    │
    ▼
┌─────────────────────┐
│  Recording Mode      │
│  • 🔴 Recording...   │
│  • Waveform visual   │
│  • Manual notes      │
│    (split-screen)    │
│  • Timestamp markers │
│  • [Stop]            │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Processing          │
│  "Transcribing..."   │
│  (Whisper API)       │
│  "Summarizing..."    │
│  Free: Groq (Llama)  │
│  Paid: OpenAI GPT-4o │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Lecture Notes View  │
│  • AI Summary        │
│    (structured)      │
│  • Full transcript   │
│    (tap line → jump  │
│     to audio moment) │
│  • Audio playback    │
│  • Edit / annotate   │
│  • Export: DOCX, PDF,│
│    ePub, Markdown    │
│  • Generate quiz     │
│    from this lecture  │
└─────────────────────┘
```

---

### 5.9 Purchase Flow

Two distinct paywall contexts exist: the **General App paywall** (Premium upgrade) and the **Exam-Specific paywall** (per-exam subscription). There are no one-time purchases — all paid access is subscription-based.

#### 5.9a General App Premium Purchase

```
Free user hits a Premium-gated feature
    │
    ▼
┌──────────────────────────────────────┐
│  General Paywall (Subrail-managed)   │
│                                      │
│  "Upgrade to Premium"                │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🔥 Monthly — $9.99/mo      │    │
│  │  7-day free trial            │    │
│  │  [Start Free Trial]          │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  💎 Yearly — $59.99/yr      │    │
│  │  ($5.00/mo) — BEST VALUE    │    │
│  │  [Subscribe Yearly]          │    │
│  └──────────────────────────────┘    │
│                                      │
│  [Continue with Free]                │
│  [Restore Purchases]                 │
└──────────────┬───────────────────────┘
               │
     ┌─────────┴──────────┐
     │                    │
     ▼                    ▼
┌──────────┐        ┌──────────────┐
│ Select   │        │ Continue     │
│ plan     │        │ with Free    │
└────┬─────┘        └──────────────┘
     │
     ▼
┌─────────────────────┐
│  Native Store Sheet  │
│  (App Store / Google │
│   Play / Huawei IAP) │
│  Confirm payment     │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Receipt Validation  │
│  (Subrail server)    │
│  Entitlement granted │
│  premium = active    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Success Screen      │
│  "Welcome to         │
│   Premium!"          │
│  → Continue to       │
│    unlocked content  │
└─────────────────────┘
```

#### 5.9b Exam-Specific Subscription Purchase

```
Free user exhausts 10-15 free exam questions
    │
    ▼
┌──────────────────────────────────────┐
│  Exam Paywall (Subrail-managed)      │
│  e.g., "Unlock unlimited SAT prep"   │
│                                      │
│  "X of 15 free questions used"       │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Weekly — $2.99/wk          │    │
│  │  (Tier 2 exam, e.g. SAT)    │    │
│  │  [Subscribe Weekly]          │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Monthly — $7.99/mo         │    │
│  │  [Subscribe Monthly]         │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Yearly — $49.99/yr         │    │
│  │  ($4.17/mo) — BEST VALUE    │    │
│  │  [Subscribe Yearly]          │    │
│  └──────────────────────────────┘    │
│                                      │
│  Pricing shown in local currency     │
│  Tier and price auto-set per exam    │
│  [Restore Purchases]                 │
└──────────────┬───────────────────────┘
               │
     ┌─────────┴──────────┐
     │                    │
     ▼                    ▼
┌──────────┐        ┌──────────────┐
│ Select   │        │ Dismiss      │
│ plan     │        │ (back to     │
└────┬─────┘        │ free content)│
     │              └──────────────┘
     ▼
┌─────────────────────┐
│  Native Store Sheet  │
│  Confirm payment     │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Receipt Validation  │
│  (Subrail server)    │
│  Entitlement granted │
│  exam_[id] = active  │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Success Screen      │
│  "SAT Prep           │
│   Unlocked!"         │
│  "Generate unlimited │
│   questions now"     │
│  → Continue to       │
│    exam content      │
└─────────────────────┘
```

**Pricing note:** Weekly exam subscriptions are capped at $1.99–$2.99 depending on exam tier. See §9.3 for full per-exam pricing tiers.

---

### 5.10 Teacher Flow (M11)

```
Sign Up (Role: Teacher)
    │
    ▼
┌─────────────────────┐
│  Teacher Onboarding  │
│  • School name       │
│  • Subjects taught   │
│  • Create first class│
│    (generates join   │
│     code)            │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Social Tab →        │
│  Teacher Portal      │
│  • My Classes        │
│  • Assignments       │
│  • Grading           │
│  • Class Analytics   │
└──────────┬──────────┘
           │
     ┌─────┼──────┐
     │     │      │
     ▼     ▼      ▼
┌──────┐┌──────┐┌──────┐
│Create││Assign││View  │
│quiz  ││to    ││class │
│(M8)  ││class ││results│
└──────┘└──────┘└──────┘
```

---

### 5.11 Parent Flow (M11)

```
Sign Up (Role: Parent)
    │
    ▼
┌─────────────────────┐
│  Parent Onboarding   │
│  • Enter child's     │
│    invite code       │
│  • Child approves    │
│    link request      │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Social Tab →        │
│  Parent Portal       │
│  • Child's activity  │
│  • Study time/week   │
│  • Recent scores     │
│  • Streak status     │
│  • Weekly report     │
│    (auto-generated)  │
│                      │
│  View-only — cannot  │
│  modify child's data │
└─────────────────────┘
```

---

### 5.12 Offline Flow

```
User goes offline (airplane, no connectivity)
    │
    ▼
┌─────────────────────┐
│  Offline Banner      │
│  "You're offline.    │
│   Downloaded content │
│   is available."     │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  Available Offline   │
│  ✅ Pre-generated Qs │
│  ✅ Downloaded decks  │
│  ✅ Cached mock tests │
│  ✅ Notes (full)      │
│  ✅ Dictionary (if    │
│     pack downloaded) │
│  ✅ Single-player     │
│     games            │
│  ✅ Study planner     │
│  ✅ Progress dashboard│
│  ❌ AI-generated Qs   │
│  ❌ Homework helper   │
│  ❌ Multiplayer games │
│  ❌ Community/social  │
│  ❌ Lecture transcribe │
└──────────┬──────────┘
           │
           │  (User studies offline —
           │   all progress saved
           │   to local outbox)
           │
           ▼
┌─────────────────────┐
│  Connectivity        │
│  Restored            │
│  "Syncing..."        │
│  Outbox → Supabase   │
│  Pull remote changes │
│  Resolve conflicts   │
│  "All caught up ✓"   │
└─────────────────────┘
```

---

### 5.13 User Flow Summary Map

```
┌──────────────┐
│  App Install  │
└──────┬───────┘
       ▼
┌──────────────────────────────────────────────────┐
│  FIRST LAUNCH ONBOARDING (§5.1)                  │
│  1.Boot → 2.Splash → 3.Language → 4.Wizard →    │
│  5.Auth → 6.Paywall → 7.Feature Compare →        │
│  8.Trial Explainer → 9.Home                      │
└──────────────────────┬───────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────┐
│  SUBSEQUENT ACCESS (§5.2)                        │
│  Boot → Auth check → Home (if logged in)         │
│                    → Onboarding (if not)          │
└──────────────────────┬───────────────────────────┘
                       ▼
     ┌─────────────────────────────────────────┐
     │              HOME TAB                   │
     │  Header: Title | 🔍 🔔 🎮              │
     │  Daily plan, streak, quick actions      │
     └──┬────┬────┬────┬────┬────┬────────────┘
        │    │    │    │    │    │
   ┌────┘    │    │    │    │    └──────────┐
   ▼         ▼    ▼    ▼    ▼              ▼
┌───────┐┌──────┐┌──────┐┌──────┐  ┌────────────┐
│Cont.  ││Scan  ││Record││Create│  │🎮 Play Hub │
│Study  ││HW    ││Lect. ││Flash │  │ Games(§5.7)│
│(§5.3) ││(§5.5)││(§5.8)││card  │  │ Challenges │
└──┬────┘└──┬───┘└──┬───┘└──┬───┘  │ Multiplayer│
   │        │       │       │      └────────────┘
   ▼        ▼       ▼       ▼
┌────────────────────────────────────────────────┐
│                  LEARN TAB                     │
│  Exams(§5.3) Flashcards(§5.4) Mock Tests(§5.6)│
│  Homework(§5.5) Quizzes Lectures(§5.8) Notes  │
└──────────────────┬─────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
┌────────────┐┌──────────────┐┌──────────────┐
│ SAGE TAB   ││ SOCIAL TAB   ││ PROFILE TAB  │
│ AI Chat    ││ Community    ││ Dashboard    │
│ Homework   ││ Teacher      ││ Exam Tracker │
│ Quiz Mode  ││ (§5.10)      ││ Settings     │
│ Explain    ││ Parent       ││ Subscription │
│ Plan       ││ (§5.11)      ││ (§5.9)       │
└────────────┘└──────────────┘└──────────────┘
```

---

## 6. Module Definitions

---

### M1: AI-Powered Test Prep Engine

**Purpose:** The core module. Delivers adaptive, exam-specific practice questions powered by Claude AI (exam generation) and Groq/OpenAI (general AI features), covering every major standardized test globally.

#### M1 Features

- **Exam Selection**: Browse and select from 100+ standardized tests organized by region, level (high school, college, graduate, professional), and subject
- **Question Types**: Multiple choice (single and multi-select), true/false, fill-in-the-blank, short answer, essay prompts, passage-based questions, data interpretation, quantitative comparison, sentence completion, error identification
- **Exam-Specific Question Styles**: Each exam's questions mimic the exact format, difficulty, timing, and style of the real test (e.g., SAT Reading passages with line references, GRE quantitative comparison format, WAEC objective questions with 4 options A-D, JAMB UTME CBT-style interface)
- **Adaptive Learning Engine**: Tracks per-topic performance using Item Response Theory (IRT). Automatically increases difficulty when the student demonstrates mastery and focuses on weak areas. Maintains a proficiency score per topic per exam.
- **Non-Adaptive Mode**: Standard mode with randomized questions at a fixed difficulty level
- **Full-Screen Interactive Questions**: Each question occupies the entire screen with clear formatting (LaTeX for math, code blocks for CS, passage rendering for reading), tap-to-select options, immediate audio feedback (correct chime / wrong buzz), visual feedback (green/red highlights with animation), optional timer, and progress indicator
- **Detailed Explanations**: After answering — why the correct answer is correct, why each wrong answer is wrong, related concepts and tips, links to study material
- **Bookmarking**: Save any question for review later, organized by exam and topic
- **Save for Later**: Skip a question and return to it within the same session
- **Free Tier**: 10-15 pre-generated questions per exam stored in the database, offline-capable
- **Paid Exam Subscription**: Unlimited Claude AI-generated questions on demand (exam generation always uses Claude), calibrated to the student's proficiency
- **Session History**: Every session logged with timestamp, score, time per question, topic breakdown

#### M1 Claude API Prompt Template (Example — SAT Math)

```text
You are an expert SAT Math question writer. Generate {count} questions.

Requirements:
- Difficulty level: {difficulty} (1-5 scale)
- Topics to focus on: {weak_topics}
- Format: Multiple choice with exactly 4 options (A, B, C, D)
- Each question includes: question_text (LaTeX where needed), options,
  correct_answer, explanation (step-by-step), topic, difficulty,
  estimated_time_seconds

Return as JSON array. Mimic exact College Board SAT Math style.
```

#### M1 Technical Implementation

```dart
class TestPrepEngine {
  // Free users — fetch pre-generated questions from local DB or Supabase
  Future<List<Question>> getPreGeneratedQuestions(String examId, String sectionId);

  // Paid users — generate via Claude API through Supabase Edge Function
  Future<List<Question>> generateAdaptiveQuestions({
    required String examId,
    required String sectionId,
    required UserProficiency proficiency,
    required int count,
    required DifficultyLevel targetDifficulty,
  });

  // Adaptive difficulty calculation
  DifficultyLevel calculateNextDifficulty(List<QuestionAttempt> recentAttempts);

  // IRT-based proficiency update
  UserProficiency updateProficiency(UserProficiency current, QuestionAttempt attempt);
}
```

---

### M2: Flashcard System

**Purpose:** A Quizlet-style flashcard system enhanced with spaced repetition, multimedia support, community sharing, and AI-powered card generation.

#### M2 Quizlet Base Features

- **Create Decks**: Title, description, subject tag, cover image
- **Card Types**: Text-to-Text, Text-to-Image, Image-to-Text, Audio-to-Text, Rich text with LaTeX
- **Study Modes**:
  - **Flashcard Mode**: Classic flip-card with swipe right (know) / swipe left (don't know), 3D flip animation
  - **Learn Mode**: AI-driven session prioritizing weak cards, combines MCQ + typed answers + true/false
  - **Write Mode**: Type answer from memory with fuzzy matching for typos
  - **Match Mode**: Drag-and-drop matching game against a timer
  - **Test Mode**: Auto-generated test from deck with mixed question types
- **Import/Export**: CSV, TSV, Quizlet format, Anki (.apkg). Export to CSV, PDF, Anki.
- **Deck Sharing**: Share via link, QR code, or within study groups. Public decks discoverable in community library.
- **Community Decks**: Browse, clone, filter by subject/exam/language/rating
- **Deck Folders**: Organize by subject or exam

#### M2 Beyond Quizlet

- **SM-2 Spaced Repetition**: Each card tracks easiness_factor (initial 2.5), interval, repetitions, next_review_date. Cards surfaced at optimal intervals for long-term retention.
- **AI Card Generation**: Paste text / upload PDF / type topic — Groq AI (Llama) for free users / OpenAI GPT-4o for paid users generates a complete deck
- **Auto-Generate from Notes**: One-tap conversion from M7 notes into flashcard decks
- **Auto-Generate from Vocab Lists**: Words saved in M6 automatically become flashcards
- **Image Generation**: OpenAI DALL-E generates visual mnemonics for any card
- **Audio Pronunciation**: TTS in multiple accents (American, British, native language)
- **Card Annotations**: Personal notes or hints on any card
- **Deck Analytics**: Mastery %, cards due, study streak per deck
- **Collaborative Decks**: Multiple users contribute cards to shared decks in real-time
- **Offline Support**: All decks cached locally, sync when connected

#### M2 SM-2 Algorithm

```dart
class SM2Algorithm {
  SpacedRepetitionState review(SpacedRepetitionState state, int quality) {
    // quality: 0-5 (0=blackout, 5=perfect recall)
    if (quality < 3) {
      return state.copyWith(repetitions: 0, interval: 1);
    }
    int newReps = state.repetitions + 1;
    int newInterval = newReps == 1 ? 1 : newReps == 2 ? 6
        : (state.interval * state.easinessFactor).round();
    double newEF = state.easinessFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3;
    return SpacedRepetitionState(
      repetitions: newReps, interval: newInterval,
      easinessFactor: newEF,
      nextReviewDate: DateTime.now().add(Duration(days: newInterval)),
    );
  }
}
```

---

### M3: AI Homework Helper

**Purpose:** A conversational AI tutor that walks students through problems step-by-step with photo-scan capability. Free users: Groq AI (Llama). Paid users: OpenAI GPT-4o.

#### M3 Features

- **Conversational Tutor**: Chat interface using Socratic method — leading questions, hints, concept explanations rather than direct answers
- **Subject Coverage**: Math (LaTeX rendering), physics, chemistry, biology, history, literature, geography, economics, CS, foreign languages
- **Photo Scan (Snap & Solve)**: Take photo of handwritten/printed question — OpenAI Vision extracts and interprets — step-by-step walkthrough. Supports equations, diagrams, graphs, text.
- **Voice Input**: Speak questions via OpenAI Whisper transcription
- **Math Rendering**: Full LaTeX via `flutter_math_fork`
- **Code Helper**: Syntax highlighting, code explanation, debugging assistance for CS students
- **Step-by-Step Solutions**: Numbered steps with per-step explanations
- **Follow-Up**: AI asks "Do you understand this step?" and offers further explanation
- **History**: All conversations saved and searchable by subject/date
- **Offline**: Previously viewed solutions cached. New queries require internet.

#### M3 Technical Stack

- **Chat Engine**: Groq AI (Llama) for free users / OpenAI GPT-4o for paid users — via Supabase Edge Function (server-side API key)
- **Image Processing**: OpenAI Vision API for photo-scan (paid users); OCR-only for free users
- **Voice**: OpenAI Whisper API for speech-to-text
- **Math Rendering**: `flutter_math_fork` package for LaTeX display
- **Code Rendering**: `flutter_highlight` for syntax highlighting
- **Conversation Context**: Maintains history per session (up to 20 messages) for contextual responses

---

### M4: Practice Exams & Mock Tests

**Purpose:** Full-length timed mock exams simulating real test conditions with instant scoring and analytics.

#### M4 Features

- **Full-Length Simulations**: Match exact structure, section count, question count, and time limits of real tests
- **Exam Conditions Mode**: Full-screen lockdown, section timers, no answer review until submission, break timers between sections
- **Section-by-Section**: Practice individual sections or full exam
- **Instant Scoring**: Official scoring methodology per exam (e.g., SAT 200-800, GRE 130-170)
- **Detailed Answer Review**: Your answer vs correct, full explanation, time spent, difficulty rating
- **Post-Test Analytics**: Overall score + percentile estimate, score by section/topic, time analysis, comparison to previous attempts, weak area identification
- **Score Trajectory**: Chart showing improvement over multiple mock tests
- **Predicted Score**: AI predicts likely real test score range based on practice performance
- **Negative Marking**: Configurable per exam (e.g., -0.25 for some exams)
- **Calculator Support**: Basic, scientific, or graphing calculator widget (per exam rules)
- **Free Tier**: 1 free mock test per exam (pre-generated questions)
- **Paid Tier**: Unlimited mock tests with AI-generated questions

#### Exam Simulation Config

```dart
class ExamConfig {
  final String examId;
  final String examName;
  final List<SectionConfig> sections;
  final int totalTimeMinutes;
  final bool hasBreaks;
  final int breakDurationMinutes;
  final ScoringMethod scoringMethod;
  final bool negativeMarking;
  final double negativeMarkPenalty;
  final bool allowSectionNavigation;
  final bool showCalculator;
  final CalculatorType calculatorType; // basic, scientific, graphing
}
```

---

### M5: Brain & Logic Challenges

**Purpose:** Daily brain teasers, puzzles, and logic challenges for cognitive engagement and app stickiness.

#### M5 Features

- **Daily Challenge**: New challenge at midnight local time. Completing extends streak.
- **Categories**: Math puzzles, word problems, lateral thinking, logic puzzles (syllogisms, grid logic), pattern recognition, memory challenges, speed rounds
- **Difficulty Tiers**: Easy, Medium, Hard, Expert — unlocked progressively
- **Streaks**: Consecutive daily completions. Streak freeze (1/week for premium).
- **Leaderboards**: Global, friends, school/institution, regional (by country)
- **Badges & Achievements**: Milestones (7-day streak, 30-day, 100 puzzles, etc.)
- **XP System**: Every challenge awards XP contributing to user level
- **Challenge History**: Review past challenges and solutions
- **Offline**: Daily challenges pre-fetched and cached for offline play

---

### M6: Vocabulary Builder & Dictionary

**Purpose:** Comprehensive vocabulary tool with dictionary, curated word lists, audio pronunciation, and auto-flashcard generation.

#### M6 Features

- **Built-In Dictionary**: Multiple definitions, etymology, synonyms/antonyms, 3-5 example sentences, part of speech, IPA phonetics, audio pronunciation (American/British English + other languages)
- **Word of the Day**: Curated daily word with definition, usage, quiz. Push notification at preferred time.
- **Subject-Specific Lists**: SAT/GRE high-frequency, medical (MCAT/USMLE), legal (LSAT/Bar), scientific (AP), business (GMAT/CFA), literary, computing/CS
- **Personal Vocab Lists**: Save words, organize by subject/custom tags
- **Auto-Flashcard Generation**: Saved words auto-generate flashcards in linked M2 deck
- **Vocabulary Quiz**: Definition matching, fill-in-blank, synonym/antonym ID, spelling from audio
- **Progress Tracking**: Words learned / in progress / to review. Spaced repetition applied.
- **Multi-Language Support**: Dictionary and pronunciation available in all supported app languages
- **Offline**: Full dictionary DB downloadable (~200MB). Audio files downloadable per language.

---

### M7: Note-Taking & Study Organizer

**Purpose:** Integrated rich-text note editor with AI summarization and auto quiz/flashcard generation.

#### M7 Features

- **Rich Text Editor**: Bold, italic, underline, headings (H1-H3), bullet/numbered lists, checklists, code blocks with syntax highlighting, LaTeX math equations inline, image/audio embedding, highlighting in multiple colors, tables
- **Organization**: Subject, Topic, Date hierarchy. Tags for cross-referencing. Full-text search. Pin important notes. Archive old notes.
- **AI Summarization**: Select notes — AI generates concise summary with key points, definitions, action items
- **AI Quiz Generation**: One-tap quiz from note content (via M8 + Claude)
- **AI Flashcard Generation**: One-tap flashcards from notes (feeds M2)
- **Templates**: Cornell method, lab reports, book summaries, study group notes
- **Export**: PDF (formatted, print-ready), DOCX (editable), Markdown, plain text
- **Collaboration**: Share with study group. Real-time collaborative editing (premium).
- **Offline**: All notes stored locally, sync to cloud when connected

---

### M8: AI Quiz & Question Generator

**Purpose:** Paste text, upload PDF, or type a topic — AI instantly generates a quiz. Free users: Groq AI (Llama), up to 5 questions/quiz. Paid users: OpenAI GPT-4o, unlimited. Exam-specific quizzes always use Claude.

#### M8 Features

- **Input Methods**: Paste text, upload PDF, upload image (OCR via OpenAI Vision), type topic, select from M7 notes, select from M13 lecture transcripts
- **Generation Config**: Question count (5-20+), question types (MCQ, T/F, fill-blank, short answer, essay), difficulty level. Each question includes correct answer + detailed explanation.
- **Quiz Customization**: Time limits per question or whole quiz, shuffle questions/options, show explanations after each question or at end
- **Quiz Sharing**: Share via link or QR code
- **Teacher Mode**: Generate and assign to class (M11 integration)
- **Quiz Library**: Save for reuse, browse community-shared quizzes
- **Offline**: Previously generated quizzes cached. New generation requires internet.

---

### M9: Progress Dashboard & Analytics

**Purpose:** Visual dashboard with learning analytics, gamification, and predicted scores.

#### M9 Features

- **Overview Dashboard**: Current streak, total XP + level, hours studied this week/month, questions answered today, active exams being prepared for
- **Exam-Specific Analytics**: Score trajectory chart (mock test scores over time), topic mastery heatmap (green = mastered, yellow = in progress, red = weak), predicted score range, readiness %, exam countdown
- **Topic Breakdown**: Per-topic accuracy rate, question count attempted, average time per question, improvement trend
- **Study Habits**: Daily/weekly study time chart, most productive study hours, session length distribution, consistency score
- **Gamification**:
  - **XP Points**: Earned from every activity (questions, flashcards, games, streaks)
  - **Levels**: Level up every N XP. Displayed on profile.
  - **Badges**: Achievement badges for milestones (first mock test, 100-day streak, all topics mastered, etc.)
  - **Streak Calendar**: Visual calendar showing study days
- **Comparative Analytics** (Premium): Compare scores to average Witt user for same exam, percentile ranking
- **Export**: Download progress report as PDF — useful for parent-teacher meetings, scholarship applications

---

### M10: Community & Social Layer

**Purpose:** Collaboration, competition, and peer learning features.

#### M10 Features

- **Study Groups**: Create/join (public or invite-only), group chat, shared flashcard decks, group quiz challenges, shared study timer
- **Q&A Forum**: Post questions (text/image/LaTeX), peer + AI answers, upvote/downvote, tags by subject/exam, best answer marking, reputation system
- **Leaderboards**: Global (XP), per-exam (mock scores), friends, school, weekly/monthly/all-time views
- **Friend System**: Add via username/QR/contacts, activity feed (opt-in), challenge friends to quizzes
- **Deck Marketplace**: Share/discover flashcard decks, ratings/reviews, featured/trending
- **Content Moderation**: AI-powered moderation for community posts + report system for inappropriate content

---

### M11: Teacher & Parent Portal

**Purpose:** Teacher classroom management and parent progress monitoring.

#### Teacher Features

- **Class Management**: Create classes with join codes, add/remove students, organize by subject/section
- **Assignments**: Assign quizzes (M8), flashcard decks, mock tests, educational games. Set due dates and time limits.
- **Grading**: Auto-graded assignments with instant results. Manual grading for essay/short-answer. Written feedback per student.
- **Class Analytics**: Class average scores per assignment, individual student progress, topic-level class performance heatmap, identify struggling students, export reports (PDF/CSV)
- **Content Library**: Save and reuse created quizzes and assignments

#### Parent Features

- **Child Linking**: Connect via invite code (child must approve)
- **Activity Overview**: Time spent studying per day/week, subjects studied, streak status, recent quiz/test scores
- **Progress Reports**: Weekly automated summary via push notification or email
- **Screen Time**: Daily app usage breakdown
- **Privacy-Respecting**: View-only — parents cannot modify the child's study content

---

### M12: Offline Mode

**Purpose:** Full offline functionality for students in low-connectivity regions — critical for markets across Africa, South Asia, and rural areas globally.

#### Content Packs

Downloadable bundles organized by exam and subject:

- Pre-generated questions (10-15 per exam free, full question banks for premium)
- Flashcard decks (community + official)
- Vocabulary databases and dictionary data
- Study materials and explanations
- Language packs for offline translation

#### Download Manager

- Browse available packs with size estimates
- Wi-Fi only download option
- Pause/resume downloads
- Storage usage display
- Auto-update packs when connected

#### Offline Feature Matrix

| Feature | Offline | Notes |
|---------|---------|-------|
| Pre-generated test questions (M1 free) | Yes | Stored locally |
| Flashcard study — all modes (M2) | Yes | Cached decks |
| Previously viewed homework solutions (M3) | Yes | Cached responses |
| Downloaded mock tests (M4) | Yes | Pre-downloaded |
| Brain challenges (M5) | Yes | Pre-fetched daily |
| Dictionary lookup (M6) | Yes | With downloaded DB |
| Note-taking and editing (M7) | Yes | Local storage |
| Previously generated quizzes (M8) | Yes | Cached |
| Progress dashboard (M9) | Yes | Local data |
| Educational games — single-player (M14) | Yes | Local |
| Study planner (M15) | Yes | Local |
| Offline translation | Yes | With language packs |
| AI-generated questions | No | Requires internet |
| AI homework helper (new queries) | No | Requires internet |
| Community features (M10) | No | Requires internet |
| Multiplayer games | No | Requires internet |

#### Sync Engine

- All offline activity (answers, progress, notes, flashcard reviews) queued in local outbox
- Pushes pending changes to Supabase when connectivity restored
- Conflict resolution: server authority for shared data, last-write-wins for personal data
- Delta sync — only changed records synced, not full datasets
- Recommended minimum: 500MB free space for core content

```dart
class SyncEngine {
  Future<SyncResult> performSync() async {
    await pushPendingChanges();   // 1. Push local outbox
    await pullRemoteChanges();    // 2. Pull changes since last sync
    await resolveConflicts();     // 3. Resolve any conflicts
    await updateSyncTimestamp();  // 4. Update last sync time
  }
}
```

---

### M13: Lecture Capture & AI Summarization

**Purpose:** Record or upload lectures and get AI-generated transcripts, structured summaries, and exportable study notes.

#### M13 Features

- **Live Recording Mode**: One-tap audio recording during lectures, optional video, real-time waveform visualization, manual note-taking alongside (split-screen), timestamp markers for important moments, background recording support
- **Upload Mode**: Import audio (MP3, WAV, M4A, AAC, OGG), video (MP4, MOV, AVI, MKV), cloud import (Google Drive, iCloud, OneDrive), drag-and-drop on desktop
- **AI Transcription**: OpenAI Whisper API, multi-language support, speaker identification, timestamps synced to audio (tap any line to jump), editable transcript for corrections
- **AI Summary Generation**: Groq AI (Llama) for free users / OpenAI GPT-4o for paid users processes transcript and generates structured summary with headings, key points, definitions spotted in lecture, action items/assignments mentioned, key quotes. Summary linked to original recording.
- **Notes View**: Clean readable format by subject/date, recording alongside summary, highlight sections, add personal annotations, search within transcripts and summaries
- **Export**: DOCX (formatted Word document), PDF (print-ready), ePub (for e-readers like Kindle/Apple Books), Markdown, plain text
- **Reader Mode**: Optimized reading on any screen — adjustable font size, line spacing, dark/light theme
- **Offline**: Previously transcribed lectures available offline. New transcription/summarization requires internet.

---

### M14: Educational Games

**Purpose:** Gamified learning experiences reinforcing knowledge while driving daily engagement.

#### Games

| Game | Description | Players |
|------|-------------|---------|
| **Word Duel** | 1v1 real-time vocabulary/spelling battle. First correct answer wins round. Best of 10. Skill-based matchmaking. | 2 |
| **Quiz Royale** | Battle royale — up to 50 players. Simultaneous questions. Wrong = eliminated. Last standing wins. Teacher can create private rooms. | 2-50 |
| **Equation Rush** | Math equations fly across screen. Solve before edge. Difficulty scales with performance. Combo multiplier for consecutive correct. | 1 |
| **Fact or Fiction** | Rapid-fire true/false with countdown. Curriculum-aligned content from student's active exams. Streak bonuses. | 1 |
| **Crossword Builder** | Auto-generated from flashcard decks/vocab lists. Timed + relaxed modes. | 1 |
| **Memory Match** | Card-flip matching — terms and definitions from study material. Timed with move counter. Personal best tracking. | 1 |
| **Timeline Challenge** | Arrange events chronologically via drag-and-drop. Covers history, science, literature. | 1 |
| **Spelling Bee** | Audio plays word, student types spelling. Progressive difficulty. Regional leaderboards by age group. | 1 |
| **Subject Boss Battles** | End-of-module boss: 20 hard questions from a topic. Defeat = badge + new content unlocked. | 1 |

#### Game Integration

- All games feed into XP and achievement system (M9)
- Teachers can assign games as homework (M11)
- Multiplayer games require internet; single-player games work offline
- Game scores tracked in `game_scores` table
- Sound effects and animations for correct/wrong answers, combos, victories

---

### M15: Study & Exam Planner

**Purpose:** Personal academic strategist combining forward-looking study planning with comprehensive exam tracking and performance analysis.

#### Study Planner Features

- **Smart Schedule Builder**: Input exam date, available hours/day, unavailable days, subjects needing attention — generates balanced day-by-day plan working backward from deadline
- **Auto-Redistribution**: If student misses a session, planner redistributes content across remaining days automatically
- **Syllabus Upload**: Upload official syllabus/topic list — app maps it into the planner automatically
- **Daily Study Goals**: Push notification each morning with today's study plan. Completing goals feeds streak + XP.
- **Assignment Tracking**: Not just exams — essays, lab reports, group projects, any academic deadline
- **Calendar View**: Daily, weekly, monthly views. Color-coded by subject. List view alternative.
- **Subject/Topic Breakdown**: Checkable list of everything to cover for each exam

#### Exam Tracker Features

- **Exam Registry**: Log every exam — name, subject, date, type (standardized/school/mock/assessment), result when available
- **Academic History**: Complete record across the student's entire journey — useful for applications and personal reference
- **Performance Trend Analysis**: Score history charts per subject/exam type. AI reads trends and recommends focus areas (e.g., "Your Math scores have plateaued over your last 3 practice tests. Focus on Algebra and Trigonometry this week.")
- **Exam Countdowns**: Dashboard widget showing days remaining + readiness percentage per registered exam
- **Target Score Tracking**: Set target (e.g., 1400 SAT) — tracker maps mock scores against target, projects whether student is on track based on improvement rate
- **Registration Deadline Reminders**: App knows when major test registration windows open/close, notifies students in advance
- **Section-Level Breakdown**: Not just overall score — performance per section (e.g., 780 Reading, 590 Math)
- **Export & Share**: Generate clean PDF report of exam history and progress — for parent-teacher meetings, scholarship applications, personal records

---

## 7. Standardized Test Catalog

Every exam below is supported with exam-specific question styles, scoring methodology, section structure, and timing rules. Free users get 10-15 pre-generated questions per exam. Paid users get unlimited AI-generated questions.

---

### 7.1 United States

#### High School Admission & Placement

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **SSAT** | Secondary School Admission Test | Private high school admission |
| **ISEE** | Independent School Entrance Exam | Private high school admission |
| **HSPT** | High School Placement Test | Catholic high school placement |
| **SHSAT** | Specialized High Schools Admissions Test | NYC specialized high schools |
| **COOP** | Cooperative Admissions Examination | Catholic high school (NJ/NY) |
| **TACHS** | Test for Admission into Catholic High Schools | Catholic high school (NYC) |

#### High School Level

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **PSAT 8/9** | Preliminary SAT 8/9 | College readiness benchmark (8th-9th grade) |
| **PSAT/NMSQT** | Preliminary SAT / National Merit Scholarship Qualifying Test | National Merit qualification, SAT practice |
| **SAT** | Scholastic Assessment Test | College admission |
| **ACT** | American College Testing | College admission |
| **AP Exams** | Advanced Placement (38 subjects) | College credit — includes: Calculus AB/BC, Statistics, Physics 1/2/C, Chemistry, Biology, Environmental Science, CS A/Principles, English Language/Literature, US/World/European History, Government, Economics (Micro/Macro), Psychology, Human Geography, Art History, Music Theory, Spanish/French/German/Chinese/Japanese/Latin, Seminar, Research |
| **GED** | General Educational Development | High school equivalency |
| **HiSET** | High School Equivalency Test | High school equivalency (alternative to GED) |
| **ASVAB** | Armed Services Vocational Aptitude Battery | Military qualification |
| **CLT** | Classic Learning Test | College admission (alternative to SAT/ACT) |

#### College & Graduate Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **GRE** | Graduate Record Examination (General + Subject) | Graduate school admission |
| **GMAT** | Graduate Management Admission Test | MBA / business school admission |
| **LSAT** | Law School Admission Test | Law school admission |
| **MCAT** | Medical College Admission Test | Medical school admission |
| **DAT** | Dental Admission Test | Dental school admission |
| **OAT** | Optometry Admission Test | Optometry school admission |
| **PCAT** | Pharmacy College Admission Test | Pharmacy school admission |
| **MAT** | Miller Analogies Test | Graduate school admission |
| **TOEFL** | Test of English as a Foreign Language | English proficiency for international students |
| **IELTS** | International English Language Testing System | English proficiency |
| **Duolingo English Test** | DET | English proficiency (online) |
| **PTE Academic** | Pearson Test of English | English proficiency |

#### US Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **USMLE** | US Medical Licensing Examination (Step 1, 2 CK, 3) | Medical licensure |
| **COMLEX** | Comprehensive Osteopathic Medical Licensing Exam | Osteopathic medical licensure |
| **NCLEX-RN** | National Council Licensure Exam — Registered Nurse | Nursing licensure |
| **NCLEX-PN** | National Council Licensure Exam — Practical Nurse | Practical nursing licensure |
| **Bar Exam** | Uniform Bar Examination (UBE) + state-specific | Law practice licensure |
| **MPRE** | Multistate Professional Responsibility Exam | Legal ethics (required for bar) |
| **CPA** | Certified Public Accountant Exam | Accounting licensure |
| **CFA** | Chartered Financial Analyst (Level I, II, III) | Finance certification |
| **FRM** | Financial Risk Manager | Risk management certification |
| **Series 7** | General Securities Representative Exam | Securities broker licensure |
| **Series 63** | Uniform Securities Agent State Law Exam | State securities licensure |
| **Series 65** | Uniform Investment Adviser Law Exam | Investment adviser licensure |
| **Series 66** | Uniform Combined State Law Exam | Combined 63+65 |
| **SIE** | Securities Industry Essentials | Securities industry entry |
| **FE** | Fundamentals of Engineering | Engineering licensure (first step) |
| **PE** | Principles and Practice of Engineering | Professional engineer licensure |
| **PMP** | Project Management Professional | Project management certification |
| **CAPM** | Certified Associate in Project Management | Entry-level PM certification |
| **PRAXIS** | Praxis Core / Subject Tests | Teacher licensure |
| **NBCOT** | National Board for Certification in OT | Occupational therapy licensure |
| **NAPLEX** | North American Pharmacist Licensure Exam | Pharmacist licensure |
| **NREMT** | National Registry of Emergency Medical Technicians | EMT certification |

---

### 7.2 United Kingdom

#### Secondary School

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **11+** | Eleven Plus | Grammar/selective school admission (age 10-11) |
| **13+** | Thirteen Plus (Common Entrance) | Independent school admission (age 13) |
| **GCSE** | General Certificate of Secondary Education | End of secondary school (age 16) |
| **IGCSE** | International GCSE | International version of GCSE |

#### Post-16 / University Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **A-Levels** | Advanced Level (all subjects) | University admission (age 18) |
| **AS-Levels** | Advanced Subsidiary Level | First year of A-Level |
| **Scottish Highers** | Scottish Higher / Advanced Higher | University admission (Scotland) |
| **IB** | International Baccalaureate Diploma | University admission (international) |
| **BTEC** | Business and Technology Education Council | Vocational qualification |
| **T-Levels** | Technical Levels | Vocational qualification (new) |

#### UK University Admission Tests

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **UCAT** | University Clinical Aptitude Test | Medicine/dentistry admission |
| **BMAT** | BioMedical Admissions Test | Medicine admission (select universities) |
| **LNAT** | Law National Aptitude Test | Law admission |
| **TSA** | Thinking Skills Assessment | Oxford/Cambridge admission |
| **MAT** | Mathematics Admissions Test | Oxford maths admission |
| **STEP** | Sixth Term Examination Paper | Cambridge maths admission |
| **PAT** | Physics Aptitude Test | Oxford physics admission |
| **HAT** | History Aptitude Test | Oxford history admission |
| **ELAT** | English Literature Admissions Test | Oxford English admission |
| **TMUA** | Test of Mathematics for University Admission | Maths-heavy courses |
| **NSAA** | Natural Sciences Admissions Assessment | Cambridge sciences |
| **ENGAA** | Engineering Admissions Assessment | Cambridge engineering |

#### UK Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **ACCA** | Association of Chartered Certified Accountants | Accounting qualification |
| **CIMA** | Chartered Institute of Management Accountants | Management accounting |
| **ACA** | Associate Chartered Accountant (ICAEW) | Chartered accountancy |
| **SQE** | Solicitors Qualifying Examination (SQE1, SQE2) | Solicitor qualification (England/Wales) |
| **BPTC** | Bar Professional Training Course assessments | Barrister qualification |
| **MRCP** | Membership of the Royal Colleges of Physicians | Physician postgraduate |
| **MRCS** | Membership of the Royal Colleges of Surgeons | Surgeon postgraduate |
| **PLAB** | Professional and Linguistic Assessments Board | International medical graduates (UK) |
| **FRCA** | Fellowship of the Royal College of Anaesthetists | Anaesthetics postgraduate |
| **FRCOphth** | Fellowship of the Royal College of Ophthalmologists | Ophthalmology postgraduate |
| **MRCGP** | Membership of the Royal College of General Practitioners | GP qualification |
| **RICS APC** | Royal Institution of Chartered Surveyors Assessment | Chartered surveyor |
| **CIPD** | Chartered Institute of Personnel and Development | HR qualification |

---

### 7.3 Europe

#### Germany

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Abitur** | Allgemeine Hochschulreife | University admission (end of Gymnasium) |
| **Mittlerer Schulabschluss** | MSA / Realschulabschluss | Secondary school certificate |
| **TestAS** | Test for Academic Studies | University admission for international students |
| **TestDaF** | Test Deutsch als Fremdsprache | German proficiency for university |
| **DSH** | Deutsche Sprachpruefung fuer den Hochschulzugang | German proficiency for university |
| **TMS** | Test fuer Medizinische Studiengaenge | Medicine admission |
| **PhaST** | Pharmazie-Studieneignungstest | Pharmacy admission |

#### France

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Baccalaureat** | Baccalaureat General / Technologique / Professionnel | University admission (end of lycee) |
| **Brevet** | Diplome National du Brevet | End of college (age 15) |
| **DELF** | Diplome d'Etudes en Langue Francaise (A1-B2) | French proficiency |
| **DALF** | Diplome Approfondi de Langue Francaise (C1-C2) | Advanced French proficiency |
| **TCF** | Test de Connaissance du Francais | French proficiency |
| **Concours** | Grandes Ecoles entrance exams (various) | Elite institution admission |

#### Spain

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Selectividad / EBAU** | Evaluacion de Bachillerato para el Acceso a la Universidad | University admission |
| **ESO** | Educacion Secundaria Obligatoria | Secondary school completion |
| **DELE** | Diplomas de Espanol como Lengua Extranjera | Spanish proficiency |
| **SIELE** | Servicio Internacional de Evaluacion de la Lengua Espanola | Spanish proficiency (digital) |
| **MIR** | Medico Interno Residente | Medical residency exam |

#### Italy

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Maturita** | Esame di Stato (Maturita) | University admission (end of secondary) |
| **TOLC** | Test OnLine CISIA | University admission (various faculties) |
| **IMAT** | International Medical Admissions Test | Medicine admission (English-taught) |
| **CILS** | Certificazione di Italiano come Lingua Straniera | Italian proficiency |
| **CELI** | Certificato di Conoscenza della Lingua Italiana | Italian proficiency |

#### Netherlands

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Eindexamen VWO** | VWO Final Examination | University admission |
| **Eindexamen HAVO** | HAVO Final Examination | Applied university admission |
| **NT2** | Nederlands als Tweede Taal (Staatsexamen) | Dutch proficiency |
| **CCVX** | Commissie Collectieve Voorziening Voortentamens | University math/science entrance |

#### Pan-European

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **IB** | International Baccalaureate Diploma Programme | University admission (global) |
| **European Baccalaureate** | EB | European Schools graduation |
| **Cambridge International** | Cambridge IGCSE / AS / A Level | International secondary qualifications |
| **CEFR Exams** | Common European Framework language exams | Language proficiency (all EU languages) |
| **ECDL/ICDL** | European/International Computer Driving Licence | Digital literacy certification |

#### European Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **European Patent Qualifying Exam** | EQE | European patent attorney |
| **EBVS Exams** | European Board of Veterinary Specialisation | Veterinary specialist |
| **CESB** | Chartered Engineer (various EU bodies) | Engineering qualification |
| **European Bar Exams** | Country-specific (Staatsexamen DE, CRFPA FR, etc.) | Legal practice per country |

---

### 7.4 India

#### School Level

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **CBSE Board (Class 10)** | Central Board of Secondary Education | Secondary school completion |
| **CBSE Board (Class 12)** | Central Board of Secondary Education | Higher secondary completion |
| **ICSE (Class 10)** | Indian Certificate of Secondary Education | Secondary school completion |
| **ISC (Class 12)** | Indian School Certificate | Higher secondary completion |
| **State Board Exams** | Various state boards (Maharashtra, Tamil Nadu, etc.) | State-level school completion |

#### Undergraduate Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **JEE Main** | Joint Entrance Examination Main | Engineering admission (NITs, IIITs) |
| **JEE Advanced** | Joint Entrance Examination Advanced | IIT admission |
| **NEET-UG** | National Eligibility cum Entrance Test (UG) | Medical/dental admission |
| **CUET** | Common University Entrance Test | Central university admission |
| **CLAT** | Common Law Admission Test | National law university admission |
| **AILET** | All India Law Entrance Test | NLU Delhi admission |
| **NDA** | National Defence Academy Exam | Defence forces admission |
| **BITSAT** | BITS Admission Test | BITS Pilani admission |
| **VITEEE** | VIT Engineering Entrance Exam | VIT admission |
| **SRMJEEE** | SRM Joint Engineering Entrance Exam | SRM admission |
| **NIFT** | National Institute of Fashion Technology Entrance | Fashion/design admission |
| **NID** | National Institute of Design Entrance | Design admission |
| **UCEED** | Undergraduate Common Entrance Exam for Design | IIT design admission |

#### Graduate Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **CAT** | Common Admission Test | IIM / MBA admission |
| **GATE** | Graduate Aptitude Test in Engineering | M.Tech / PSU admission |
| **NEET-PG** | National Eligibility cum Entrance Test (PG) | Medical postgraduate admission |
| **XAT** | Xavier Aptitude Test | XLRI / MBA admission |
| **MAT** | Management Aptitude Test | MBA admission |
| **CMAT** | Common Management Admission Test | MBA admission |
| **SNAP** | Symbiosis National Aptitude Test | Symbiosis MBA admission |
| **IIFT** | Indian Institute of Foreign Trade Entrance | IIFT MBA admission |

#### Indian Professional & Competitive Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **UPSC CSE** | Union Public Service Commission Civil Services Exam | IAS/IPS/IFS officer selection |
| **UPSC CDS** | Combined Defence Services Exam | Defence officer selection |
| **SSC CGL** | Staff Selection Commission Combined Graduate Level | Government job selection |
| **SSC CHSL** | SSC Combined Higher Secondary Level | Government job selection |
| **IBPS PO** | Institute of Banking Personnel Selection — PO | Bank officer recruitment |
| **IBPS Clerk** | IBPS Clerk Exam | Bank clerk recruitment |
| **RBI Grade B** | Reserve Bank of India Grade B | RBI officer recruitment |
| **CA** | Chartered Accountant (Foundation, Inter, Final) | Accounting qualification (ICAI) |
| **CS** | Company Secretary (Foundation, Executive, Professional) | Corporate governance (ICSI) |
| **CMA** | Cost and Management Accountant | Cost accounting (ICMAI) |
| **UGC NET** | University Grants Commission National Eligibility Test | Lecturership / JRF eligibility |

---

### 7.5 Africa

#### Pan-African / West Africa

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **WAEC / WASSCE** | West African Examinations Council / West African Senior School Certificate Exam | Secondary school completion (Nigeria, Ghana, Sierra Leone, Liberia, Gambia) |
| **JAMB UTME** | Joint Admissions and Matriculation Board — Unified Tertiary Matriculation Exam | University admission (Nigeria) |
| **NECO** | National Examinations Council | Secondary school completion (Nigeria) |
| **NABTEB** | National Business and Technical Examinations Board | Technical/vocational certification (Nigeria) |
| **BECE** | Basic Education Certificate Examination | Junior secondary completion (Ghana, Nigeria) |
| **Post-UTME** | Post-Unified Tertiary Matriculation Exam | University-specific screening (Nigeria) |

#### East Africa

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **KCPE** | Kenya Certificate of Primary Education | Primary school completion (Kenya) |
| **KCSE** | Kenya Certificate of Secondary Education | Secondary school completion (Kenya) |
| **UACE** | Uganda Advanced Certificate of Education | University admission (Uganda) |
| **UCE** | Uganda Certificate of Education | Secondary completion (Uganda) |
| **CSEE** | Certificate of Secondary Education Examination | Secondary completion (Tanzania) |
| **ACSEE** | Advanced Certificate of Secondary Education Exam | University admission (Tanzania) |
| **National Exam (Rwanda)** | National Examination for S6 | University admission (Rwanda) |

#### Southern Africa

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **NSC / Matric** | National Senior Certificate (Matric) | University admission (South Africa) |
| **NBT** | National Benchmark Tests | University placement (South Africa) |
| **MANEB** | Malawi National Examinations Board exams | Secondary completion (Malawi) |
| **ZIMSEC** | Zimbabwe School Examinations Council | Secondary completion (Zimbabwe) |
| **ECZ** | Examinations Council of Zambia | Secondary completion (Zambia) |

#### North Africa

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Baccalaureat (Algeria)** | Baccalaureat Algerien | University admission (Algeria) |
| **Baccalaureat (Tunisia)** | Baccalaureat Tunisien | University admission (Tunisia) |
| **Baccalaureat (Morocco)** | Baccalaureat Marocain | University admission (Morocco) |
| **Thanawiya Amma** | General Secondary Education Certificate | University admission (Egypt) |

#### African Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **ICAN** | Institute of Chartered Accountants of Nigeria | Accounting qualification (Nigeria) |
| **CITN** | Chartered Institute of Taxation of Nigeria | Tax qualification (Nigeria) |
| **ICAG** | Institute of Chartered Accountants Ghana | Accounting qualification (Ghana) |
| **SAICA** | South African Institute of Chartered Accountants | Accounting qualification (South Africa) |
| **Nigerian Bar Exam** | Nigerian Law School Bar Finals | Legal practice (Nigeria) |
| **MDCN Exams** | Medical and Dental Council of Nigeria | Medical licensure (Nigeria) |

---

### 7.6 China

#### School & University Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Zhongkao** | Senior High School Entrance Examination | High school admission (age 15) |
| **Gaokao** | National College Entrance Examination | University admission — the single most important exam in China. Covers Chinese, Mathematics, Foreign Language + electives |
| **Xiao Gaokao** | Academic Proficiency Test | High school graduation + Gaokao eligibility |

#### Graduate Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **NPEE / Kaoyan** | National Postgraduate Entrance Examination | Master's/PhD admission |
| **MBA Entrance** | National MBA Entrance Exam (Management category) | MBA admission |
| **Judicial Exam** | National Unified Legal Professional Qualification Exam | Legal practice qualification |

#### Language & Proficiency

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **CET-4** | College English Test Band 4 | English proficiency (undergraduate requirement) |
| **CET-6** | College English Test Band 6 | Advanced English proficiency |
| **TEM-4** | Test for English Majors Band 4 | English major proficiency |
| **TEM-8** | Test for English Majors Band 8 | Advanced English major proficiency |
| **HSK** | Hanyu Shuiping Kaoshi (Levels 1-6) | Chinese proficiency for foreigners |
| **HSKK** | HSK Speaking Test | Chinese speaking proficiency |

#### Chinese Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **National Civil Service Exam** | Guokao | Central government civil service |
| **Provincial Civil Service** | Shengkao | Provincial government positions |
| **CPA (China)** | Chinese Certified Public Accountant | Accounting qualification (CICPA) |
| **National Medical Licensing** | Zhiye Yishi Kaoshi | Medical practice licensure |
| **National Judicial Exam** | Falv Zhiye Zige Kaoshi | Legal practice qualification |
| **Teacher Qualification** | Jiaoshi Zige Kaoshi | Teaching certification |

---

### 7.7 Latin America

#### Brazil

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **ENEM** | Exame Nacional do Ensino Medio | University admission (national) — used by all federal universities and many private ones |
| **Vestibular** | University-specific entrance exams (USP, UNICAMP, etc.) | University admission (institution-specific) |
| **ENADE** | Exame Nacional de Desempenho dos Estudantes | Higher education quality assessment |
| **OAB** | Ordem dos Advogados do Brasil Exam | Bar exam (legal practice) |
| **CELPE-Bras** | Certificado de Proficiencia em Lingua Portuguesa | Portuguese proficiency for foreigners |
| **Revalida** | Exame Nacional de Revalidacao de Diplomas Medicos | Foreign medical degree revalidation |
| **CFC** | Conselho Federal de Contabilidade Exam | Accounting qualification |

#### Chile

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **PAES** | Prueba de Acceso a la Educacion Superior (replaced PSU) | University admission |
| **SIMCE** | Sistema de Medicion de la Calidad de la Educacion | National education quality assessment |
| **EUNACOM** | Examen Unico Nacional de Conocimientos de Medicina | Medical licensure |

#### Colombia

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **ICFES Saber 11** | Saber 11 (formerly ICFES) | University admission (end of secondary) |
| **Saber Pro** | Saber Pro (formerly ECAES) | Higher education quality assessment |
| **Saber TyT** | Saber TyT | Technical education assessment |

#### Mexico

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **EXANI-I** | Examen Nacional de Ingreso I | High school admission |
| **EXANI-II** | Examen Nacional de Ingreso II | University admission |
| **EXANI-III** | Examen Nacional de Ingreso III | Graduate school admission |
| **COMIPEMS** | Concurso de Ingreso a la Educacion Media Superior | Mexico City high school admission |
| **CENEVAL EGEL** | Examen General para el Egreso de Licenciatura | Professional degree exit exam |
| **ENARM** | Examen Nacional para Aspirantes a Residencias Medicas | Medical residency admission |

#### Argentina

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **CBC** | Ciclo Basico Comun (UBA) | University of Buenos Aires common cycle |
| **Ingreso Universitario** | University-specific entrance exams | University admission (varies by institution) |

#### Other Latin America

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **PAA (Puerto Rico)** | Prueba de Aptitud Academica | University admission (College Board PR) |
| **Prueba de Transicion (Peru)** | National university admission exam | University admission (Peru) |
| **ENES (Ecuador)** | Examen Nacional para la Educacion Superior | University admission (Ecuador) |

---

### 7.8 Japan

#### School & University Admission

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **Common Test** | Daigaku Nyushi Kyotsu Test (replaced Center Test) | National university admission (standardized first stage) |
| **University-Specific Exams** | Niji Shiken (Second Stage) | Individual university entrance exams |
| **High School Entrance** | Koukou Nyushi | High school admission exams (prefecture-specific) |
| **EJU** | Examination for Japanese University Admission for International Students | University admission for international students |

#### Language & Proficiency

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **JLPT** | Japanese-Language Proficiency Test (N1-N5) | Japanese proficiency for foreigners |
| **Eiken** | Eiken Test in Practical English Proficiency (Grade 1-5) | English proficiency (widely used in Japan) |
| **TOEIC** | Test of English for International Communication | English proficiency (business-focused, very popular in Japan) |
| **Kanji Kentei** | Nihon Kanji Noryoku Kentei (Levels 1-10) | Kanji proficiency |

#### Japanese Professional Exams

| Exam | Full Name | Purpose |
|------|-----------|---------|
| **National Medical Exam** | Ishi Kokka Shiken | Medical licensure |
| **Bar Exam (Japan)** | Shiho Shiken | Legal practice qualification |
| **CPA (Japan)** | Konin Kaikeishi Shiken | Certified public accountant |
| **National Civil Service** | Kokka Komuin Shiken | Government civil service |
| **IT Passport** | Joho Shori Gijutsusha Shiken | IT fundamental certification |
| **Fundamental IT Engineer** | Kihon Joho Gijutsusha | IT engineer certification |
| **Tax Accountant** | Zeirishi Shiken | Tax accountant qualification |

---

### 7.9 Global Professional Exams

These exams are administered internationally and recognized across multiple countries.

#### Finance & Accounting

| Exam | Full Name | Regions |
|------|-----------|---------|
| **CFA** | Chartered Financial Analyst (Level I, II, III) | Global (US-based, CFA Institute) |
| **FRM** | Financial Risk Manager (Part I, II) | Global (US-based, GARP) |
| **CAIA** | Chartered Alternative Investment Analyst | Global |
| **CFP** | Certified Financial Planner | Global (country-specific versions) |
| **CMA** | Certified Management Accountant (IMA) | Global (US-based) |
| **CIA** | Certified Internal Auditor | Global (IIA) |
| **ACCA** | Association of Chartered Certified Accountants | Global (UK-based) |

#### Technology & IT

| Exam | Full Name | Regions |
|------|-----------|---------|
| **AWS Certifications** | Solutions Architect, Developer, SysOps, DevOps, etc. | Global |
| **Azure Certifications** | AZ-900, AZ-104, AZ-305, AI-900, DP-900, etc. | Global |
| **GCP Certifications** | Associate Cloud Engineer, Professional Architect, etc. | Global |
| **CompTIA A+** | IT Support Fundamentals | Global |
| **CompTIA Network+** | Networking Fundamentals | Global |
| **CompTIA Security+** | Cybersecurity Fundamentals | Global |
| **CISSP** | Certified Information Systems Security Professional | Global (ISC2) |
| **CCNA** | Cisco Certified Network Associate | Global (Cisco) |
| **CCNP** | Cisco Certified Network Professional | Global (Cisco) |
| **PMP** | Project Management Professional | Global (PMI) |
| **CAPM** | Certified Associate in Project Management | Global (PMI) |
| **PRINCE2** | Projects in Controlled Environments | Global (UK-based, Axelos) |
| **Scrum Master (CSM/PSM)** | Certified/Professional Scrum Master | Global |
| **ITIL** | Information Technology Infrastructure Library | Global |
| **Kubernetes (CKA/CKAD)** | Certified Kubernetes Administrator/Developer | Global (CNCF) |
| **Terraform Associate** | HashiCorp Certified Terraform Associate | Global |

#### Healthcare (International)

| Exam | Full Name | Regions |
|------|-----------|---------|
| **USMLE** | US Medical Licensing Examination | US (taken globally by IMGs) |
| **PLAB** | Professional and Linguistic Assessments Board | UK |
| **AMC** | Australian Medical Council Exam | Australia |
| **MCCQE** | Medical Council of Canada Qualifying Exam | Canada |
| **IFOM** | International Foundations of Medicine | Global (NBME) |

#### Legal (International)

| Exam | Full Name | Regions |
|------|-----------|---------|
| **QLTS/SQE** | Solicitors Qualifying Examination | England/Wales (taken globally) |
| **New York Bar** | New York State Bar Examination | US (popular for international lawyers) |
| **QLTT** | Qualified Lawyers Transfer Test | Ireland |

#### Language Proficiency (Global)

| Exam | Full Name | Language |
|------|-----------|----------|
| **TOEFL** | Test of English as a Foreign Language | English |
| **IELTS** | International English Language Testing System | English |
| **TOEIC** | Test of English for International Communication | English |
| **Cambridge English** | B2 First (FCE), C1 Advanced (CAE), C2 Proficiency (CPE) | English |
| **DELF/DALF** | French proficiency diplomas | French |
| **DELE** | Diplomas de Espanol como Lengua Extranjera | Spanish |
| **TestDaF** | Test Deutsch als Fremdsprache | German |
| **HSK** | Hanyu Shuiping Kaoshi | Chinese |
| **JLPT** | Japanese-Language Proficiency Test | Japanese |
| **TOPIK** | Test of Proficiency in Korean | Korean |
| **CELI/CILS** | Italian proficiency certificates | Italian |
| **CELPE-Bras** | Portuguese proficiency certificate | Portuguese |

---

## 8. Question Engine Design

The Question Engine is the core interactive system that powers M1, M4, M8, and M14. Every question in Witt is rendered as a full-screen, immersive, interactive experience.

### 8.1 Full-Screen Question Layout

Each question occupies the entire screen. The layout adapts based on question type:

**Standard MCQ Layout:**
- Top bar: exam name, question number (e.g., "12 of 30"), timer (if enabled), bookmark icon, flag-for-review icon
- Question body: full question text with proper rendering (LaTeX for math, syntax highlighting for code, passage panel for reading comprehension)
- Answer options: large tap targets (A, B, C, D) with clear labels. Selected option highlighted in blue.
- Bottom bar: "Previous" and "Next" navigation, "Submit Answer" button
- After submission: answer locks, correct/wrong feedback appears, explanation panel slides up from bottom

**Passage-Based Layout (SAT Reading, GRE Verbal, etc.):**
- Split-screen: passage on left (scrollable), question + options on right
- On mobile: swipeable tabs between passage and question
- Line numbers in passage for reference questions

**Grid-In / Numeric Entry (SAT Math, GRE Quant):**
- Numeric keypad replaces answer options
- Input field with format validation
- Fraction entry support

**Essay / Short Answer (GRE AWA, AP Essays):**
- Full-screen text editor with word count
- Timer prominently displayed
- Auto-save every 30 seconds
- AI grading after submission (Claude API)

### 8.2 Audio Feedback System

| Event | Sound | Duration |
|-------|-------|----------|
| **Correct Answer** | Positive chime (ascending tone) | ~0.5s |
| **Wrong Answer** | Gentle buzz (low tone) | ~0.5s |
| **Streak (3+ correct)** | Celebratory jingle | ~1.0s |
| **Time Warning (30s left)** | Soft tick | ~0.3s |
| **Time Up** | Alert tone | ~1.0s |
| **Level Up / Badge Earned** | Achievement fanfare | ~1.5s |
| **Boss Defeated (M14)** | Victory music | ~2.0s |

All sounds are optional — users can mute in settings. Haptic feedback accompanies sounds on supported devices.

### 8.3 Adaptive Question Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Student     │     │  Adaptive   │     │  Question   │
│  answers Q   │────>│  Engine     │────>│  Selector   │
└─────────────┘     │             │     │             │
                    │ Update IRT  │     │ Pick next Q │
                    │ proficiency │     │ based on    │
                    │ per topic   │     │ proficiency │
                    └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
    ┌─────┴─────┐       ┌────┴──────┐
    │ Free User │       │ Paid User │
    │ Select    │       │ Generate  │
    │ from pre- │       │ via Claude│
    │ generated │       │ API       │
    │ pool      │       │           │
    └───────────┘       └───────────┘
```

### 8.4 Question Data Model

```dart
class Question {
  final String id;
  final String examId;
  final String sectionId;
  final String topic;
  final QuestionType type; // mcq, trueFalse, fillBlank, shortAnswer, essay, gridIn, matching
  final String questionText; // Supports markdown + LaTeX
  final String? passageText; // For passage-based questions
  final List<String>? options; // For MCQ
  final String correctAnswer;
  final String explanation; // Detailed step-by-step
  final int difficulty; // 1-5
  final int estimatedTimeSeconds;
  final bool isPreGenerated; // true = free tier, false = AI-generated
  final Map<String, dynamic>? metadata; // Exam-specific data
}

class QuestionAttempt {
  final String questionId;
  final String userId;
  final String? selectedAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final bool isBookmarked;
  final bool isSavedForLater;
}
```

### 8.5 Exam-Specific Question Style Examples

| Exam | Question Style | Key Characteristics |
|------|---------------|---------------------|
| **SAT Math** | MCQ + Grid-In | 4 options, no penalty for guessing, calculator allowed on Section 2 |
| **SAT Reading** | Passage-based MCQ | Long passages with line references, evidence-based questions |
| **GRE Quant** | Quantitative Comparison + MCQ + Numeric Entry | Compare Quantity A vs B format unique to GRE |
| **GRE Verbal** | Text Completion + Sentence Equivalence + Reading | 1-3 blank fill-ins, select 2 synonymous answers |
| **GMAT** | Data Sufficiency + Problem Solving | Unique "is this sufficient?" format |
| **LSAT** | Logical Reasoning + Logic Games + Reading | Analytical reasoning with game boards |
| **MCAT** | Passage-based science MCQ | Dense scientific passages, 4 options |
| **WAEC** | Objective (MCQ) + Theory | 4 options A-D, separate theory section |
| **JAMB UTME** | CBT-style MCQ | 4 options, 180 questions in 120 minutes, no negative marking |
| **Gaokao Math** | Fill-in + Proof-based | Numeric answers + multi-step proofs |
| **JEE Advanced** | MCQ (single + multi-correct) + Numeric | Negative marking, partial marking for multi-correct |
| **NEET** | MCQ | 4 options, -1 for wrong answer, +4 for correct |
| **CAT** | MCQ + TITA (non-MCQ) | Type-in-the-answer for some questions |
| **A-Levels** | Structured + Essay | Multi-part questions with marks per part |
| **IB** | Paper 1 (MCQ) + Paper 2 (structured) + Paper 3 (essay) | Varies by subject |

---

## 9. Monetization & Pricing

Witt uses a **two-tier pricing model**: a General App subscription that unlocks all app features, and separate Exam-Specific subscriptions for individual standardized test prep. Every user must be on one of the General tiers (including Free). Exam access is priced independently.

### 9.1 Monetization Stack

Witt uses **Subrail** (internal platform, replaces RevenueCat) for all in-app purchase management, subscription lifecycle, receipt validation, paywall experimentation, and analytics.

---

### 9.2 Tier 1: General App Pricing

This tier controls access to all app features **except** exam-specific question banks and AI-generated exam content. Every user is on one of these plans.

#### Free Plan (Always Free, Forever)

Students who want to use the app for free indefinitely. Very limited but functional.

| Feature | Free Limit |
|---------|-----------|
| **Sage AI (Chat Bot)** | 10 messages/day (Groq AI), 500 char input, ~500 word output, Chat + Explain modes only |
| **Sage Dictation** | Not available |
| **Flashcards** | Create up to 5 decks, 50 cards per deck. Study unlimited. No AI generation. |
| **Note-Taking** | Up to 10 notes, 2,000 words per note |
| **Vocabulary Builder** | 3 word lists, 25 words per list. Word of the Day only. |
| **AI Homework Helper** | 3 scans/day, text-only explanations (no step-by-step) |
| **AI Quiz Generator** | 1 quiz/day, max 10 questions per quiz |
| **Lecture Capture** | Record up to 5 minutes. No AI summarization. |
| **Mock Tests** | 1 free mock test per exam (pre-generated, not AI) |
| **Brain Challenges** | Daily challenge only (1/day) |
| **Educational Games** | 3 games/day, single-player only. No multiplayer. |
| **Study Planner** | Basic planner, no AI-generated plans |
| **Progress Dashboard** | Basic stats only (questions answered, streak). No trends, no predicted scores. |
| **Community / Social** | Read-only feed. Join up to 2 study groups. 1 forum post/day. |
| **Collaborative Features** | Not available |
| **Streak Freeze** | Not available |
| **Ads** | Banner ads on Home tab and Learn tab (non-intrusive, bottom of screen) |
| **Offline Content** | 1 content pack download at a time |
| **Cross-Device Sync** | Not available (local only unless authenticated) |

#### Premium Monthly — $9.99/mo

Full access to all app features. No limits on any module.

#### Premium Yearly — $59.99/yr ($5.00/mo)

Same as Premium Monthly. 50% savings. Billed annually.

#### Premium Feature Access (Monthly & Yearly)

| Feature | Premium Access |
|---------|--------------|
| **Sage AI (Chat Bot)** | Unlimited messages (OpenAI GPT-4o), 4,000 char input, ~2,000 word output, all modes |
| **Sage Dictation** | Unlimited (Whisper API) |
| **Flashcards** | Unlimited decks, unlimited cards, AI-generated decks via Sage |
| **Note-Taking** | Unlimited notes, unlimited length |
| **Vocabulary Builder** | Unlimited word lists, AI-curated lists, spaced repetition |
| **AI Homework Helper** | Unlimited scans, step-by-step solutions with diagrams |
| **AI Quiz Generator** | Unlimited quizzes, unlimited questions |
| **Lecture Capture** | Unlimited recording length, full AI summarization + key point extraction |
| **Mock Tests** | Unlimited AI-generated mock tests for all exams (requires exam subscription or free questions) |
| **Brain Challenges** | Unlimited challenges, all categories |
| **Educational Games** | Unlimited games, multiplayer access, all 9 game types |
| **Study Planner** | AI-generated study plans, adaptive scheduling |
| **Progress Dashboard** | Full analytics: trends, predicted scores, comparative stats, mastery heatmap |
| **Community / Social** | Full access: unlimited posts, groups, deck marketplace, friend challenges |
| **Collaborative Features** | Real-time note editing, collaborative decks |
| **Streak Freeze** | 1 per week |
| **Ads** | Ad-free experience |
| **Offline Content** | Unlimited content pack downloads |
| **Cross-Device Sync** | Full sync across all devices |
| **Priority Support** | In-app chat support with faster response times |

---

### 9.3 Tier 2: Exam-Specific Pricing

Each standardized test/exam has its own independent subscription. This is **separate** from the General App subscription. A user can be on the Free general plan but subscribe to specific exams, or be Premium and still need to subscribe to exams for AI-generated questions.

**Important:** General Premium does NOT include exam question banks. Premium unlocks the app features (Sage, tools, analytics, etc.), while Exam subscriptions unlock the exam-specific AI-generated questions and content.

#### Free Exam Access (All Exams)

Every exam includes **10-15 pre-generated questions** with full answers and explanations that anyone can access for free. This is a permanent, non-expiring sample:
- 10-15 curated questions per exam (hand-picked to represent the exam's style)
- Full detailed explanations for each question
- Interactive question UI (sounds, bookmarking, etc.)
- Once all free questions are answered, no new questions are generated
- "Upgrade to unlock unlimited questions" prompt after completing free set

#### Paid Exam Subscriptions

Paid exam users get **unlimited AI-generated questions** (via OpenAI, regardless of general plan tier) for their subscribed exams. Questions are generated on-demand, adaptive to the user's skill level, and mimic the exact style of the real exam.

**Exam Pricing Tiers (USD Base):**

##### Tier 1 — Basic Exams: $1.99/wk | $4.99/mo | $29.99/yr

| Region | Exams |
|--------|-------|
| **Africa** | BECE (Ghana), KCPE (Kenya), Common Entrance (Nigeria), FSLC (Cameroon), Grade 7 Exam (Zambia), PSLE (Tanzania), Standard 8 (Malawi) |
| **India** | NTSE, Navodaya (JNV), KVPY |
| **China** | Zhongkao |
| **Latin America** | ENLACE (Mexico), Prova Brasil, SIMCE (Chile), Saber (Colombia) |

##### Tier 2 — Standard High School & Undergraduate Exams: $2.99/wk | $7.99/mo | $49.99/yr

| Region | Exams |
|--------|-------|
| **US** | SAT, ACT, PSAT/NMSQT, AP Exams (all subjects), CLEP, HiSET/GED, SHSAT/SSAT/ISEE |
| **UK** | GCSE, A-Levels, AS-Levels, 11+ Entrance, Scottish Highers |
| **Europe** | Abitur (Germany), Baccalaureat (France), Selectividad (Spain), Maturita (Italy), VWO (Netherlands), Studentereksamen (Denmark), Ylioppilastutkinto (Finland), Matura (Poland), Leaving Cert (Ireland) |
| **Africa** | WASSCE/WAEC, NECO, JAMB UTME, KCSE (Kenya), Matric/NSC (South Africa), BECE Senior (Ghana), GCE O/A Level (Cameroon), NECTA (Tanzania), MANEB (Malawi), ZIMSEC (Zimbabwe), UCE/UACE (Uganda) |
| **India** | CBSE Board (10th & 12th), ICSE/ISC, State Boards, CUET |
| **China** | Gaokao |
| **Japan** | Common Test (Kyotsu Test), High School Entrance |
| **Latin America** | ENEM (Brazil), PSU (Chile), ICFES Saber 11 (Colombia), EXANI-II (Mexico), PAA (Puerto Rico) |

##### Tier 3 — Graduate & Professional Entrance Exams: $3.99/wk | $11.99/mo | $79.99/yr

| Region | Exams |
|--------|-------|
| **US/Global** | GRE, GMAT, LSAT, DAT, OAT, PCAT |
| **UK** | LNAT, BMAT, UCAT, MAT, STEP, PAT, TSA |
| **India** | JEE Main, JEE Advanced, NEET, CAT, GATE, CLAT, NIFT, NID |
| **Japan** | EJU, University-specific entrance exams |

##### Tier 4 — Medical, Legal & Elite Professional Exams: $4.99/wk | $14.99/mo | $99.99/yr

| Region | Exams |
|--------|-------|
| **US** | MCAT, USMLE (Step 1, 2, 3), NCLEX-RN, NCLEX-PN, Bar Exam (MBE/MEE/MPT) |
| **UK** | MRCP, MRCS, PLAB, SQE |
| **Global** | COMLEX, NBDE |

##### Tier 5 — Global Professional Certifications: $4.99/wk | $14.99/mo | $99.99/yr

| Category | Exams |
|----------|-------|
| **Finance** | CFA (Levels I-III), CPA, ACCA, FRM, CAIA, CFP |
| **Technology** | AWS (Solutions Architect, Developer, SysOps), Azure (AZ-900, AZ-104, AZ-305), GCP (Associate Cloud Engineer, Professional), CompTIA (A+, Network+, Security+), CISSP, PMP |
| **Actuarial** | SOA Exams (P, FM, IFM, LTAM, STAM, SRM, PA) |

##### Exam Bundle Discounts

| Bundle | Price | Savings |
|--------|-------|---------|
| **3-Exam Bundle** | 20% off combined monthly/yearly price | Mix any exams from any tier |
| **5-Exam Bundle** | 30% off combined monthly/yearly price | Mix any exams from any tier |
| **Regional Bundle** (all exams in one country) | $19.99/mo or $149.99/yr | Best for students taking multiple national exams |
| **All-Access Exam Pass** | $29.99/mo or $199.99/yr | Every exam, every region, unlimited |

---

### 9.4 Free User Limitations — Complete Summary

This is the definitive reference for what free users can and cannot do across the entire app.

| Area | What Free Users GET | What Free Users DON'T GET |
|------|--------------------|-----------------------------|
| **Exams** | 10-15 free questions per exam (all exams) | AI-generated questions, unlimited practice |
| **Sage AI** | 10 msgs/day, Groq AI (Llama), Chat + Explain only, 500 char input, ~500 word output | OpenAI GPT-4o, dictation, all modes, unlimited messages |
| **Flashcards** | 5 decks, 50 cards/deck, manual creation | AI-generated decks, unlimited decks/cards |
| **Notes** | 10 notes, 2,000 words each | Unlimited notes, unlimited length |
| **Vocabulary** | 3 lists, 25 words each, Word of the Day | Unlimited lists, AI-curated, spaced repetition |
| **Homework Helper** | 3 scans/day, basic explanations (Groq AI / Llama) | Unlimited scans, step-by-step with diagrams (OpenAI GPT-4o) |
| **Quiz Generator** | 1 quiz/day, max 5 questions (Groq AI / Llama) | Unlimited quizzes, unlimited questions (OpenAI GPT-4o) |
| **Lecture Capture** | 5-minute recordings, no AI summary (Groq AI unavailable for free lecture summarization) | Unlimited recording, full AI summarization (OpenAI GPT-4o) |
| **Mock Tests** | 1 free mock per exam (pre-generated) | Unlimited AI-generated mocks |
| **Games** | 3 games/day, single-player only | Unlimited games, multiplayer |
| **Brain Challenges** | Daily challenge only | Unlimited challenges, all categories |
| **Study Planner** | Basic manual planner | AI-generated adaptive plans |
| **Analytics** | Basic stats (streak, questions answered) | Trends, predicted scores, mastery heatmap |
| **Social** | Read-only feed, 2 groups, 1 post/day | Full community access, unlimited groups/posts |
| **Collaboration** | Not available | Real-time editing, collaborative decks |
| **Streak Freeze** | Not available | 1 per week |
| **Ads** | Banner ads on Home + Learn tabs | Ad-free |
| **Offline** | 1 content pack at a time | Unlimited downloads |
| **Cross-Device Sync** | Not available | Full sync |

---

### 9.5 Currency & Pricing Strategy

#### GeoIP Currency Detection

- **MaxMind GeoIP2** database determines user's country on first app launch
- Country maps to home currency
- Currency stored in user profile and used for all pricing displays
- User can manually override currency in settings

#### Base Currency

- **USD is the base currency** for all internal pricing and conversions
- All prices (general + exam) are set in USD first
- Converted to local currency using daily exchange rates cached in `currency_rates` table

#### Price Parity Rules

| Currency | Parity Rule | Example |
|----------|-------------|---------|
| **USD** | Base | $9.99 |
| **EUR** | 1 USD = 1 EUR | 9.99 EUR |
| **GBP** | 1 USD = 1 GBP | 9.99 GBP |
| **All others** | Market exchange rate from USD | Converted at daily rate |

This means a $9.99 subscription costs 9.99 EUR and 9.99 GBP regardless of the actual exchange rate — providing price parity for the three major Western currencies.

#### Exchange Rate Management

```dart
class PricingEngine {
  // Fetch and cache exchange rates daily via Supabase Edge Function
  Future<Map<String, double>> fetchExchangeRates();
  
  // Convert USD price to user's local currency
  double convertPrice(double usdPrice, String targetCurrency) {
    if (targetCurrency == 'USD') return usdPrice;
    if (targetCurrency == 'EUR') return usdPrice; // 1:1 parity
    if (targetCurrency == 'GBP') return usdPrice; // 1:1 parity
    return usdPrice * getExchangeRate(targetCurrency);
  }
  
  // Format price for display with local currency symbol
  String formatPrice(double amount, String currencyCode);
}
```

---

### 9.6 Subrail Integration

```dart
class WittMonetization {
  final SubrailSDK subrail;
  final LocalDb localDb;

  // ─────────────────────────────────────────
  // GENERAL APP TIER
  // ─────────────────────────────────────────

  bool get isFreeUser => !isPremium;
  bool get isPremium =>
      subrail.customerInfo.entitlements['premium']?.isActive ?? false;

  PlanType get currentPlan {
    if (isPremium) {
      final e = subrail.customerInfo.entitlements['premium']!;
      return e.periodType == PeriodType.monthly
          ? PlanType.premiumMonthly
          : PlanType.premiumYearly;
    }
    return PlanType.free;
  }

  // ─────────────────────────────────────────
  // AI PROVIDER ROUTING
  // General features: Groq (free) / OpenAI (paid)
  // Exam generation: always Claude (via Supabase Edge Fn)
  // ─────────────────────────────────────────

  /// Returns the AI provider to use for general (non-exam) features.
  AIProvider get generalAIProvider =>
      isPremium ? AIProvider.openAI : AIProvider.groq;

  /// Exam question generation always uses Claude regardless of plan.
  AIProvider get examAIProvider => AIProvider.claude;

  /// Whether the current user can generate questions on-demand for an exam.
  /// Free users only get the static pre-generated pool (10-15 Qs).
  bool canGenerateExamQuestions(String examId) =>
      hasExamSubscription(examId) || hasAllAccessExamPass;

  // ─────────────────────────────────────────
  // EXAM-SPECIFIC TIER
  // Exam access is INDEPENDENT of general plan.
  // A user must have an active general plan (any tier incl. Free)
  // AND an active exam subscription to get AI-generated exam Qs.
  // Free exam questions (10-15) are always available to everyone.
  // ─────────────────────────────────────────

  bool hasExamSubscription(String examId) =>
      subrail.customerInfo.entitlements['exam_$examId']?.isActive ?? false;

  bool get hasAllAccessExamPass =>
      subrail.customerInfo.entitlements['exam_all_access']?.isActive ?? false;

  /// Guard: user must have an active general plan (Free counts) to use the app at all.
  /// This is always true for any authenticated user — Free plan is always active.
  bool get hasActiveGeneralPlan => true; // Free plan is always active post-onboarding

  /// Whether user can access the free exam question pool (always true for all users).
  bool canAccessFreeExamQuestions(String examId) => true;

  /// Whether user has exhausted the free question pool for an exam.
  bool hasUsedFreeQuestions(String examId) =>
      localDb.getFreeQuestionsAnswered(examId) >= 15;

  /// Full access check: can user generate unlimited AI exam questions?
  /// Requires: active general plan (any tier) + active exam subscription.
  bool canAccessUnlimitedExamQuestions(String examId) {
    return hasActiveGeneralPlan &&
        (hasAllAccessExamPass || hasExamSubscription(examId));
  }

  // ─────────────────────────────────────────
  // PAYWALLS
  // ─────────────────────────────────────────

  Future<void> showGeneralPaywall() =>
      subrail.presentPaywall('general_pricing');

  Future<void> showExamPaywall(String examId) =>
      subrail.presentPaywall('exam_$examId');

  Future<void> restorePurchases() => subrail.restorePurchases();
}

enum AIProvider { groq, openAI, claude }
enum PlanType { free, premiumMonthly, premiumYearly }
```

**Entitlement rules summary:**

| Scenario | General Plan | Exam Sub | Can use app? | Gets free exam Qs? | Gets unlimited exam Qs? | General AI |
|----------|-------------|----------|-------------|-------------------|------------------------|------------|
| New user (Free) | Free ✓ | None | Yes | Yes (10-15) | No | Groq |
| Free + Exam sub | Free ✓ | Active ✓ | Yes | Yes | Yes (Claude) | Groq |
| Premium only | Premium ✓ | None | Yes | Yes (10-15) | No | OpenAI |
| Premium + Exam sub | Premium ✓ | Active ✓ | Yes | Yes | Yes (Claude) | OpenAI |
| Premium + All-Access | Premium ✓ | All-Access ✓ | Yes | Yes | Yes (all exams, Claude) | OpenAI |

### 9.7 Store-Specific Implementation

| Store | Implementation | Notes |
|-------|---------------|-------|
| **App Store** | StoreKit 2 via Subrail iOS SDK | Subscriptions (general + exam) + auto-renewable |
| **Google Play** | Play Billing via Subrail Android SDK | Subscriptions (general + exam) + auto-renewable |
| **Huawei AppGallery** | Huawei IAP Kit via Subrail Huawei SDK | Subscriptions + auto-renewable |
| **Microsoft Store** | Microsoft Store IAP via Subrail Windows SDK | Subscriptions + durable add-ons |

### 9.8 Pricing Display Rules

- All prices shown in user's local currency (GeoIP-detected or manually set)
- Paywall screens always show: Free plan benefits, Monthly price, Yearly price with savings badge ("Save 50%")
- Exam paywall shows: Free questions remaining (e.g., "3 of 15 free questions used"), Weekly/Monthly/Yearly options
- "Restore Purchases" link visible on all paywall screens
- Trial periods: 7-day free trial for Premium Monthly (first-time subscribers only)
- Exam subscriptions: No trial, but 10-15 free questions serve as the try-before-you-buy experience

---

## 10. Realtime Translation System

### 10.1 Overview

Witt supports real-time translation of all content — questions, explanations, flashcards, notes, and UI — in both online and offline modes. This is critical for non-English-speaking students worldwide.

### 10.2 Online Translation

- **Provider**: Google Cloud Translation API (primary) / DeepL API (fallback for European languages)
- **Flow**: Content is translated on-demand via Supabase Edge Function. Translations are cached in the database to avoid repeated API calls.
- **Supported Languages**: 50+ languages including all major languages in target markets
- **Context-Aware**: Educational content is translated with subject-specific terminology preserved (e.g., mathematical terms, scientific nomenclature)
- **UI Translation**: All app UI strings are pre-translated and bundled with the app via Flutter's `intl` package

### 10.3 Offline Translation

- **Technology**: On-device ML models using TensorFlow Lite / Google ML Kit
- **Language Packs**: Downloadable compressed model files (~30-80MB per language pair)
- **Pre-Downloaded**: Users select their preferred languages in settings and download packs over Wi-Fi
- **Quality**: Slightly lower than online translation but sufficient for study content
- **Supported Pairs**: Major language pairs (English to/from: Spanish, French, German, Portuguese, Chinese, Japanese, Korean, Hindi, Arabic, Swahili, Yoruba, Hausa, and more)

### 10.4 Translation Caching Strategy

```dart
class TranslationService {
  // 1. Check local cache (SQLite)
  // 2. If miss, check Supabase cache
  // 3. If miss, call translation API and cache result
  // 4. If offline, use on-device model
  Future<String> translate(String text, String fromLang, String toLang) async {
    final cached = await localCache.get(text, fromLang, toLang);
    if (cached != null) return cached;
    
    if (isOnline) {
      final result = await translationAPI.translate(text, fromLang, toLang);
      await localCache.put(text, fromLang, toLang, result);
      return result;
    } else {
      return offlineModel.translate(text, fromLang, toLang);
    }
  }
}
```

---

## 11. Offline Architecture

### 11.1 Design Philosophy

Witt is designed **offline-first** — the app should feel fully functional without internet. All user-generated data (notes, flashcard reviews, question attempts, study progress) is written to local storage first, then synced to the cloud when connectivity is available.

### 11.2 Local Storage Strategy

| Storage | Technology | Data |
|---------|------------|------|
| **Structured Data** | SQLite (sqflite) | Questions, progress, flashcards, bookmarks, attempts |
| **Key-Value / Preferences** | Hive | User settings, auth tokens, cache metadata, sync timestamps |
| **Files** | Device file system | Audio recordings, images, content packs, language models |

### 11.3 Content Pack System

Content packs are downloadable bundles that enable offline access:

| Pack Type | Contents | Approx Size |
|-----------|----------|-------------|
| **Exam Pack (Free)** | 10-15 pre-generated questions + explanations | 1-5 MB |
| **Exam Pack (Premium)** | Full question bank (500+ questions) | 10-50 MB |
| **Dictionary Pack** | Full dictionary database for a language | ~200 MB |
| **Language Pack** | Offline translation model for a language pair | 30-80 MB |
| **Vocabulary Pack** | Subject-specific word lists + audio | 5-20 MB |
| **Flashcard Pack** | Community/official deck bundles | 1-10 MB |

### 11.4 Sync Protocol

1. **Write locally first** — all user actions write to SQLite/Hive immediately
2. **Queue for sync** — changes are added to an outbox table with timestamps
3. **Monitor connectivity** — `connectivity_plus` package detects network changes
4. **Push on connect** — when online, outbox items are pushed to Supabase in order
5. **Pull updates** — after pushing, pull any remote changes since last sync
6. **Resolve conflicts** — server authority for shared data, last-write-wins for personal data
7. **Update sync timestamp** — record the last successful sync time

### 11.5 Storage Management

- Display total offline storage usage in settings
- Per-pack storage breakdown
- "Clear Cache" option (preserves user data, clears cached content)
- "Delete Pack" option per content pack
- Low storage warning when device has < 500MB free
- Wi-Fi only download toggle

---

## 12. Security, Privacy & Compliance

### 12.1 Authentication

| Method | Provider | Use Case |
|--------|----------|----------|
| **Email/Password** | Supabase Auth | Primary sign-up/login |
| **Google OAuth** | Supabase Auth | Social login |
| **Apple Sign-In** | Supabase Auth | Required for iOS |
| **Phone OTP** | Supabase Auth | SMS-based login (important for African/Asian markets) |
| **Anonymous Auth** | Supabase Auth | Try before sign-up |

### 12.2 Data Security

- **Encryption in Transit**: All API calls over HTTPS/TLS 1.3
- **Encryption at Rest**: Supabase encrypts all data at rest (AES-256)
- **Local Encryption**: Sensitive local data (auth tokens, API keys) encrypted via Flutter Secure Storage
- **API Keys**: All AI API keys (Anthropic, OpenAI) are stored server-side in Supabase Edge Functions — never exposed to the client
- **Row-Level Security (RLS)**: Supabase RLS policies ensure users can only access their own data

### 12.3 Privacy Compliance

| Regulation | Scope | Implementation |
|------------|-------|----------------|
| **GDPR** | EU users | Data export, right to deletion, consent management, DPA with Supabase |
| **CCPA** | California users | Same as GDPR |
| **COPPA** | US children under 13 | Parental consent flow, limited data collection for minors |
| **POPIA** | South Africa | Data protection compliance |
| **NDPR** | Nigeria | Nigerian data protection compliance |
| **PDPA** | Various Asian countries | Country-specific data protection |

### 12.4 Content Safety

- AI-generated content is filtered for inappropriate material before display
- Community posts moderated by AI + human review
- Report system for user-generated content
- Age-appropriate content filtering based on user profile

### 12.5 API Security

- All Anthropic/OpenAI API calls routed through Supabase Edge Functions (server-side)
- Rate limiting per user to prevent abuse
- Request validation and sanitization
- Audit logging for all AI API calls

---

## 13. Platform-Specific Notes

### 13.1 iOS (iPhone + iPad)

- **Min Version**: iOS 15+
- **Distribution**: App Store
- **IAP**: StoreKit 2 via Subrail SDK
- **Auth**: Apple Sign-In required (App Store policy)
- **Notifications**: APNs via OneSignal
- **Offline Storage**: App sandbox + shared container for extensions
- **Background Tasks**: `BGTaskScheduler` for background sync and content downloads
- **Widgets**: iOS home screen widgets for daily challenge, streak counter, exam countdown
- **Shortcuts**: Siri Shortcuts for "Start studying [exam]"
- **iPad**: Split-screen multitasking support, keyboard shortcuts, Apple Pencil for note-taking (M7)

### 13.2 macOS

- **Min Version**: macOS 12+
- **Distribution**: Mac App Store + direct download (notarized DMG)
- **IAP**: StoreKit 2 (Mac App Store) or Stripe (direct download)
- **Notifications**: APNs via OneSignal
- **UI Adaptations**: Native menu bar, keyboard shortcuts, larger layouts, multi-window support
- **Desktop Features**: Drag-and-drop file import (lectures, PDFs), system-level notifications, Touch Bar support (legacy Macs)
- **File System**: Full file system access for lecture import/export
- **Note-Taking**: Optimized for keyboard-heavy input, wider editor layout

### 13.3 Android

- **Min Version**: Android 7.0+ (API 24)
- **Distribution**: Google Play Store
- **IAP**: Google Play Billing via Subrail SDK
- **Notifications**: FCM via OneSignal
- **Offline Storage**: Internal storage + scoped storage for media
- **Background Tasks**: WorkManager for background sync
- **Widgets**: Android home screen widgets (daily challenge, streak, countdown)
- **Material You**: Dynamic color theming on Android 12+
- **Tablets**: Responsive layout with multi-pane views

### 13.4 HuaweiOS (HarmonyOS / EMUI)

- **Min Version**: EMUI 10+ / HarmonyOS 2+
- **Distribution**: Huawei AppGallery
- **IAP**: Huawei IAP Kit via Subrail SDK
- **Push Notifications**: Huawei Push Kit via OneSignal
- **Auth**: Huawei ID sign-in support
- **Maps/Location**: Huawei Location Kit for GeoIP (instead of Google Play Services)
- **Key Difference**: No Google Play Services — all GMS dependencies replaced with HMS equivalents
- **HMS Core Integration**:
  - HMS IAP Kit (in-app purchases)
  - HMS Push Kit (notifications)
  - HMS Account Kit (Huawei ID login)
  - HMS ML Kit (on-device translation, OCR)
  - HMS Location Kit (GeoIP)

### 13.5 Windows

- **Min Version**: Windows 10+
- **Distribution**: Microsoft Store + direct download (MSIX installer)
- **IAP**: Microsoft Store IAP via Subrail SDK (Store version) or Stripe (direct download)
- **Notifications**: Windows Toast via OneSignal
- **UI Adaptations**: Windows-native title bar, system tray icon, keyboard-first navigation, resizable windows
- **Desktop Features**: File drag-and-drop, system notifications (Windows Toast), taskbar jump lists
- **Offline Storage**: AppData folder for local database and content packs
- **Installer**: MSIX package for Microsoft Store, standalone MSIX for direct distribution
- **Auto-Update**: Microsoft Store handles updates (Store version), custom update mechanism for direct download

### 13.6 Cross-Platform Considerations

| Feature | iOS | macOS | Android | HuaweiOS | Windows |
|---------|-----|-------|---------|----------|---------|
| **Audio Recording** | AVFoundation | AVFoundation | MediaRecorder | HMS Audio | Windows Audio |
| **Camera (Photo Scan)** | AVFoundation | AVFoundation | CameraX | HMS Camera | Windows Camera |
| **File Picker** | UIDocumentPicker | NSOpenPanel | SAF | HMS File | Windows File Picker |
| **Biometric Auth** | Face ID / Touch ID | Touch ID | Fingerprint / Face | Fingerprint | Windows Hello |
| **Deep Links** | Universal Links | Universal Links | App Links | App Links | Protocol Handler |
| **Background Sync** | BGTaskScheduler | BGTaskScheduler | WorkManager | WorkManager | Background Task |

---

## 14. Appendices

### Appendix A: Flutter Package Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  
  # Routing
  go_router: ^13.x
  
  # Backend
  supabase_flutter: ^2.x
  
  # Networking
  dio: ^5.x
  
  # Local Storage
  sqflite: ^2.x
  hive_flutter: ^1.x
  flutter_secure_storage: ^9.x
  
  # UI
  flutter_math_fork: ^0.7.x
  flutter_highlight: ^0.7.x
  flutter_markdown: ^0.6.x
  cached_network_image: ^3.x
  shimmer: ^3.x
  lottie: ^3.x
  
  # Audio/Video
  record: ^5.x
  just_audio: ^0.9.x
  video_player: ^2.x
  
  # Camera & Image
  camera: ^0.10.x
  image_picker: ^1.x
  
  # Connectivity
  connectivity_plus: ^5.x
  
  # Notifications
  onesignal_flutter: ^5.x
  
  # Analytics
  mixpanel_flutter: ^2.x
  sentry_flutter: ^7.x
  
  # Monetization
  subrail_flutter: ^1.x  # Internal SDK
  
  # Translation
  google_mlkit_translation: ^0.10.x
  
  # Utilities
  intl: ^0.18.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  uuid: ^4.x
  path_provider: ^2.x
  share_plus: ^7.x
  url_launcher: ^6.x
  qr_flutter: ^4.x
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  riverpod_generator: ^2.x
  flutter_lints: ^3.x
  patrol: ^3.x
  integration_test:
    sdk: flutter
```

### Appendix B: Environment Variables

```bash
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...

# AI APIs (server-side only — Supabase Edge Functions)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# Translation
GOOGLE_TRANSLATE_API_KEY=AIza...
DEEPL_API_KEY=...

# GeoIP
MAXMIND_LICENSE_KEY=...

# Push Notifications
ONESIGNAL_APP_ID=...
ONESIGNAL_REST_API_KEY=...

# Analytics
MIXPANEL_TOKEN=...
SENTRY_DSN=https://...@sentry.io/...

# Subrail
SUBRAIL_API_KEY=sk_live_...
SUBRAIL_PROJECT_ID=...

# Exchange Rates
EXCHANGE_RATE_API_KEY=...
```

### Appendix C: Supported Languages (UI + Content)

| Language | Code | UI | Content Translation | Offline Translation |
|----------|------|----|--------------------|---------------------|
| English | en | Yes | N/A (base) | N/A |
| Spanish | es | Yes | Yes | Yes |
| French | fr | Yes | Yes | Yes |
| German | de | Yes | Yes | Yes |
| Portuguese | pt | Yes | Yes | Yes |
| Chinese (Simplified) | zh-CN | Yes | Yes | Yes |
| Chinese (Traditional) | zh-TW | Yes | Yes | Yes |
| Japanese | ja | Yes | Yes | Yes |
| Korean | ko | Yes | Yes | Yes |
| Hindi | hi | Yes | Yes | Yes |
| Arabic | ar | Yes | Yes | Yes |
| Swahili | sw | Yes | Yes | Yes |
| Yoruba | yo | Yes | Yes | Planned |
| Hausa | ha | Yes | Yes | Planned |
| Igbo | ig | Yes | Yes | Planned |
| Amharic | am | Yes | Yes | Planned |
| Zulu | zu | Yes | Yes | Planned |
| Turkish | tr | Yes | Yes | Yes |
| Russian | ru | Yes | Yes | Yes |
| Italian | it | Yes | Yes | Yes |
| Dutch | nl | Yes | Yes | Yes |
| Polish | pl | Yes | Yes | Yes |
| Vietnamese | vi | Yes | Yes | Yes |
| Thai | th | Yes | Yes | Yes |
| Indonesian | id | Yes | Yes | Yes |
| Malay | ms | Yes | Yes | Yes |

### Appendix D: Project Directory Structure

```
witt/
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── macos/                      # macOS platform files
├── windows/                    # Windows platform files
├── huawei/                     # HuaweiOS platform files + HMS config
├── lib/
│   ├── main.dart               # App entry point
│   ├── app/
│   │   ├── app.dart            # MaterialApp configuration
│   │   ├── router.dart         # GoRouter configuration
│   │   └── theme.dart          # App theme (light + dark)
│   ├── core/
│   │   ├── constants/          # App-wide constants
│   │   ├── errors/             # Error handling
│   │   ├── network/            # Dio client, interceptors
│   │   ├── storage/            # SQLite, Hive helpers
│   │   ├── sync/               # Sync engine
│   │   └── utils/              # Shared utilities
│   ├── features/
│   │   ├── auth/               # Authentication (M-Auth)
│   │   ├── test_prep/          # M1: AI-Powered Test Prep
│   │   ├── flashcards/         # M2: Flashcard System
│   │   ├── homework_helper/    # M3: AI Homework Helper
│   │   ├── mock_tests/         # M4: Practice Exams
│   │   ├── brain_challenges/   # M5: Brain & Logic
│   │   ├── vocabulary/         # M6: Vocabulary Builder
│   │   ├── notes/              # M7: Note-Taking
│   │   ├── quiz_generator/     # M8: AI Quiz Generator
│   │   ├── dashboard/          # M9: Progress Dashboard
│   │   ├── community/          # M10: Community & Social
│   │   ├── teacher_parent/     # M11: Teacher & Parent Portal
│   │   ├── offline/            # M12: Offline Mode / Downloads
│   │   ├── lectures/           # M13: Lecture Capture
│   │   ├── games/              # M14: Educational Games
│   │   └── planner/            # M15: Study & Exam Planner
│   ├── models/                 # Shared data models (freezed)
│   ├── providers/              # Riverpod providers
│   ├── services/
│   │   ├── ai/                 # Anthropic + OpenAI clients
│   │   ├── subrail/            # Subrail SDK wrapper
│   │   ├── translation/        # Translation service
│   │   ├── audio/              # Audio recording/playback
│   │   └── geoip/              # GeoIP + currency
│   └── widgets/                # Shared UI components
├── assets/
│   ├── sounds/                 # Audio feedback files
│   ├── images/                 # App images and icons
│   ├── fonts/                  # Custom fonts
│   └── l10n/                   # Localization files (ARB)
├── test/                       # Unit tests
├── integration_test/           # Integration tests
├── docs/                       # Documentation
│   ├── main.md                 # This document
│   └── brainstorming.md        # Initial brainstorming
├── builds/                     # Build outputs
├── pubspec.yaml                # Flutter dependencies
├── melos.yaml                  # Monorepo configuration
└── README.md                   # Project README
```

---

**Document Status:** Complete  
**Last Updated:** February 2026  
**Next Steps:** Database schema design, UI/UX wireframes, Supabase project setup
