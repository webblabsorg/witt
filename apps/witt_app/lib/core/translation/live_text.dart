import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import 'ml_kit_translate_client.dart';

class _UiTextRequest {
  const _UiTextRequest(this.text, this.targetLang);

  final String text;
  final String targetLang;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UiTextRequest &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          targetLang == other.targetLang;

  @override
  int get hashCode => text.hashCode ^ targetLang.hashCode;
}

final _uiTextProvider = FutureProvider.autoDispose
    .family<String, _UiTextRequest>((ref, request) async {
      final input = request.text.trim();
      if (input.isEmpty) return request.text;

      final target = request.targetLang.toLowerCase();
      if (target == 'en') return request.text;

      try {
        return await MlKitTranslateClient.instance.translate(
          text: request.text,
          sourceLang: 'en',
          targetLang: target,
        );
      } catch (_) {
        return request.text;
      }
    });

final liveTextProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  text,
) async {
  final localeCode = ref.watch(localeProvider).languageCode.toLowerCase();
  return ref.watch(_uiTextProvider(_UiTextRequest(text, localeCode)).future);
});

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
    final localeCode = ref.watch(localeProvider).languageCode.toLowerCase();
    final translated = ref.watch(
      _uiTextProvider(_UiTextRequest(text, localeCode)),
    );

    return Text(
      translated.valueOrNull ?? text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
