# Witt — ML Kit-Only Translation Plan

## Decision

Witt now uses **Google ML Kit Translation only**.

- No LibreTranslate
- No Argos
- No VPS translation server
- No translation API keys

This keeps translation fully on-device, faster, and simpler to maintain.

---

## Why ML Kit Only

1. ML Kit already covers the product language requirements.
2. On-device translation works offline after model download.
3. Removes server/network dependency and infra overhead.
4. Lower latency and better UX for realtime translation.

---

## Architecture

```
Flutter App
  ├── localeProvider (selected app language)
  ├── onboardingProvider.language (persisted onboarding choice)
  ├── TranslationNotifier (Riverpod)
  │    ├── reads localeProvider for default target language
  │    ├── debounced realtime translation updates
  │    └── stores history in Hive
  └── MlKitTranslateClient
       ├── ensures source/target models are downloaded
       └── runs OnDeviceTranslator translateText()
```

---

## Current Behavior (Implemented)

1. Language changes in onboarding apply **instantly** to app locale.
2. Continue on language screen moves to wizard step 1 (no splash loop).
3. Translation target language follows selected app language when supported.
4. Translation updates near-realtime as user types (debounced).
5. Translation runs on-device via ML Kit and is marked as offline.

---

## Supported App Translation Languages (Current In-App Set)

`en, fr, es, ar, zh, hi, pt, it, nl, ru, pl, tr, sw, bn, id, vi, de, ja, ko`

The language picker may include locale variants (e.g. `en-GB`, `zh-CN`, `zh-TW`),
which are normalized to their base language code for locale/translation routing.

---

## Environment Variables

No translation-specific environment variables are required anymore.

Removed from config/docs:

- `LIBRETRANSLATE_URL`
- `LIBRETRANSLATE_API_KEY`

---

## Next Enhancements

1. Expand supported language list to the full ML Kit set (59).
2. Add explicit model management UI (download/delete by language).
3. Add inline translation widgets to exam, Sage, and social surfaces.
4. Add metrics for model download latency and translation latency.
