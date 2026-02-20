import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            WittSpacing.lg,
            WittSpacing.xxl,
            WittSpacing.lg,
            WittSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Unlock the full Witt experience',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: WittSpacing.sm),
              Text(
                'Choose the plan that works for you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? WittColors.textSecondaryDark
                      : WittColors.textSecondary,
                ),
              ),
              const SizedBox(height: WittSpacing.xxxl),

              // Free plan
              _PlanCard(
                icon: '✨',
                title: 'FREE PLAN',
                titleColor: WittColors.textPrimary,
                features: const [
                  '10 Sage AI messages/day',
                  '10–15 free questions per exam',
                  'Basic flashcards & notes',
                  'Daily brain challenge',
                  'Limited games & community',
                ],
                ctaLabel: 'Continue with Free',
                ctaVariant: WittButtonVariant.outline,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: WittSpacing.lg),

              // Premium Monthly
              _PlanCard(
                icon: '🔥',
                title: 'PREMIUM MONTHLY',
                price: '\$9.99/mo',
                titleColor: WittColors.primary,
                isHighlighted: false,
                badge: '7-day free trial',
                features: const [
                  'Unlimited Sage AI (GPT-4o + dictation)',
                  'Unlimited flashcards, notes & quizzes',
                  'AI homework helper & lecture capture',
                  'Full analytics & study planner',
                  'Multiplayer games & full community',
                  'Ad-free + cross-device sync',
                ],
                ctaLabel: 'Start Free Trial',
                onTap: () => context.go('/onboarding/feature-comparison'),
              ),
              const SizedBox(height: WittSpacing.lg),

              // Premium Yearly
              _PlanCard(
                icon: '💎',
                title: 'PREMIUM YEARLY',
                price: '\$59.99/yr',
                subPrice: '\$5.00/mo',
                titleColor: WittColors.primaryDark,
                isHighlighted: true,
                badge: 'SAVE 50% — BEST VALUE',
                badgeColor: WittColors.secondary,
                features: const [
                  'Everything in Premium Monthly',
                  'Billed annually',
                ],
                ctaLabel: 'Subscribe Yearly',
                onTap: () => context.go('/onboarding/free-trial'),
              ),
              const SizedBox(height: WittSpacing.xxl),

              // Footer links
              Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Restore Purchases'),
                    ),
                    Text(
                      'Exam-specific plans available inside the app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? WittColors.textTertiaryDark
                            : WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.features,
    required this.ctaLabel,
    required this.onTap,
    this.price,
    this.subPrice,
    this.titleColor,
    this.isHighlighted = false,
    this.badge,
    this.badgeColor,
    this.ctaVariant = WittButtonVariant.primary,
  });

  final String icon;
  final String title;
  final String? price;
  final String? subPrice;
  final Color? titleColor;
  final bool isHighlighted;
  final String? badge;
  final Color? badgeColor;
  final List<String> features;
  final String ctaLabel;
  final VoidCallback onTap;
  final WittButtonVariant ctaVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WittColors.surfaceVariantDark : WittColors.surface,
        borderRadius: WittSpacing.borderRadiusXl,
        border: Border.all(
          color: isHighlighted
              ? WittColors.primary
              : (isDark ? WittColors.outlineDark : WittColors.outline),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: WittColors.primary.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(WittSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.md,
                  vertical: WittSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: (badgeColor ?? WittColors.primary).withAlpha(26),
                  borderRadius: WittSpacing.borderRadiusFull,
                  border: Border.all(
                    color: badgeColor ?? WittColors.primary,
                    width: 1,
                  ),
                ),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor ?? WittColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: WittSpacing.md),
            ],

            // Title row
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: WittSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (price != null) ...[
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subPrice != null)
                        Text(
                          subPrice!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? WittColors.textSecondaryDark
                                : WittColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: WittSpacing.lg),

            // Features
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: WittSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: WittColors.success, size: 18),
                    const SizedBox(width: WittSpacing.sm),
                    Expanded(
                      child: Text(f, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: WittSpacing.lg),

            // CTA
            WittButton(
              label: ctaLabel,
              onPressed: onTap,
              variant: ctaVariant,
              isFullWidth: true,
              gradient: ctaVariant == WittButtonVariant.primary
                  ? WittColors.primaryGradient
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
