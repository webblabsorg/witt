import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_models.dart';

/// Central AI routing layer.
/// All AI calls go through this class — it selects the correct
/// Supabase Edge Function based on feature + user tier.
class AiRouter {
  AiRouter({
    required String supabaseUrl,
    required String supabaseAnonKey,
  })  : _supabaseUrl = supabaseUrl,
        _supabaseAnonKey = supabaseAnonKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  final String _supabaseUrl;
  final String _supabaseAnonKey;
  final Dio _dio;

  String _edgeFnUrl(String slug) =>
      '$_supabaseUrl/functions/v1/$slug';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
      };

  // ── Non-streaming request ────────────────────────────────────────────────

  Future<AiResponse> request(AiRequest req) async {
    try {
      final body = {
        'messages': req.messages.map((m) => m.toJson()).toList(),
        'provider': req.resolvedProvider.name,
        if (req.systemPrompt != null) 'system': req.systemPrompt,
        if (req.maxTokens != null) 'max_tokens': req.maxTokens,
        if (req.examId != null) 'exam_id': req.examId,
        'stream': false,
      };

      final response = await _dio.post(
        _edgeFnUrl(req.edgeFunctionSlug),
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );

      final data = response.data as Map<String, dynamic>;
      return AiResponse(
        content: data['content'] as String? ?? '',
        provider: req.resolvedProvider,
        feature: req.feature,
        tokensUsed: data['tokens_used'] as int? ?? 0,
      );
    } on DioException catch (e) {
      return AiResponse(
        content: '',
        provider: req.resolvedProvider,
        feature: req.feature,
        tokensUsed: 0,
        error: _dioError(e),
      );
    } catch (e) {
      return AiResponse(
        content: '',
        provider: req.resolvedProvider,
        feature: req.feature,
        tokensUsed: 0,
        error: e.toString(),
      );
    }
  }

  // ── Streaming request (SSE) ───────────────────────────────────────────────

  Stream<String> stream(AiRequest req) async* {
    final body = {
      'messages': req.messages.map((m) => m.toJson()).toList(),
      'provider': req.resolvedProvider.name,
      if (req.systemPrompt != null) 'system': req.systemPrompt,
      if (req.maxTokens != null) 'max_tokens': req.maxTokens,
      if (req.examId != null) 'exam_id': req.examId,
      'stream': true,
    };

    try {
      final response = await _dio.post(
        _edgeFnUrl(req.edgeFunctionSlug),
        data: jsonEncode(body),
        options: Options(
          headers: {..._headers, 'Accept': 'text/event-stream'},
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.last;

        for (final line in lines.sublist(0, lines.length - 1)) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = json['delta'] as String? ??
                  (json['choices'] as List?)
                      ?.firstOrNull?['delta']?['content'] as String? ??
                  '';
              if (delta.isNotEmpty) yield delta;
            } catch (_) {
              // skip malformed SSE lines
            }
          }
        }
      }
    } on DioException catch (e) {
      yield '\n\n[Error: ${_dioError(e)}]';
    }
  }

  String _dioError(DioException e) {
    if (e.response != null) {
      return 'API error ${e.response!.statusCode}: ${e.response!.data}';
    }
    return e.message ?? 'Network error';
  }
}
