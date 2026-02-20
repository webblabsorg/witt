import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../../core/currency/currency_provider.dart';

class FeatureComparisonScreen extends ConsumerWidget {
  const FeatureComparisonScreen({super.key});

  static const _features = [
    _Feature('🤖', 'Sage AI (Unlimited)'),
    _Feature('🎙️', 'Sage Dictation'),
    _Feature('📸', 'AI Homework Helper'),
    _Feature('📝', 'Unlimited Notes & Decks'),
    _Feature('🧠', 'AI Study Planner'),
    _Feature('🎤', 'Lecture AI Summarization'),
    _Feature('📊', 'Full Analytics & Trends'),
    _Feature('🎮', 'Multiplayer Games'),
    _Feature('👥', 'Full Community Access'),
    _Feature('🔄', 'Cross-Device Sync'),
    _Feature('🚫', 'Ad-Free Experience'),
    _Feature('❄️', 'Streak Freeze'),
    _Feature('📦', 'Unlimited Offline Packs'),
    _Feature('🎯', 'Priority Support'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthlyLocalized = ref.watch(localizedPriceProvider(9.99));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.lg,
                vertical: WittSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.push('/onboarding/free-trial'),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? WittColors.surfaceVariantDark
                          : WittColors.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  0,
                  WittSpacing.lg,
                  WittSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(WittSpacing.xxl),
                      decoration: BoxDecoration(
                        gradient: WittColors.premiumGradient,
                        borderRadius: WittSpacing.borderRadiusXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Go beyond your limits',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: WittSpacing.sm),
                          Text(
                            'Upgrade to Premium for ${monthlyLocalized.formatted}/mo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WittSpacing.xxl),

                    Text('What you get', style: theme.textTheme.titleLarge),
                    const SizedBox(height: WittSpacing.lg),

                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WittSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: Text(
                                'Free',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark
                                      ? WittColors.textSecondaryDark
                                      : WittColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                'Premium',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: WittColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    const Divider(),

                    // Feature rows
                    ..._features.map((f) => _FeatureRow(feature: f)),

                    const SizedBox(height: WittSpacing.xxxl),

                    // CTA
                    WittButton(
                      label: 'Upgrade to Premium',
                      onPressed: () => context.push('/onboarding/free-trial'),
                      isFullWidth: true,
                      size: WittButtonSize.lg,
                      gradient: WittColors.premiumGradient,
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    Center(
                      child: Text(
                        'Total price: ${monthlyLocalized.formatted}/month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? WittColors.textSecondaryDark
                              : WittColors.textSecondary,
                        ),
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

class _Feature {
  const _Feature(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: WittSpacing.md,
        horizontal: WittSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(feature.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(feature.label, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Icon(
                Icons.close_rounded,
                color: isDark
                    ? WittColors.textTertiaryDark
                    : WittColors.textTertiary,
                size: 18,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: const Icon(
                Icons.check_rounded,
                color: WittColors.success,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
