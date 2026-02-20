import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../onboarding_state.dart';

class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String _selected = 'en';

  static const _languages = [
    _Language('en', '🇺🇸', 'English (US)', 'English'),
    _Language('en-GB', '🇬🇧', 'English (UK)', 'English'),
    _Language('es', '🇪🇸', 'Español', 'Spanish'),
    _Language('fr', '🇫🇷', 'Français', 'French'),
    _Language('de', '🇩🇪', 'Deutsch', 'German'),
    _Language('pt', '🇵🇹', 'Português', 'Portuguese'),
    _Language('it', '🇮🇹', 'Italiano', 'Italian'),
    _Language('nl', '🇳🇱', 'Nederlands', 'Dutch'),
    _Language('ru', '🇷🇺', 'Русский', 'Russian'),
    _Language('pl', '🇵🇱', 'Polski', 'Polish'),
    _Language('tr', '🇹🇷', 'Türkçe', 'Turkish'),
    _Language('ar', '🇸🇦', 'العربية', 'Arabic'),
    _Language('hi', '🇮🇳', 'हिन्दी', 'Hindi'),
    _Language('bn', '🇧🇩', 'বাংলা', 'Bengali'),
    _Language('zh-CN', '🇨🇳', '中文（简体）', 'Chinese Simplified'),
    _Language('zh-TW', '🇹🇼', '中文（繁體）', 'Chinese Traditional'),
    _Language('ja', '🇯🇵', '日本語', 'Japanese'),
    _Language('ko', '🇰🇷', '한국어', 'Korean'),
    _Language('id', '🇮🇩', 'Bahasa Indonesia', 'Indonesian'),
    _Language('vi', '🇻🇳', 'Tiếng Việt', 'Vietnamese'),
    _Language('sw', '🇰🇪', 'Kiswahili', 'Swahili'),
  ];

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
                  Text('Choose your language',
                      style: theme.textTheme.headlineSmall),
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
                    onTap: () => setState(() => _selected = lang.code),
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
                          Text(lang.flag,
                              style: const TextStyle(fontSize: 24)),
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
                            const Icon(Icons.check_circle_rounded,
                                color: WittColors.primary, size: 20),
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
