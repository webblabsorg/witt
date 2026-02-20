/// LibreTranslate HTTP client — 100% open-source, no Google/Microsoft APIs.
///
/// Self-host: https://github.com/LibreTranslate/LibreTranslate
/// Public instance: https://libretranslate.com (rate-limited, free tier)
///
/// Set LIBRETRANSLATE_URL in .env to point at your own instance for
/// unlimited, zero-cost translations.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LibreTranslateClient {
  LibreTranslateClient._()
      : _baseUrl = dotenv.env['LIBRETRANSLATE_URL'] ?? 'https://libretranslate.com',
        _apiKey = dotenv.env['LIBRETRANSLATE_API_KEY'] ?? '',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

  static final instance = LibreTranslateClient._();

  final String _baseUrl;
  final String _apiKey;
  final Dio _dio;

  /// Translate [text] from [sourceLang] to [targetLang].
  /// Returns the translated string.
  /// Throws [LibreTranslateException] on failure.
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return text;
    if (sourceLang == targetLang) return text;

    try {
      final body = <String, dynamic>{
        'q': text,
        'source': sourceLang,
        'target': targetLang,
        'format': 'text',
      };
      if (_apiKey.isNotEmpty) body['api_key'] = _apiKey;

      final response = await _dio.post(
        '$_baseUrl/translate',
        data: jsonEncode(body),
      );

      final data = response.data;
      if (data is Map && data.containsKey('translatedText')) {
        return data['translatedText'] as String;
      }
      throw LibreTranslateException('Unexpected response: $data');
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.message ?? 'Network error';
      throw LibreTranslateException(msg.toString());
    }
  }

  /// Detect the language of [text].
  /// Returns a language code string (e.g. 'en', 'fr').
  Future<String> detect(String text) async {
    try {
      final body = <String, dynamic>{'q': text};
      if (_apiKey.isNotEmpty) body['api_key'] = _apiKey;

      final response = await _dio.post(
        '$_baseUrl/detect',
        data: jsonEncode(body),
      );

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return (data.first as Map)['language'] as String? ?? 'en';
      }
      return 'en';
    } on DioException {
      return 'en';
    }
  }

  /// Fetch supported languages from the LibreTranslate instance.
  Future<List<Map<String, String>>> fetchSupportedLanguages() async {
    try {
      final response = await _dio.get('$_baseUrl/languages');
      final data = response.data as List;
      return data
          .map((e) => {
                'code': (e as Map)['code'] as String,
                'name': e['name'] as String,
              })
          .toList();
    } on DioException {
      return [];
    }
  }
}

class LibreTranslateException implements Exception {
  const LibreTranslateException(this.message);
  final String message;

  @override
  String toString() => 'LibreTranslateException: $message';
}
