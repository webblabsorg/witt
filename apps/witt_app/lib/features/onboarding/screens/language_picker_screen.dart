import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../../core/providers/locale_provider.dart';
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

  String _toLocaleCode(String code) => code.split('-').first;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingProvider).language;
  }

  static final _languages = mlKitLanguages
      .map(
        (lang) =>
            _Language(lang.code, lang.flag, lang.nativeName, lang.englishName),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  Text(
                    'Choose your language',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  Text(
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
                          Text(lang.flag, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: WittSpacing.md),
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
                label: 'Continue',
                onPressed: () async {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(_toLocaleCode(_selected));
                  await ref
                      .read(onboardingProvider.notifier)
                      .setLanguage(_selected);
                  if (context.mounted) {
                    context.go('/onboarding/wizard/1');
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
  const _Language(this.code, this.flag, this.nativeName, this.englishName);

  final String code;
  final String flag;
  final String nativeName;
  final String englishName;
}
