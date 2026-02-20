import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../../core/translation/live_text.dart';

class OnboardingIntroScreen extends ConsumerWidget {
  const OnboardingIntroScreen({super.key});

  static const _features = [
    _Feature(
      icon: Icons.auto_awesome_rounded,
      color: WittColors.accent,
      title: 'AI Tutor & Homework Help',
      subtitle: 'Ask Sage anything — step-by-step explanations, 24/7.',
    ),
    _Feature(
      icon: Icons.style_rounded,
      color: WittColors.primary,
      title: 'Flashcards & Spaced Repetition',
      subtitle: 'Create, share, and master decks with smart scheduling.',
    ),
    _Feature(
      icon: Icons.school_rounded,
      color: WittColors.success,
      title: 'Exam Prep & Mock Tests',
      subtitle: '150+ exams worldwide with adaptive practice.',
    ),
    _Feature(
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFFF6B35),
      title: 'Study Games & Challenges',
      subtitle: 'Word Duel, Quiz Royale, and 7 more learning games.',
    ),
    _Feature(
      icon: Icons.calendar_today_rounded,
      color: WittColors.secondary,
      title: 'Study Planner & Progress',
      subtitle: 'Smart schedules, streaks, XP, and analytics.',
    ),
    _Feature(
      icon: Icons.note_alt_rounded,
      color: WittColors.textSecondary,
      title: 'Notes, Lectures & Vocabulary',
      subtitle: 'Capture, summarise, and organise everything you learn.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final btnLabel =
        ref.watch(liveTextProvider("Let's go")).valueOrNull ?? "Let's go";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: WittSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: WittSpacing.xl),
              LiveText(
                "Let's personalise Witt for you",
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: WittSpacing.sm),
              LiveText(
                'Answer a few quick questions so we can set up the tools you need — whether that\'s exam prep, flashcards, study planning, or all of the above.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? WittColors.textSecondaryDark
                      : WittColors.textSecondary,
                ),
              ),
              const SizedBox(height: WittSpacing.xxl),
              Expanded(
                child: ListView.separated(
                  itemCount: _features.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: WittSpacing.sm),
                  itemBuilder: (_, i) => _FeatureTile(feature: _features[i]),
                ),
              ),
              const SizedBox(height: WittSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: WittButton(
                  label: btnLabel,
                  onPressed: () => context.go('/onboarding/wizard/1'),
                  size: WittButtonSize.lg,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(height: WittSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WittSpacing.lg,
        vertical: WittSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? WittColors.surfaceVariantDark
            : WittColors.surfaceVariant,
        borderRadius: WittSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withAlpha(26),
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiveText(feature.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                LiveText(
                  feature.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? WittColors.textSecondaryDark
                        : WittColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
