# ML Kit On-Device Translation — Architecture Prompt

Use this prompt when implementing Google ML Kit translation in a new Flutter app.
This architecture is battle-tested from the Witt app (v26.2).

---

## Prompt

You are implementing **Google ML Kit on-device translation** for a Flutter app using
**Riverpod** for state management, **Hive** for local persistence, and **GoRouter** for
navigation. Follow this exact architecture:

---

### 1. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  google_mlkit_translation: ^0.11.1   # ML Kit translation
  flutter_riverpod: ^2.6.1
  hive_flutter: ^1.1.0
  go_router: ^14.8.1
```

---

### 2. Centralized Language Catalog (`lib/core/translation/ml_kit_languages.dart`)

Create a single source of truth for all 59 ML Kit supported languages:

```dart
class MlKitLanguage {
  const MlKitLanguage({
    required this.code,       // BCP-47 / ML Kit code e.g. 'en', 'zh-Hans'
    required this.englishName,
    required this.nativeName,
    required this.flag,
  });
  final String code;
  final String englishName;
  final String nativeName;
  final String flag;
}

const List<MlKitLanguage> mlKitLanguages = [
  MlKitLanguage(code: 'af', englishName: 'Afrikaans',   nativeName: 'Afrikaans',    flag: '🇿🇦'),
  MlKitLanguage(code: 'ar', englishName: 'Arabic',      nativeName: 'العربية',       flag: '🇸🇦'),
  MlKitLanguage(code: 'be', englishName: 'Belarusian',  nativeName: 'Беларуская',    flag: '🇧🇾'),
  MlKitLanguage(code: 'bg', englishName: 'Bulgarian',   nativeName: 'Български',     flag: '🇧🇬'),
  MlKitLanguage(code: 'bn', englishName: 'Bengali',     nativeName: 'বাংলা',          flag: '🇧🇩'),
  MlKitLanguage(code: 'ca', englishName: 'Catalan',     nativeName: 'Català',        flag: '🏴󠁥󠁳󠁣󠁴󠁿'),
  MlKitLanguage(code: 'cs', englishName: 'Czech',       nativeName: 'Čeština',       flag: '🇨🇿'),
  MlKitLanguage(code: 'cy', englishName: 'Welsh',       nativeName: 'Cymraeg',       flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿'),
  MlKitLanguage(code: 'da', englishName: 'Danish',      nativeName: 'Dansk',         flag: '🇩🇰'),
  MlKitLanguage(code: 'de', englishName: 'German',      nativeName: 'Deutsch',       flag: '🇩🇪'),
  MlKitLanguage(code: 'el', englishName: 'Greek',       nativeName: 'Ελληνικά',      flag: '🇬🇷'),
  MlKitLanguage(code: 'en', englishName: 'English',     nativeName: 'English',       flag: '🇬🇧'),
  MlKitLanguage(code: 'eo', englishName: 'Esperanto',   nativeName: 'Esperanto',     flag: '🌍'),
  MlKitLanguage(code: 'es', englishName: 'Spanish',     nativeName: 'Español',       flag: '🇪🇸'),
  MlKitLanguage(code: 'et', englishName: 'Estonian',    nativeName: 'Eesti',         flag: '🇪🇪'),
  MlKitLanguage(code: 'fa', englishName: 'Persian',     nativeName: 'فارسی',          flag: '🇮🇷'),
  MlKitLanguage(code: 'fi', englishName: 'Finnish',     nativeName: 'Suomi',         flag: '🇫🇮'),
  MlKitLanguage(code: 'fr', englishName: 'French',      nativeName: 'Français',      flag: '🇫🇷'),
  MlKitLanguage(code: 'ga', englishName: 'Irish',       nativeName: 'Gaeilge',       flag: '🇮🇪'),
  MlKitLanguage(code: 'gl', englishName: 'Galician',    nativeName: 'Galego',        flag: '🇪🇸'),
  MlKitLanguage(code: 'gu', englishName: 'Gujarati',    nativeName: 'ગુજરાતી',        flag: '🇮🇳'),
  MlKitLanguage(code: 'he', englishName: 'Hebrew',      nativeName: 'עברית',          flag: '🇮🇱'),
  MlKitLanguage(code: 'hi', englishName: 'Hindi',       nativeName: 'हिन्दी',          flag: '🇮🇳'),
  MlKitLanguage(code: 'hr', englishName: 'Croatian',    nativeName: 'Hrvatski',      flag: '🇭🇷'),
  MlKitLanguage(code: 'hu', englishName: 'Hungarian',   nativeName: 'Magyar',        flag: '🇭🇺'),
  MlKitLanguage(code: 'id', englishName: 'Indonesian',  nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
  MlKitLanguage(code: 'is', englishName: 'Icelandic',   nativeName: 'Íslenska',      flag: '🇮🇸'),
  MlKitLanguage(code: 'it', englishName: 'Italian',     nativeName: 'Italiano',      flag: '🇮🇹'),
  MlKitLanguage(code: 'ja', englishName: 'Japanese',    nativeName: '日本語',          flag: '🇯🇵'),
  MlKitLanguage(code: 'ka', englishName: 'Georgian',    nativeName: 'ქართული',       flag: '🇬🇪'),
  MlKitLanguage(code: 'kn', englishName: 'Kannada',     nativeName: 'ಕನ್ನಡ',          flag: '🇮🇳'),
  MlKitLanguage(code: 'ko', englishName: 'Korean',      nativeName: '한국어',          flag: '🇰🇷'),
  MlKitLanguage(code: 'lt', englishName: 'Lithuanian',  nativeName: 'Lietuvių',      flag: '🇱🇹'),
  MlKitLanguage(code: 'lv', englishName: 'Latvian',     nativeName: 'Latviešu',      flag: '🇱🇻'),
  MlKitLanguage(code: 'mk', englishName: 'Macedonian',  nativeName: 'Македонски',    flag: '🇲🇰'),
  MlKitLanguage(code: 'mr', englishName: 'Marathi',     nativeName: 'मराठी',          flag: '🇮🇳'),
  MlKitLanguage(code: 'ms', englishName: 'Malay',       nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  MlKitLanguage(code: 'mt', englishName: 'Maltese',     nativeName: 'Malti',         flag: '🇲🇹'),
  MlKitLanguage(code: 'nl', englishName: 'Dutch',       nativeName: 'Nederlands',    flag: '🇳🇱'),
  MlKitLanguage(code: 'no', englishName: 'Norwegian',   nativeName: 'Norsk',         flag: '🇳🇴'),
  MlKitLanguage(code: 'pa', englishName: 'Punjabi',     nativeName: 'ਪੰਜਾਬੀ',         flag: '🇮🇳'),
  MlKitLanguage(code: 'pl', englishName: 'Polish',      nativeName: 'Polski',        flag: '🇵🇱'),
  MlKitLanguage(code: 'pt', englishName: 'Portuguese',  nativeName: 'Português',     flag: '🇧🇷'),
  MlKitLanguage(code: 'ro', englishName: 'Romanian',    nativeName: 'Română',        flag: '🇷🇴'),
  MlKitLanguage(code: 'ru', englishName: 'Russian',     nativeName: 'Русский',       flag: '🇷🇺'),
  MlKitLanguage(code: 'sk', englishName: 'Slovak',      nativeName: 'Slovenčina',    flag: '🇸🇰'),
  MlKitLanguage(code: 'sl', englishName: 'Slovenian',   nativeName: 'Slovenščina',   flag: '🇸🇮'),
  MlKitLanguage(code: 'sq', englishName: 'Albanian',    nativeName: 'Shqip',         flag: '🇦🇱'),
  MlKitLanguage(code: 'sr', englishName: 'Serbian',     nativeName: 'Српски',        flag: '🇷🇸'),
  MlKitLanguage(code: 'sv', englishName: 'Swedish',     nativeName: 'Svenska',       flag: '🇸🇪'),
  MlKitLanguage(code: 'sw', englishName: 'Swahili',     nativeName: 'Kiswahili',     flag: '🇰🇪'),
  MlKitLanguage(code: 'ta', englishName: 'Tamil',       nativeName: 'தமிழ்',          flag: '🇮🇳'),
  MlKitLanguage(code: 'te', englishName: 'Telugu',      nativeName: 'తెలుగు',         flag: '🇮🇳'),
  MlKitLanguage(code: 'th', englishName: 'Thai',        nativeName: 'ภาษาไทย',        flag: '🇹🇭'),
  MlKitLanguage(code: 'tl', englishName: 'Filipino',    nativeName: 'Filipino',      flag: '🇵🇭'),
  MlKitLanguage(code: 'tr', englishName: 'Turkish',     nativeName: 'Türkçe',        flag: '🇹🇷'),
  MlKitLanguage(code: 'uk', englishName: 'Ukrainian',   nativeName: 'Українська',    flag: '🇺🇦'),
  MlKitLanguage(code: 'ur', englishName: 'Urdu',        nativeName: 'اردو',           flag: '🇵🇰'),
  MlKitLanguage(code: 'vi', englishName: 'Vietnamese',  nativeName: 'Tiếng Việt',    flag: '🇻🇳'),
  MlKitLanguage(code: 'zh', englishName: 'Chinese (Simplified)',  nativeName: '中文（简体）', flag: '🇨🇳'),
  MlKitLanguage(code: 'zh-Hant', englishName: 'Chinese (Traditional)', nativeName: '中文（繁體）', flag: '🇹🇼'),
];
```

---

### 3. ML Kit Translation Client (`lib/core/translation/ml_kit_translate_client.dart`)

```dart
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MlKitTranslateClient {
  MlKitTranslateClient._();
  static final instance = MlKitTranslateClient._();

  final _cache = <String, OnDeviceTranslator>{};

  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return '';
    if (sourceLang == targetLang) return text;

    final key = '$sourceLang→$targetLang';
    final translator = _cache.putIfAbsent(key, () => OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.values.firstWhere(
        (l) => l.bcpCode == sourceLang,
        orElse: () => TranslateLanguage.english,
      ),
      targetLanguage: TranslateLanguage.values.firstWhere(
        (l) => l.bcpCode == targetLang,
        orElse: () => TranslateLanguage.english,
      ),
    ));

    // Download model if not already on device (happens once per language pair)
    final modelManager = OnDeviceTranslatorModelManager();
    final isDownloaded = await modelManager.isModelDownloaded(targetLang);
    if (!isDownloaded) {
      await modelManager.downloadModel(targetLang);
    }

    return await translator.translateText(text);
  }

  void dispose() {
    for (final t in _cache.values) {
      t.close();
    }
    _cache.clear();
  }
}
```

---

### 4. Translation State & Provider (`lib/features/translation/providers/translation_providers.dart`)

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/translation/ml_kit_languages.dart';
import '../../../core/translation/ml_kit_translate_client.dart';

// ── Supported languages (from centralized catalog) ──────────────────────────

final supportedLanguages = mlKitLanguages
    .map((l) => SupportedLanguage(code: l.code, name: l.englishName, nativeName: l.nativeName))
    .toList(growable: false);

// ── Translation state ────────────────────────────────────────────────────────

class TranslationState {
  const TranslationState({
    required this.sourceLang,
    required this.targetLang,
    required this.inputText,
    required this.outputText,
    required this.isTranslating,
    required this.isOffline,
    required this.history,
  });
  // ... fields
}

// ── Translation notifier ─────────────────────────────────────────────────────

class TranslationNotifier extends AutoDisposeNotifier<TranslationState> {
  Timer? _inputDebounce;
  static const _debounce = Duration(milliseconds: 350);

  bool _isSupported(String code) =>
      supportedLanguages.any((l) => l.code == code);

  @override
  TranslationState build() {
    ref.onDispose(() => _inputDebounce?.cancel());

    // Prefer app locale → onboarding language → 'en'
    final localeCode = ref.watch(localeProvider).languageCode;
    final onboardingLang = ref.watch(onboardingProvider).language;
    final preferredTarget = _isSupported(localeCode)
        ? localeCode
        : _isSupported(onboardingLang)
            ? onboardingLang
            : 'en';

    return TranslationState(
      sourceLang: 'en',
      targetLang: preferredTarget,
      inputText: '',
      outputText: '',
      isTranslating: false,
      isOffline: true, // ML Kit is always offline
      history: [],
    );
  }

  // Debounced input → triggers translation after 350ms idle
  void onInputChanged(String text) {
    _inputDebounce?.cancel();
    _inputDebounce = Timer(_debounce, () => _translate(text));
  }

  Future<void> _translate(String text) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(outputText: '', isTranslating: false);
      return;
    }
    state = state.copyWith(isTranslating: true);
    try {
      final result = await MlKitTranslateClient.instance.translate(
        text: text,
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
      );
      state = state.copyWith(outputText: result, isTranslating: false);
    } catch (_) {
      state = state.copyWith(isTranslating: false);
    }
  }

  void setSourceLang(String code) => state = state.copyWith(sourceLang: code);
  void setTargetLang(String code) => state = state.copyWith(targetLang: code);
  void swapLanguages() => state = state.copyWith(
    sourceLang: state.targetLang,
    targetLang: state.sourceLang,
    inputText: state.outputText,
    outputText: state.inputText,
  );
}

final translationProvider =
    AutoDisposeNotifierProvider<TranslationNotifier, TranslationState>(
  TranslationNotifier.new,
);
```

---

### 5. Language Picker Screen

```dart
class LanguagePickerScreen extends ConsumerStatefulWidget { ... }

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String _selected = 'en';

  static final _languages = mlKitLanguages
      .map((l) => _Language(l.code, l.flag, l.nativeName, l.englishName))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    // Prefer persisted locale; fall back to onboarding language
    final localeCode = ref.read(localeProvider).languageCode;
    final onboardingLang = ref.read(onboardingProvider).language;
    final matchedByLocale = _languages.any((l) =>
        l.code == localeCode || l.code.split('-').first == localeCode);
    _selected = matchedByLocale ? localeCode : onboardingLang;
  }

  Future<void> _onSelect(String code) async {
    setState(() => _selected = code);
    await ref.read(localeProvider.notifier).setLocale(code.split('-').first);
    await ref.read(onboardingProvider.notifier).setLanguage(code);
  }

  // Build: ListView of all 59 languages with flag + native name + English name
  // Continue button: context.go('/onboarding/wizard/1')
}
```

---

### 6. Locale Provider (`lib/core/providers/locale_provider.dart`)

```dart
class LocaleNotifier extends Notifier<Locale> {
  late Box<dynamic> _box;

  @override
  Locale build() {
    _box = Hive.box<dynamic>('app_prefs');
    final saved = _box.get('app_locale', defaultValue: 'en') as String;
    return Locale(saved);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _box.put('app_locale', languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
```

---

### 7. Bootstrap (Hive initialization order)

**Critical:** Open all Hive boxes BEFORE Riverpod providers initialize.

```dart
static Future<void> run(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await openOnboardingBox();     // Must be first — translation provider depends on it
  await Hive.openBox<dynamic>('app_prefs');  // localeProvider depends on this
  // ... rest of init (Supabase, analytics, etc.)
}
```

---

### 8. Router Redirect Logic

```dart
// onboardingDone = isCompleted AND (authenticated OR anonymous)
final isSignedIn = auth.status == AuthStatus.authenticated ||
    auth.status == AuthStatus.anonymous;
final onboardingDone = onboarding.isCompleted && isSignedIn;

// Startup flow:
// Fresh user:     Splash → Language Picker → Wizard → Auth → Paywall → Home
// Returning auth: Splash → auto-complete if needed → Home
// Anonymous+done: Splash → Home (protected routes redirect to auth screen)

if (!onboardingDone && !location.startsWith('/onboarding')) {
  return '/onboarding/splash?from=${Uri.encodeComponent(fullUri)}';
}

// Returning authenticated user with isCompleted=false → auto-complete
// (handle in splash screen _nextRoute())
if (auth.status == AuthStatus.authenticated && !onboarding.isCompleted) {
  await ref.read(onboardingProvider.notifier).complete();
  return '/home';
}
```

---

### 9. Key Architectural Rules

1. **Single source of truth** — `mlKitLanguages` list is the only place language metadata lives. Never duplicate it.
2. **Locale = translation target** — `localeProvider` drives both the app UI language and the translation target language. `onboardingProvider.language` is the fallback.
3. **No network calls** — ML Kit downloads models once on first use, then works fully offline. Mark `isOffline: true` always.
4. **Debounce input** — 350ms debounce on text input prevents excessive ML Kit calls.
5. **Model caching** — Cache `OnDeviceTranslator` instances by `sourceLang→targetLang` key. Never create a new one per keystroke.
6. **Bootstrap order** — Hive boxes must open before any Riverpod provider that reads from Hive.
7. **Anonymous users** — Treat `anonymous` same as `authenticated` for onboarding completion. Block them from full-auth-only routes (`/profile`, `/sage`) by redirecting to auth screen.
8. **Returning users** — If `isAuthenticated && !isCompleted`, auto-call `complete()` in splash so they never re-run the wizard.

---

### 10. Testing Checklist

```dart
// Verify language count
expect(supportedLanguages.length, 59);

// Verify translation provider uses locale
final container = ProviderContainer(overrides: [
  localeProvider.overrideWith(() => MockLocaleNotifier('fr')),
]);
expect(container.read(translationProvider).targetLang, 'fr');

// Verify router redirect for fresh user
final result = computeRedirect(
  location: '/home',
  fullUri: '/home',
  onboarding: OnboardingData(isCompleted: false),
  auth: AuthState(status: AuthStatus.unauthenticated),
);
expect(result, startsWith('/onboarding/splash?from='));

// Verify anonymous+completed passes through to home
final result2 = computeRedirect(
  location: '/home',
  fullUri: '/home',
  onboarding: OnboardingData(isCompleted: true),
  auth: AuthState(status: AuthStatus.anonymous),
);
expect(result2, isNull);
```

---

## Checklist for New App Implementation

- [ ] Add `google_mlkit_translation` to `pubspec.yaml`
- [ ] Add Android permissions in `AndroidManifest.xml` (internet for first model download)
- [ ] Copy `ml_kit_languages.dart` catalog
- [ ] Create `MlKitTranslateClient` singleton with model caching
- [ ] Create `TranslationNotifier` with debounced input and locale-aware target language
- [ ] Create `LocaleNotifier` backed by Hive `app_prefs` box
- [ ] Create `LanguagePickerScreen` using full 59-language list
- [ ] Open Hive boxes in bootstrap BEFORE providers initialize
- [ ] Implement router redirect logic with `onboardingDone = isCompleted && isSignedIn`
- [ ] Handle returning authenticated users: auto-complete onboarding in splash
- [ ] Write tests: language count, redirect logic, anonymous flow, locale sync
