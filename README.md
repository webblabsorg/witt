# Witt — The AI-Powered Study Companion

> Cross-platform AI-powered education super-app for standardized test prep, adaptive learning, and comprehensive study planning.

## Repository

[https://github.com/webblabsorg/wiit](https://github.com/webblabsorg/wiit)

## Tech Stack

- **Framework:** Flutter 3.x (iOS, macOS, Android, HuaweiOS, Windows)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **AI Providers:** Groq (free), OpenAI (paid), Claude (exam generation)
- **Monetization:** Subrail
- **Push Notifications:** OneSignal (all platforms)
- **Local Storage:** Hive + SQLite
- **CI/CD:** GitHub Actions + Codemagic

## Project Structure

```
witt/
├── apps/
│   └── witt_app/          # Main Flutter application
├── packages/
│   ├── witt_core/         # Core utilities, models, enums
│   ├── witt_ui/           # Design system, theme, widgets
│   ├── witt_api/          # Supabase API client layer
│   ├── witt_ai/           # AI provider routing (Groq/OpenAI/Claude)
│   ├── witt_auth/         # Authentication repository
│   ├── witt_storage/      # Local storage (Hive + SQLite)
│   └── witt_monetization/ # Paywall & entitlement management
├── supabase/
│   ├── config.toml        # Supabase project config
│   ├── migrations/        # Database migration SQL files
│   └── seed/              # Seed data (exam catalog)
├── docs/
│   ├── main.md            # Technical & architectural document
│   └── phases.md          # Implementation plan
├── .github/
│   └── workflows/ci.yml   # GitHub Actions CI pipeline
├── melos.yaml             # Melos monorepo config
└── analysis_options.yaml  # Dart lint rules
```

## Getting Started

### Prerequisites

- Flutter 3.38+ (stable channel)
- Dart 3.10+
- Melos (`dart pub global activate melos`)

### Setup

```bash
# Clone
git clone https://github.com/webblabsorg/wiit.git
cd witt

# Bootstrap monorepo
melos bootstrap

# Run the app
cd apps/witt_app
flutter run
```

### Environment

Copy `.env.example` to `.env.dev`, `.env.staging`, `.env.prod` and fill in your keys:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ONESIGNAL_APP_ID=your-onesignal-app-id
SENTRY_DSN=https://your-sentry-dsn
MIXPANEL_TOKEN=your-mixpanel-token
```

### Melos Commands

```bash
melos bootstrap    # Install all dependencies
melos analyze      # Run dart analyze across all packages
melos test         # Run tests across all packages
melos format       # Check formatting
melos build_runner # Run code generation (freezed, json_serializable)
melos clean        # Clean all packages
```

## Database

30 tables in Supabase PostgreSQL with RLS policies. Migrations in `supabase/migrations/`.

**Catalog Milestone A:** 5 exams seeded (SAT, GRE, WAEC, JAMB, IELTS) with sections and pricing.

## CI/CD

GitHub Actions pipeline: lint → test → build (Android APK + iOS).
Codemagic for release builds (configured separately).

## Documentation

- **`docs/main.md`** — Full technical specification
- **`docs/phases.md`** — Implementation plan with sequential sessions
