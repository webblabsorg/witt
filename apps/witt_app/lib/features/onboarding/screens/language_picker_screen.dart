import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/translation/live_text.dart';
import '../../../core/translation/ml_kit_languages.dart';
import '../onboarding_state.dart';

class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String _selected = 'en';

  static const _preferredOrder = <String>[
    'en',
    'es',
    'fr',
    'ar',
    'pt',
    'hi',
    'zh',
    'ru',
    'de',
    'ja',
    'ko',
    'sw',
    'bn',
    'tr',
    'it',
  ];

  String _toLocaleCode(String code) => code.split('-').first;

  @override
  void initState() {
    super.initState();
    // Prefer the persisted locale (source of truth for current app language);
    // fall back to onboarding language if locale not yet set.
    final localeCode = ref.read(localeProvider).languageCode;
    final onboardingLang = ref.read(onboardingProvider).language;
    // Match locale code against picker list; fall back to onboarding language.
    final matchedByLocale = _languages.any(
      (l) => l.code == localeCode || l.code.split('-').first == localeCode,
    );
    _selected = matchedByLocale ? localeCode : onboardingLang;
  }

  static final _languages = () {
    final ranked = mlKitLanguages
        .map(
          (lang) => _Language(
            lang.code,
            lang.code == 'en' ? 'English' : lang.nativeName,
            lang.code == 'en' ? 'English' : lang.englishName,
          ),
        )
        .toList(growable: false);

    ranked.sort((a, b) {
      final aRank = _preferredOrder.indexOf(a.code);
      final bRank = _preferredOrder.indexOf(b.code);
      final aIdx = aRank == -1 ? 999 : aRank;
      final bIdx = bRank == -1 ? 999 : bRank;
      if (aIdx != bIdx) return aIdx.compareTo(bIdx);
      return a.englishName.compareTo(b.englishName);
    });
    return ranked;
  }();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final continueLabel =
        ref.watch(liveTextProvider('Continue')).valueOrNull ?? 'Continue';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.xxl,
                WittSpacing.lg,
                WittSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiveText(
                    'Choose your language',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  LiveText(
                    'You can change this later in Settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: WittSpacing.pagePadding,
                itemCount: _languages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: WittSpacing.sm),
                itemBuilder: (context, i) {
                  final lang = _languages[i];
                  final isSelected = _selected == lang.code;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selected = lang.code);
                      await ref
                          .read(localeProvider.notifier)
                          .setLocale(_toLocaleCode(lang.code));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: WittSpacing.lg,
                        vertical: WittSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? WittColors.primaryContainer
                            : (isDark
                                  ? WittColors.surfaceVariantDark
                                  : WittColors.surfaceVariant),
                        borderRadius: WittSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isSelected
                              ? WittColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? WittColors.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  lang.englishName,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: WittColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                WittSpacing.xxl,
              ),
              child: WittButton(
                label: continueLabel,
                onPressed: () async {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(_toLocaleCode(_selected));
                  await ref
                      .read(onboardingProvider.notifier)
                      .setLanguage(_selected);
                  if (context.mounted) {
                    context.go('/onboarding/intro');
                  }
                },
                isFullWidth: true,
                size: WittButtonSize.lg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Language {
  const _Language(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;
}
