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

## Post-Launch Monitoring

### First 24 Hours
- Monitor Sentry for P0 crashes (target: 0 crash-free sessions < 99%)
- Monitor Supabase dashboard: API request volume, DB connections, Edge Function errors
- Monitor OneSignal delivery rates
- Check App Store / Play Console ratings and reviews

### Rollback Plan
- **Flutter app:** Push a hotfix build through stores (expedited review for P0 crashes)
- **Database:** Supabase migrations are additive — rollback by applying a reverse migration
- **Edge Functions:** Redeploy previous version via Supabase dashboard or MCP
- **Feature flags:** Disable problematic features via Supabase remote config table

### Key Dashboards
| Service | URL |
|---------|-----|
| Supabase | https://supabase.com/dashboard/project/ovchpewtnpglnlveblgd |
| Sentry | https://sentry.io (project: witt-app) |
| OneSignal | https://app.onesignal.com |
| Codemagic CI | https://codemagic.io (see `codemagic.yaml`) |

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
