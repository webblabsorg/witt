# Phase 0 — Verification Checklist

Use this checklist to confirm all `done when` criteria from `phases.md` are met before closing Phase 0.

---

## Session 0.1 — Monorepo & Flutter Project

- [ ] `melos bootstrap` completes with no errors
- [ ] App launches on iOS simulator (blank 5-tab scaffold visible)
- [ ] App launches on Android emulator (blank 5-tab scaffold visible)
- [ ] `flutter analyze` reports no issues
- [ ] `melos test` passes all tests

---

## Session 0.2 — Supabase Database Schema

- [ ] All 14 migrations applied (verify: Supabase Dashboard → Database → Migrations)
- [ ] RLS enabled on all 30+ tables (verify: Supabase Dashboard → Database → Tables)
- [ ] Seed data queryable: `select name, slug from public.exams;` returns 5 rows (SAT, GRE, WAEC, JAMB, IELTS)
- [ ] Storage buckets exist: `avatars`, `audio`, `images`, `exports`, `content-packs`

### Auth Providers (manual dashboard steps — required before closing)

Go to: **Supabase Dashboard → Authentication → Providers**

- [ ] **Email/Password** — enabled (on by default)
- [ ] **Google OAuth** — enabled; add `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` from [Google Cloud Console](https://console.cloud.google.com)
- [ ] **Apple OAuth** — enabled; add Apple credentials from [Apple Developer Portal](https://developer.apple.com)
- [ ] **Phone OTP** — enabled; configure Twilio or MessageBird credentials in Supabase dashboard
- [ ] **Anonymous** — enabled via toggle in Supabase Dashboard → Authentication → Providers → Anonymous

---

## Session 0.3 — CI/CD, Error Tracking & Analytics

### GitHub Actions CI

- [ ] Push to `main` triggers CI pipeline (verify: GitHub → Actions tab)
- [ ] Lint job passes
- [ ] Test job passes
- [ ] Android build job produces APK artifact
- [ ] iOS build job completes (no-codesign)

### Sentry

- [ ] Add real `SENTRY_DSN` to `.env.dev` (get from [sentry.io](https://sentry.io) → Project → Settings → Client Keys)
- [ ] Run app in debug mode and trigger a test crash:
  ```dart
  // Paste temporarily in any screen's initState, then remove:
  await Sentry.captureException(Exception('Phase 0 test crash'));
  ```
- [ ] Confirm event appears in Sentry dashboard within ~30 seconds

### Mixpanel

- [ ] Add real `MIXPANEL_TOKEN` to `.env.dev`
- [ ] Launch app
- [ ] Confirm `app_open` event appears in Mixpanel Live View within ~60 seconds

### OneSignal

- [ ] Create OneSignal app at [onesignal.com](https://onesignal.com) → configure APNs (iOS) + FCM (Android)
- [ ] Add real `ONESIGNAL_APP_ID` to `.env.dev`
- [ ] Launch app on iOS device/simulator — confirm notification permission prompt appears
- [ ] Launch app on Android device/emulator — confirm notification permission prompt appears
- [ ] Send test notification from OneSignal Dashboard → Messages → New Push
- [ ] Confirm notification delivered on iOS
- [ ] Confirm notification delivered on Android

### Codemagic

- [ ] Connect repo at [codemagic.io](https://codemagic.io)
- [ ] Add `witt_secrets` environment variable group with: `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`, Apple signing certs
- [ ] Update `APP_STORE_APP_ID` in `codemagic.yaml` with real App Store app ID (from App Store Connect)
- [ ] Trigger `android-release` workflow manually — confirm AAB artifact produced
- [ ] Trigger `ios-release` workflow manually — confirm IPA artifact produced

---

## Phase 0 Sign-off

All items above checked → Phase 0 is complete. Proceed to Phase 1.
