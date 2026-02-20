# Witt — Launch Runbook

## Prerequisites

### Secrets & API Keys

All secrets are stored in Supabase Edge Function environment variables and app `.env` files.
**Never commit secrets to git.**

| Secret | Where set | Used by |
|--------|-----------|---------|
| `SUPABASE_URL` | `.env.prod` | Flutter app |
| `SUPABASE_ANON_KEY` | `.env.prod` | Flutter app |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase dashboard → Edge Functions secrets | `delete-account` Edge Function |
| `ONESIGNAL_REST_API_KEY` | Supabase dashboard → Edge Functions secrets | `send-notification` Edge Function |
| `ONESIGNAL_APP_ID` | `.env.prod` | Flutter app (OneSignal SDK) |
| `SUBRAIL_API_KEY` | `.env.prod` | Flutter app (Subrail SDK) |
| `SENTRY_DSN` | `.env.prod` | Flutter app (Sentry SDK) |
| `ANTHROPIC_API_KEY` | Supabase dashboard → Edge Functions secrets | AI Edge Functions |
| `OPENAI_API_KEY` | Supabase dashboard → Edge Functions secrets | AI Edge Functions |

### Store Accounts

| Store | Account | Console URL |
|-------|---------|-------------|
| App Store (iOS/macOS) | Apple Developer Program | https://appstoreconnect.apple.com |
| Google Play | Google Play Console | https://play.google.com/console |
| Huawei AppGallery | Huawei Developer Account | https://developer.huawei.com/consumer/en/appgallery |
| Microsoft Store | Microsoft Partner Center | https://partner.microsoft.com/dashboard |

---

## Pre-Launch Checklist

### Database
- [ ] Run all migrations on production Supabase project (`ovchpewtnpglnlveblgd`)
- [ ] Verify RLS policies are active on all tables (`select tablename, rowsecurity from pg_tables where schemaname = 'public'`)
- [ ] Confirm `delete_account` and `export_my_data` RPCs exist and are callable
- [ ] Confirm Edge Functions deployed: `delete-account`, `send-notification`, all `ai-*` functions
- [ ] Set all required Edge Function secrets in Supabase dashboard

### App Builds
- [ ] Bump version in `pubspec.yaml` (version: `1.0.0+1`)
- [ ] Run `flutter pub get` and `melos bootstrap` in monorepo root
- [ ] iOS: `flutter build ipa --release --flavor prod --dart-define-from-file=.env.prod`
- [ ] macOS: `flutter build macos --release --dart-define-from-file=.env.prod`
- [ ] Android: `flutter build appbundle --release --flavor prod --dart-define-from-file=.env.prod`
- [ ] Windows: `flutter build windows --release --dart-define-from-file=.env.prod`

### Signing
- [ ] iOS/macOS: Distribution certificate + provisioning profile active in Xcode
- [ ] Android: Keystore configured in `android/key.properties` (not committed)
- [ ] macOS: Notarization via `xcrun notarytool` before DMG distribution

### Testing
- [ ] Run `flutter test` — all tests pass
- [ ] Smoke test on physical device (iOS + Android minimum)
- [ ] Verify deep links: `xcrun simctl openurl booted "witt://learn/exam/sat"`
- [ ] Verify push notification delivery (OneSignal test send)
- [ ] Verify GDPR export returns JSON
- [ ] Verify account deletion removes all data

---

## Store Submission

### App Store (iOS)
1. Open Xcode → Product → Archive
2. Upload to App Store Connect via Xcode Organizer
3. Fill metadata from `docs/store/app-store.md`
4. Submit for review (typical: 24–48h)

### App Store (macOS)
1. Same archive flow, select macOS target
2. Notarize DMG for direct download: `xcrun notarytool submit Witt.dmg --apple-id ... --team-id ...`

### Google Play
1. Upload AAB to Play Console → Production track
2. Fill metadata from `docs/store/google-play.md`
3. Submit for review (typical: 1–3 days)

### Huawei AppGallery
1. Upload APK/AAB to AppGallery Connect
2. Fill metadata from `docs/store/huawei-appgallery.md`
3. Submit for review (typical: 1–5 days)

### Microsoft Store
1. Upload MSIX to Partner Center
2. Fill metadata from `docs/store/microsoft-store.md`
3. Submit for review (typical: 1–3 days)

---

## Store Submission Checklist

### Per-Store Verification (before clicking "Submit")

| Step | iOS | macOS | Android | Huawei | Windows |
|------|-----|-------|---------|--------|---------|
| Binary uploaded | [ ] IPA via Xcode | [ ] Archive via Xcode | [ ] AAB via Play Console | [ ] APK/AAB via AppGallery | [ ] MSIX via Partner Center |
| Metadata filled | [ ] `docs/store/app-store.md` | [ ] same | [ ] `docs/store/google-play.md` | [ ] `docs/store/huawei-appgallery.md` | [ ] `docs/store/microsoft-store.md` |
| Screenshots uploaded | [ ] 6.7" + 5.5" | [ ] 1280×800 | [ ] phone + 7" + 10" | [ ] phone | [ ] 1366×768 |
| Privacy policy URL | [ ] https://witt.app/privacy | [ ] same | [ ] same | [ ] same | [ ] same |
| Age rating filled | [ ] 4+ (COPPA compliant) | [ ] 4+ | [ ] Everyone | [ ] 3+ | [ ] Everyone |
| In-app purchases listed | [ ] Premium Monthly/Yearly | [ ] same | [ ] same | [ ] same | [ ] same |
| Review notes added | [ ] Test account creds | [ ] same | [ ] N/A | [ ] N/A | [ ] N/A |
| Deep links tested | [ ] `xcrun simctl openurl` | [ ] `open witt://` | [ ] `adb shell am start` | [ ] manual | [ ] manual |
| Crash-free on device | [ ] physical iPhone | [ ] physical Mac | [ ] physical Android | [ ] emulator OK | [ ] physical PC |

### Submission Order
1. **iOS** first (longest review: 24–48h)
2. **macOS** simultaneously (same App Store Connect)
3. **Android** (1–3 days review)
4. **Huawei** (1–5 days review)
5. **Windows** (1–3 days review)

---

## Post-Launch Monitoring

### First 24 Hours
- Monitor Sentry for P0 crashes (target: crash-free sessions ≥ 99%)
- Monitor Supabase dashboard: API request volume, DB connections, Edge Function errors
- Monitor OneSignal delivery rates
- Check App Store / Play Console ratings and reviews
- Verify deep links work from production builds on all platforms

### Launch Dashboard Setup

#### Sentry
1. Create project `witt-app` at https://sentry.io
2. Set alert rules:
   - **P0:** Any unhandled exception → Slack #witt-alerts + email
   - **P1:** Error rate > 1% of sessions → Slack #witt-alerts
   - **Performance:** Transaction duration p95 > 3s → Slack #witt-perf
3. Upload source maps / debug symbols from Codemagic build artifacts

#### Supabase
1. Dashboard: https://supabase.com/dashboard/project/ovchpewtnpglnlveblgd
2. Monitor tabs:
   - **API:** Request count, latency p95, error rate
   - **Database:** Active connections (alert if > 80% of pool), query performance
   - **Edge Functions:** Invocation count, error rate, cold start latency
   - **Storage:** Bandwidth usage for content-packs bucket
3. Set up Supabase Log Drains to external logging if needed

#### OneSignal
1. Dashboard: https://app.onesignal.com
2. Verify delivery rate > 95% within first hour of launch
3. Monitor opt-in rate (target: > 60% of active users)

#### Codemagic
1. Dashboard: https://codemagic.io
2. Verify all workflows pass on `main` branch post-merge
3. Set up Slack notifications for build failures

### Key Dashboards
| Service | URL | Alert Channel |
|---------|-----|---------------|
| Supabase | https://supabase.com/dashboard/project/ovchpewtnpglnlveblgd | Slack #witt-alerts |
| Sentry | https://sentry.io (project: witt-app) | Slack #witt-alerts + email |
| OneSignal | https://app.onesignal.com | Slack #witt-alerts |
| Codemagic CI | https://codemagic.io (see `codemagic.yaml`) | Slack #witt-ci |
| App Store Connect | https://appstoreconnect.apple.com | Email |
| Google Play Console | https://play.google.com/console | Email |

### Rollback Plan
- **Flutter app:** Push a hotfix build through stores (expedited review for P0 crashes)
- **Database:** Supabase migrations are additive — rollback by applying a reverse migration
- **Edge Functions:** Redeploy previous version via Supabase dashboard or MCP
- **Feature flags:** Disable problematic features via Supabase remote config table

---

## Codemagic CI/CD

Builds are configured in `codemagic.yaml` at the repo root.

```bash
# Trigger a manual build
# Push to main → Codemagic auto-builds all workflows
git push origin main
```

Environment variables required in Codemagic:
- `CM_KEYSTORE` (Android keystore, base64)
- `CM_KEYSTORE_PASSWORD`
- `CM_KEY_ALIAS`
- `CM_KEY_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

---

## Operational Notes

- **Anonymous auth:** Users can try the app without signing up. Anonymous sessions are converted to full accounts on sign-up.
- **COPPA:** Users selecting "Middle School" are asked for birth year. Under-13 users require parental consent before proceeding.
- **Rate limits:** Sage AI is rate-limited per user (10 messages/day free, unlimited premium). Limits enforced server-side via `sage_usage` table.
- **Content packs:** Offline content packs are served from Supabase Storage. Ensure storage bucket `content-packs` is public-read.
- **RLS:** All tables have RLS enabled. Security advisor should show 0 lints before launch.
