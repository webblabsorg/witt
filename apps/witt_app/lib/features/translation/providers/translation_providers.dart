import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_models.dart';
import '../../../core/persistence/hive_boxes.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/translation/ml_kit_translate_client.dart';

// ── Supported languages ───────────────────────────────────────────────────

const supportedLanguages = [
  SupportedLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
    isOfflineAvailable: true,
  ),
  SupportedLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
    isOfflineAvailable: true,
  ),
  SupportedLanguage(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
    isOfflineAvailable: true,
  ),
  SupportedLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    flag: '🇸🇦',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'zh',
    name: 'Chinese',
    nativeName: '中文',
    flag: '🇨🇳',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    flag: '🇧🇷',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'it',
    name: 'Italian',
    nativeName: 'Italiano',
    flag: '🇮🇹',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'nl',
    name: 'Dutch',
    nativeName: 'Nederlands',
    flag: '🇳🇱',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'ru',
    name: 'Russian',
    nativeName: 'Русский',
    flag: '🇷🇺',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'pl',
    name: 'Polish',
    nativeName: 'Polski',
    flag: '🇵🇱',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'tr',
    name: 'Turkish',
    nativeName: 'Türkçe',
    flag: '🇹🇷',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'sw',
    name: 'Swahili',
    nativeName: 'Kiswahili',
    flag: '🇰🇪',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
    flag: '🇧🇩',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'vi',
    name: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    flag: '🇻🇳',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flag: '🇯🇵',
    isOfflineAvailable: false,
  ),
  SupportedLanguage(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    flag: '🇰🇷',
    isOfflineAvailable: false,
  ),
];

final supportedLanguagesProvider = Provider<List<SupportedLanguage>>(
  (_) => supportedLanguages,
);

// ── Translation notifier ──────────────────────────────────────────────────

class TranslationNotifier extends Notifier<TranslationState> {
  int _requestId = 0;
  Timer? _inputDebounce;

  bool _isSupported(String code) =>
      supportedLanguages.any((lang) => lang.code == code);

  @override
  TranslationState build() {
    ref.onDispose(() {
      _inputDebounce?.cancel();
    });

    final preferredLocale = ref.watch(localeProvider).languageCode;
    final preferredTarget = _isSupported(preferredLocale)
        ? preferredLocale
        : 'en';

    final srcLang =
        translationBox.get(kKeyLastSourceLang, defaultValue: 'en') as String;
    final tgtLang = preferredTarget;
    final rawHistory =
        translationBox.get(kKeyTranslationHistory, defaultValue: <dynamic>[])
            as List;
    final history = rawHistory.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return TranslationResult(
        sourceText: m['src'] as String,
        translatedText: m['tgt'] as String,
        sourceLang: m['srcLang'] as String,
        targetLang: m['tgtLang'] as String,
        timestamp: DateTime.parse(m['ts'] as String),
        isOffline: m['offline'] as bool? ?? false,
      );
    }).toList();
    return TranslationState(
      sourceLang: srcLang,
      targetLang: tgtLang,
      history: history,
    );
  }

  void setSourceLang(String code) {
    state = state.copyWith(sourceLang: code, result: null);
    translationBox.put(kKeyLastSourceLang, code);
    if (state.inputText.trim().isNotEmpty) {
      unawaited(translate());
    }
  }

  void setTargetLang(String code) {
    state = state.copyWith(targetLang: code, result: null);
    translationBox.put(kKeyLastTargetLang, code);
    if (state.inputText.trim().isNotEmpty) {
      unawaited(translate());
    }
  }

  void swapLanguages() {
    state = state.copyWith(
      sourceLang: state.targetLang,
      targetLang: state.sourceLang,
      result: null,
    );
    translationBox.put(kKeyLastSourceLang, state.sourceLang);
    translationBox.put(kKeyLastTargetLang, state.targetLang);
  }

  void setInput(String text) {
    state = state.copyWith(inputText: text, result: null);
    _inputDebounce?.cancel();
    if (text.trim().isEmpty) return;
    _inputDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(translate());
    });
  }

  Future<void> translate() async {
    final requestId = ++_requestId;

    final text = state.inputText.trim();
    if (text.isEmpty) return;

    final srcLang = state.sourceLang;
    final tgtLang = state.targetLang;
    state = state.copyWith(status: TranslationStatus.loading, error: null);

    try {
      final translated = await MlKitTranslateClient.instance.translate(
        text: text,
        sourceLang: srcLang,
        targetLang: tgtLang,
      );

      final result = TranslationResult(
        sourceText: text,
        translatedText: translated,
        sourceLang: srcLang,
        targetLang: tgtLang,
        timestamp: DateTime.now(),
        isOffline: true,
      );

      final newHistory = [result, ...state.history.take(19)];

      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        status: TranslationStatus.success,
        result: result,
        history: newHistory,
      );
      Analytics.translate(srcLang, tgtLang, true);
      translationBox.put(
        kKeyTranslationHistory,
        newHistory
            .map(
              (r) => {
                'src': r.sourceText,
                'tgt': r.translatedText,
                'srcLang': r.sourceLang,
                'tgtLang': r.targetLang,
                'ts': r.timestamp.toIso8601String(),
                'offline': r.isOffline,
              },
            )
            .toList(),
      );
    } on MlKitTranslateException catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        status: TranslationStatus.error,
        error: 'Translation failed: ${e.message}',
      );
    } catch (_) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        status: TranslationStatus.error,
        error: 'Translation failed. Check your connection.',
      );
    }
  }

  void clearHistory() {
    state = state.copyWith(history: []);
    translationBox.put(kKeyTranslationHistory, <dynamic>[]);
  }
}

final translationProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
      TranslationNotifier.new,
    );
