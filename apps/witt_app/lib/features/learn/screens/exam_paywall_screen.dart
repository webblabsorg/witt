import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../providers/exam_providers.dart';

class ExamPaywallScreen extends ConsumerWidget {
  const ExamPaywallScreen({
    super.key,
    required this.examId,
    required this.questionsUsed,
    required this.onDismiss,
  });

  final String examId;
  final int questionsUsed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exam = ref.watch(examByIdProvider(examId));
    if (exam == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WittSpacing.lg),
          child: Column(
            children: [
              // ── Close button ───────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
              ),

              const Spacer(),

              // ── Lock icon ──────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: WittColors.premiumGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: WittSpacing.lg),

              // ── Headline ───────────────────────────────────────────────
              Text(
                'You\'ve used your ${exam.freeQuestionCount} free questions!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WittSpacing.sm),
              Text(
                'Unlock unlimited ${exam.name} practice questions, adaptive AI drills, and full mock tests.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: WittColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: WittSpacing.xl),

              // ── Feature list ───────────────────────────────────────────
              ..._features.map((f) => _FeatureRow(icon: f.$1, label: f.$2)),

              const SizedBox(height: WittSpacing.xl),

              // ── Pricing cards ──────────────────────────────────────────
              Row(
                children: [
                  _PriceCard(
                    label: 'Weekly',
                    price: exam.weeklyPriceUsd,
                    period: '/week',
                    isHighlighted: false,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _PriceCard(
                    label: 'Monthly',
                    price: exam.monthlyPriceUsd,
                    period: '/month',
                    isHighlighted: true,
                    badge: 'POPULAR',
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _PriceCard(
                    label: 'Yearly',
                    price: exam.yearlyPriceUsd,
                    period: '/year',
                    isHighlighted: false,
                    badge: 'BEST VALUE',
                  ),
                ],
              ),

              const SizedBox(height: WittSpacing.lg),

              // ── CTA ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: WittButton(
                  label:
                      'Unlock ${exam.name} — \$${exam.monthlyPriceUsd.toStringAsFixed(2)}/mo',
                  onPressed: () {
                    // Phase 3: wire to Subrail purchase flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchase flow coming in Phase 3'),
                      ),
                    );
                  },
                  gradient: WittColors.premiumGradient,
                ),
              ),
              const SizedBox(height: WittSpacing.sm),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Maybe later',
                  style: TextStyle(color: WittColors.textTertiary),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  static const List<(IconData, String)> _features = [
    (Icons.all_inclusive, 'Unlimited practice questions'),
    (Icons.psychology, 'AI-adaptive difficulty'),
    (Icons.quiz, 'Full-length mock tests'),
    (Icons.analytics, 'Detailed performance analytics'),
    (Icons.offline_bolt, 'Offline access'),
  ];
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: WittColors.success),
          const SizedBox(width: WittSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.label,
    required this.price,
    required this.period,
    required this.isHighlighted,
    this.badge,
  });

  final String label;
  final double price;
  final String period;
  final bool isHighlighted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WittSpacing.sm,
              vertical: WittSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? WittColors.primaryContainer
                  : WittColors.surfaceVariant,
              borderRadius: BorderRadius.circular(WittSpacing.sm),
              border: Border.all(
                color: isHighlighted ? WittColors.primary : WittColors.outline,
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isHighlighted
                        ? WittColors.primary
                        : WittColors.textPrimary,
                  ),
                ),
                Text(
                  period,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: WittColors.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
