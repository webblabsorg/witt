# Witt — Free Translation Stack Implementation Plan

## Overview

100% free, zero-per-call translation using two complementary engines:

| Engine | Coverage | Platform | Mode |
|--------|----------|----------|------|
| **Google ML Kit Translation** | 59 languages | iOS + Android (Flutter) | On-device (offline after download) |
| **LibreTranslate / Argos** | 30+ languages | All (via VPS REST API) | Self-hosted server |

**Strategy:** ML Kit is the primary engine for mobile (on-device, fast, offline). LibreTranslate on your VPS is the fallback/web engine for languages ML Kit doesn't cover and for any web surface.

---

## Language Coverage

### ML Kit supported languages (59)
Afrikaans, Albanian, Arabic, Belarusian, Bengali, Bulgarian, Catalan, Chinese (Simplified), Chinese (Traditional), Croatian, Czech, Danish, Dutch, English, Esperanto, Estonian, Finnish, French, Galician, Georgian, German, Greek, Gujarati, Haitian Creole, Hebrew, Hindi, Hungarian, Icelandic, Indonesian, Irish, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Macedonian, Malay, Maltese, Marathi, Norwegian, Persian, Polish, Portuguese, Romanian, Russian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tagalog, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese, Welsh

### LibreTranslate / Argos additional languages
Arabic, Azerbaijani, Catalan, Chinese, Czech, Danish, Dutch, English, Esperanto, Finnish, French, German, Greek, Hebrew, Hindi, Hungarian, Indonesian, Irish, Italian, Japanese, Korean, Persian, Polish, Portuguese, Russian, Slovak, Spanish, Swedish, Turkish, Ukrainian

**Combined unique coverage: ~65+ languages**

---

## Architecture

```
Flutter App
    │
    ├── TranslationService (Dart)
    │       ├── ML Kit (primary, on-device)
    │       │       └── google_mlkit_translation package
    │       └── LibreTranslate (fallback, via HTTP)
    │               └── dio → VPS REST API
    │
    └── Language model cache (Hive)
            └── tracks downloaded ML Kit models
```

**Routing logic:**
1. If target language is in ML Kit's 59 → use ML Kit (offline, instant)
2. If not in ML Kit → call LibreTranslate VPS API
3. If VPS unreachable → return error with graceful UI fallback

---

## Session Plan

---

### Session L1 — VPS Setup: LibreTranslate

**Goal:** LibreTranslate running on your VPS, accessible via HTTPS.

**Steps (run on VPS via SSH):**
```bash
# 1. Install Python + pip
sudo apt update && sudo apt install -y python3 python3-pip git

# 2. Install LibreTranslate
pip3 install libretranslate

# 3. Install all Argos language models
libretranslate --install-files

# 4. Create systemd service for auto-start
sudo tee /etc/systemd/system/libretranslate.service > /dev/null << 'EOF'
[Unit]
Description=LibreTranslate
After=network.target

[Service]
ExecStart=/usr/local/bin/libretranslate --host 0.0.0.0 --port 5000 --api-keys
Restart=always
User=ubuntu

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable libretranslate
sudo systemctl start libretranslate

# 5. Set up nginx reverse proxy with HTTPS (certbot)
sudo apt install -y nginx certbot python3-certbot-nginx
# Configure nginx to proxy :443 → :5000
# Run: sudo certbot --nginx -d translate.witt.app
```

**Deliverable:** `https://translate.witt.app/translate` endpoint live.

**Verification:**
```bash
curl -X POST https://translate.witt.app/translate \
  -H "Content-Type: application/json" \
  -d '{"q":"Hello","source":"en","target":"fr","format":"text"}'
# Expected: {"translatedText":"Bonjour"}
```

---

### Session L2 — Flutter: TranslationService

**Goal:** Dart service that routes to ML Kit or LibreTranslate.

**Package additions to `apps/witt_app/pubspec.yaml`:**
```yaml
  google_mlkit_translation: ^0.11.0
```

**New file: `lib/features/translation/services/translation_service.dart`**

```dart
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:dio/dio.dart';

class TranslationService {
  static const _libreTranslateUrl = 'https://translate.witt.app/translate';
  static const _apiKey = String.fromEnvironment('LIBRETRANSLATE_API_KEY');

  static final _dio = Dio();

  // ML Kit supported BCP-47 codes
  static const _mlKitLanguages = {
    'af', 'sq', 'ar', 'be', 'bn', 'bg', 'ca', 'zh', 'hr', 'cs',
    'da', 'nl', 'en', 'eo', 'et', 'fi', 'fr', 'gl', 'ka', 'de',
    'el', 'gu', 'ht', 'he', 'hi', 'hu', 'is', 'id', 'ga', 'it',
    'ja', 'kn', 'ko', 'lv', 'lt', 'mk', 'ms', 'mt', 'mr', 'no',
    'fa', 'pl', 'pt', 'ro', 'ru', 'sk', 'sl', 'es', 'sw', 'sv',
    'tl', 'ta', 'te', 'th', 'tr', 'uk', 'ur', 'vi', 'cy',
  };

  static Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (_mlKitLanguages.contains(targetLang)) {
      return _translateWithMlKit(text, sourceLang, targetLang);
    }
    return _translateWithLibreTranslate(text, sourceLang, targetLang);
  }

  static Future<String> _translateWithMlKit(
    String text, String source, String target,
  ) async {
    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.values.firstWhere(
        (l) => l.bcpCode == source,
        orElse: () => TranslateLanguage.english,
      ),
      targetLanguage: TranslateLanguage.values.firstWhere(
        (l) => l.bcpCode == target,
        orElse: () => TranslateLanguage.english,
      ),
    );
    try {
      return await translator.translateText(text);
    } finally {
      translator.close();
    }
  }

  static Future<String> _translateWithLibreTranslate(
    String text, String source, String target,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _libreTranslateUrl,
      data: {
        'q': text,
        'source': source,
        'target': target,
        'format': 'text',
        if (_apiKey.isNotEmpty) 'api_key': _apiKey,
      },
    );
    return response.data?['translatedText'] as String? ?? text;
  }

  /// Downloads the ML Kit model for [langCode] if not already cached.
  static Future<void> downloadModel(String langCode) async {
    final lang = TranslateLanguage.values.firstWhere(
      (l) => l.bcpCode == langCode,
      orElse: () => TranslateLanguage.english,
    );
    final manager = OnDeviceTranslatorModelManager();
    final isDownloaded = await manager.isModelDownloaded(lang);
    if (!isDownloaded) {
      await manager.downloadModel(lang);
    }
  }
}
```

**Deliverable:** `TranslationService.translate()` works for all 65+ languages.

---

### Session L3 — UI: Language Selector + Translation Screen

**Goal:** Wire `TranslationService` into the existing `TranslationScreen`.

**Steps:**
1. Replace the current stub `TranslationScreen` with a full implementation:
   - Source language picker (dropdown, all 65+ languages)
   - Target language picker
   - Text input field
   - Translate button (black bg, white text)
   - Result display
   - "Download for offline" button (triggers `downloadModel()` for ML Kit languages)
2. Add a `Riverpod` provider: `translationProvider` that wraps `TranslationService`
3. Show loading indicator during translation
4. Show graceful error if VPS unreachable (offline fallback message)

**Deliverable:** Translation screen fully functional end-to-end.

---

### Session L4 — Inline Translation (Content Screens)

**Goal:** Allow users to translate any text in the app (exam questions, Sage responses, community posts).

**Steps:**
1. Add a `TranslatableText` widget that wraps `SelectableText` with a long-press context menu option "Translate"
2. On tap: show a bottom sheet with the translated text in the user's preferred language
3. Preferred language stored in `OnboardingData.languageCode` (already persisted)
4. Wire into:
   - `ExamHubScreen` question text
   - `_MessageBubble` in `SageScreen`
   - Community post bodies in `SocialScreen`

**Deliverable:** Long-press → translate on all major content surfaces.

---

### Session L5 — Model Management + Settings

**Goal:** Let users manage downloaded offline language models.

**Steps:**
1. Add "Offline Languages" section to `ProfileScreen` settings
2. List all 59 ML Kit languages with download status
3. Download / delete buttons per language
4. Show storage size per model (~30 MB each)
5. Auto-download user's selected app language on first launch

**Deliverable:** Users can manage offline language packs from settings.

---

### Session L6 — VPS API Key + Rate Limiting

**Goal:** Secure the LibreTranslate endpoint.

**Steps:**
1. Generate API keys on the VPS: `libretranslate --gen-api-key`
2. Add `LIBRETRANSLATE_API_KEY` to `.env.prod`, `.env.staging`
3. Add to `flutter_dotenv` loading in `main.dart`
4. Add rate limiting in nginx config (e.g., 60 req/min per IP)
5. Add Supabase Edge Function as a proxy (optional, for key hiding)

**Deliverable:** VPS endpoint secured, keys rotatable without app update.

---

## Environment Variables Required

| Key | Where | Value |
|-----|-------|-------|
| `LIBRETRANSLATE_URL` | `.env.prod` | `https://translate.witt.app` |
| `LIBRETRANSLATE_API_KEY` | `.env.prod` | Generated on VPS |

---

## VPS Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 2 GB | 4 GB |
| Storage | 10 GB (models) | 20 GB |
| CPU | 1 vCPU | 2 vCPU |
| OS | Ubuntu 22.04 | Ubuntu 22.04 |

---

## Next Step

Provide VPS SSH details to begin **Session L1** (LibreTranslate installation).
