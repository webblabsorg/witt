import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../onboarding/onboarding_state.dart';

class FreeTrialScreen extends ConsumerWidget {
  const FreeTrialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.lg,
                vertical: WittSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      await ref.read(onboardingProvider.notifier).complete();
                      if (context.mounted) context.go('/home');
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? WittColors.surfaceVariantDark
                          : WittColors.surfaceVariant,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('RESTORE')),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'HOW YOUR FREE TRIAL WORKS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: isDark
                            ? WittColors.textSecondaryDark
                            : WittColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: WittSpacing.xxxl),

                    // Timeline
                    _TimelineStep(
                      dotColor: WittColors.success,
                      title: 'Today',
                      subtitle:
                          'Get full access to all Premium features and tools',
                      isFirst: true,
                    ),
                    _TimelineStep(
                      dotColor: WittColors.secondary,
                      title: 'In 6 days',
                      subtitle: "Get reminded about your trial's expiration",
                    ),
                    _TimelineStep(
                      dotColor: WittColors.primary,
                      title: 'In 7 days',
                      subtitle: 'You will be charged — cancel any time earlier',
                      isLast: true,
                    ),

                    const SizedBox(height: WittSpacing.xxxl),

                    // Price summary
                    Text(
                      '7-day free trial',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    Text(
                      'Then \$59.99/year (\$5.00/month)',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? WittColors.textSecondaryDark
                            : WittColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: WittSpacing.xxxl),

                    // CTA
                    WittButton(
                      label: 'Start my Free Trial',
                      onPressed: () async {
                        await ref.read(onboardingProvider.notifier).complete();
                        if (context.mounted) context.go('/home');
                      },
                      isFullWidth: true,
                      size: WittButtonSize.lg,
                      gradient: WittColors.primaryGradient,
                    ),
                    const SizedBox(height: WittSpacing.lg),

                    // Legal
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? WittColors.textTertiaryDark
                              : WittColors.textTertiary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By subscribing, you agree to our\n',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: WittColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Terms of Use',
                            style: const TextStyle(
                              color: WittColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final Color dotColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? WittColors.outlineDark : WittColors.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 20, color: lineColor),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : WittSpacing.xxl,
                top: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
