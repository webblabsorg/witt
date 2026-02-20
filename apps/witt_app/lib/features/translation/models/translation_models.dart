import 'package:flutter/foundation.dart';

// ── Language ──────────────────────────────────────────────────────────────

@immutable
class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isOfflineAvailable = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isOfflineAvailable;
}

// ── Translation result ────────────────────────────────────────────────────

@immutable
class TranslationResult {
  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    this.isOffline = false,
  });

  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final bool isOffline;
}

// ── Translation state ─────────────────────────────────────────────────────

enum TranslationStatus { idle, loading, success, error }

@immutable
class TranslationState {
  const TranslationState({
    this.status = TranslationStatus.idle,
    this.sourceLang = 'en',
    this.targetLang = 'fr',
    this.inputText = '',
    this.result,
    this.error,
    this.history = const [],
  });

  final TranslationStatus status;
  final String sourceLang;
  final String targetLang;
  final String inputText;
  final TranslationResult? result;
  final String? error;
  final List<TranslationResult> history;

  TranslationState copyWith({
    TranslationStatus? status,
    String? sourceLang,
    String? targetLang,
    String? inputText,
    TranslationResult? result,
    String? error,
    List<TranslationResult>? history,
  }) =>
      TranslationState(
        status: status ?? this.status,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        inputText: inputText ?? this.inputText,
        result: result ?? this.result,
        error: error ?? this.error,
        history: history ?? this.history,
      );
}
