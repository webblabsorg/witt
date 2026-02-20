import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_models.dart';

// ── Supported languages ───────────────────────────────────────────────────

const supportedLanguages = [
  SupportedLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧', isOfflineAvailable: true),
  SupportedLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', isOfflineAvailable: true),
  SupportedLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', isOfflineAvailable: true),
  SupportedLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', isOfflineAvailable: false),
  SupportedLanguage(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳', isOfflineAvailable: false),
  SupportedLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', isOfflineAvailable: false),
  SupportedLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷', isOfflineAvailable: false),
  SupportedLanguage(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', flag: '🇰🇪', isOfflineAvailable: false),
  SupportedLanguage(code: 'yo', name: 'Yoruba', nativeName: 'Yorùbá', flag: '🇳🇬', isOfflineAvailable: false),
  SupportedLanguage(code: 'ha', name: 'Hausa', nativeName: 'Hausa', flag: '🇳🇬', isOfflineAvailable: false),
  SupportedLanguage(code: 'ig', name: 'Igbo', nativeName: 'Igbo', flag: '🇳🇬', isOfflineAvailable: false),
  SupportedLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', isOfflineAvailable: false),
  SupportedLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵', isOfflineAvailable: false),
  SupportedLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷', isOfflineAvailable: false),
];

final supportedLanguagesProvider = Provider<List<SupportedLanguage>>(
  (_) => supportedLanguages,
);

// ── Translation notifier ──────────────────────────────────────────────────

class TranslationNotifier extends Notifier<TranslationState> {
  @override
  TranslationState build() => const TranslationState();

  void setSourceLang(String code) {
    state = state.copyWith(sourceLang: code, result: null);
  }

  void setTargetLang(String code) {
    state = state.copyWith(targetLang: code, result: null);
  }

  void swapLanguages() {
    state = state.copyWith(
      sourceLang: state.targetLang,
      targetLang: state.sourceLang,
      result: null,
    );
  }

  void setInput(String text) {
    state = state.copyWith(inputText: text, result: null);
  }

  Future<void> translate() async {
    final text = state.inputText.trim();
    if (text.isEmpty) return;

    state = state.copyWith(status: TranslationStatus.loading, error: null);

    try {
      // In production: call Google Cloud Translation API or DeepL
      // For offline: use TF Lite model bundled with app
      // Here we simulate with a delay and mock translation
      await Future.delayed(const Duration(milliseconds: 800));

      final translated = _mockTranslate(text, state.sourceLang, state.targetLang);
      final result = TranslationResult(
        sourceText: text,
        translatedText: translated,
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
        timestamp: DateTime.now(),
        isOffline: false,
      );

      state = state.copyWith(
        status: TranslationStatus.success,
        result: result,
        history: [result, ...state.history.take(19)],
      );
    } catch (e) {
      state = state.copyWith(
        status: TranslationStatus.error,
        error: 'Translation failed. Check your connection.',
      );
    }
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  /// Mock translation — replace with real API call in production
  String _mockTranslate(String text, String from, String to) {
    final translations = {
      'fr': {
        'hello': 'bonjour',
        'world': 'monde',
        'study': 'étudier',
        'learn': 'apprendre',
        'school': 'école',
        'exam': 'examen',
        'question': 'question',
        'answer': 'réponse',
      },
      'es': {
        'hello': 'hola',
        'world': 'mundo',
        'study': 'estudiar',
        'learn': 'aprender',
        'school': 'escuela',
        'exam': 'examen',
        'question': 'pregunta',
        'answer': 'respuesta',
      },
      'ar': {
        'hello': 'مرحبا',
        'study': 'دراسة',
        'learn': 'تعلم',
        'school': 'مدرسة',
        'exam': 'امتحان',
      },
    };

    final lower = text.toLowerCase();
    final langMap = translations[to];
    if (langMap != null && langMap.containsKey(lower)) {
      return langMap[lower]!;
    }

    // Fallback: prefix with target language indicator
    return '[$to] $text';
  }
}

final translationProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
  TranslationNotifier.new,
);
