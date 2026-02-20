library;

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MlKitTranslateClient {
  MlKitTranslateClient._();

  static final instance = MlKitTranslateClient._();

  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final input = text.trim();
    if (input.isEmpty) return text;

    final source = _toTranslateLanguage(sourceLang);
    final target = _toTranslateLanguage(targetLang);

    if (source == target) return text;

    final manager = OnDeviceTranslatorModelManager();
    final sourceReady = await manager.isModelDownloaded(source.bcpCode);
    if (!sourceReady) {
      await manager.downloadModel(source.bcpCode);
    }

    final targetReady = await manager.isModelDownloaded(target.bcpCode);
    if (!targetReady) {
      await manager.downloadModel(target.bcpCode);
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );

    try {
      return await translator.translateText(input);
    } catch (e) {
      throw MlKitTranslateException(e.toString());
    } finally {
      translator.close();
    }
  }

  TranslateLanguage _toTranslateLanguage(String code) {
    final normalized = code.trim();
    final base = normalized.split('-').first.toLowerCase();

    try {
      return TranslateLanguage.values.firstWhere((l) => l.bcpCode == base);
    } catch (_) {
      throw MlKitTranslateException('Language not supported on-device: $code');
    }
  }
}

class MlKitTranslateException implements Exception {
  const MlKitTranslateException(this.message);

  final String message;

  @override
  String toString() => 'MlKitTranslateException: $message';
}
