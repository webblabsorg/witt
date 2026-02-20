import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../../core/translation/live_text.dart';

class OnboardingIntroScreen extends ConsumerWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final startOnboardingLabel =
        ref.watch(liveTextProvider('Start onboarding')).valueOrNull ??
        'Start onboarding';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: WittSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: WittSpacing.xl),
              LiveText(
                'Welcome to your personal onboarding',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: WittSpacing.md),
              LiveText(
                'In less than two minutes, we will build a study path that matches your goals.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? WittColors.textSecondaryDark
                      : WittColors.textSecondary,
                ),
              ),
              const SizedBox(height: WittSpacing.xxxl),
              _BenefitTile(
                icon: Icons.tune_rounded,
                title: 'Personalized exam prep',
                subtitle:
                    'Get recommendations based on your role, country, and target exams.',
              ),
              const SizedBox(height: WittSpacing.md),
              _BenefitTile(
                icon: Icons.route_rounded,
                title: 'Tailored study plan',
                subtitle:
                    'Set your schedule and build realistic milestones from day one.',
              ),
              const SizedBox(height: WittSpacing.md),
              _BenefitTile(
                icon: Icons.timeline_rounded,
                title: 'Exam tracking',
                subtitle:
                    'Track exam dates, monitor target scores, and stay ready every week.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: WittButton(
                  label: startOnboardingLabel,
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

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(WittSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? WittColors.surfaceVariantDark
            : WittColors.surfaceVariant,
        borderRadius: WittSpacing.borderRadiusLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WittColors.primaryContainer,
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: Icon(
              icon,
              color: WittColors.primary,
              size: WittSpacing.iconMd,
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiveText(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: WittSpacing.xs),
                LiveText(
                  subtitle,
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
