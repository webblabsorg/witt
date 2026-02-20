// ML Kit dynamic translation disabled for English-only US launch.
// Re-enable the full implementation below when multi-language support is restored.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
// import 'ml_kit_translate_client.dart'; // Re-enable for multi-language support

// ── Translation providers (disabled — English only) ───────────────────────
// Re-enable when multi-language support is restored:
//
// class _UiTextRequest { ... }
//
// final _uiTextProvider = FutureProvider.autoDispose
//     .family<String, _UiTextRequest>((ref, request) async {
//       if (request.targetLang == 'en') return request.text;
//       return await MlKitTranslateClient.instance.translate(
//         text: request.text, sourceLang: 'en', targetLang: request.targetLang,
//       );
//     });

/// Pass-through provider — always returns the original English text.
final liveTextProvider = Provider.autoDispose
    .family<AsyncValue<String>, String>((ref, text) => AsyncValue.data(text));

/// LiveText widget — renders text as-is (English only for US launch).
/// When multi-language support is restored, swap back to the ML Kit
/// FutureProvider-based implementation.
class LiveText extends ConsumerWidget {
  const LiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Locale watched but translation disabled — always English.
    ref.watch(localeProvider);
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
