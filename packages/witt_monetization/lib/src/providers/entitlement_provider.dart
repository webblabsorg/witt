import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entitlement.dart';

// ── Entitlement state ─────────────────────────────────────────────────────

class EntitlementNotifier extends Notifier<Entitlement> {
  @override
  Entitlement build() => Entitlement.free;

  /// Called after a successful purchase or restore.
  void grant({
    required SubscriptionPlan plan,
    required SubscriptionStatus status,
    DateTime? expiresAt,
    DateTime? trialEndsAt,
    List<String> unlockedExamIds = const [],
    bool isLifetime = false,
  }) {
    state = Entitlement(
      plan: plan,
      status: status,
      unlockedExamIds: unlockedExamIds,
      expiresAt: expiresAt,
      trialEndsAt: trialEndsAt,
      isLifetime: isLifetime,
    );
  }

  /// Unlock a single exam (exam-specific purchase).
  void unlockExam(String examId) {
    if (state.unlockedExamIds.contains(examId)) return;
    state = state.copyWith(
      unlockedExamIds: [...state.unlockedExamIds, examId],
    );
  }

  /// Revoke (e.g. subscription expired or cancelled).
  void revoke() {
    state = state.copyWith(
      status: SubscriptionStatus.expired,
    );
  }

  /// Reset to free (e.g. on sign-out).
  void reset() {
    state = Entitlement.free;
  }

  /// Simulate a purchase for dev/testing.
  void devGrantPremium() {
    grant(
      plan: SubscriptionPlan.premiumMonthly,
      status: SubscriptionStatus.active,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }
}

final entitlementProvider =
    NotifierProvider<EntitlementNotifier, Entitlement>(
        EntitlementNotifier.new);

// ── Convenience derived providers ─────────────────────────────────────────

final isPaidProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).isPremium;
});

final isExamUnlockedByEntitlementProvider =
    Provider.family<bool, String>((ref, examId) {
  return ref.watch(entitlementProvider).isExamUnlocked(examId);
});

// ── Purchase flow state ───────────────────────────────────────────────────

enum PurchaseFlowStatus { idle, loading, success, error, cancelled }

class PurchaseFlowState {
  const PurchaseFlowState({
    required this.status,
    this.productId,
    this.errorMessage,
  });

  final PurchaseFlowStatus status;
  final String? productId;
  final String? errorMessage;

  PurchaseFlowState copyWith({
    PurchaseFlowStatus? status,
    String? productId,
    String? errorMessage,
  }) =>
      PurchaseFlowState(
        status: status ?? this.status,
        productId: productId ?? this.productId,
        errorMessage: errorMessage,
      );

  static const idle = PurchaseFlowState(status: PurchaseFlowStatus.idle);
}

class PurchaseFlowNotifier extends Notifier<PurchaseFlowState> {
  @override
  PurchaseFlowState build() => PurchaseFlowState.idle;

  /// Initiates a purchase. In production this calls the Subrail SDK.
  /// Currently implemented as a simulated flow for Phase 3.
  Future<void> purchase(PurchaseProduct product) async {
    state = state.copyWith(
      status: PurchaseFlowStatus.loading,
      productId: product.id,
    );

    // Simulate network delay for purchase flow
    await Future.delayed(const Duration(seconds: 2));

    // In production: call Subrail SDK here and await result.
    // On success, grant entitlement. On failure, set error.
    // For now: simulate success.
    ref.read(entitlementProvider.notifier).grant(
          plan: product.plan,
          status: SubscriptionStatus.trial,
          trialEndsAt: DateTime.now().add(const Duration(days: 7)),
          expiresAt: product.plan == SubscriptionPlan.premiumYearly
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 30)),
        );

    state = state.copyWith(
      status: PurchaseFlowStatus.success,
      productId: product.id,
    );
  }

  /// Restore previous purchases.
  Future<void> restore() async {
    state = state.copyWith(status: PurchaseFlowStatus.loading);
    await Future.delayed(const Duration(seconds: 1));
    // In production: call Subrail SDK restore here.
    // For now: no-op (no prior purchase to restore in dev).
    state = PurchaseFlowState.idle;
  }

  /// Unlock a single exam.
  Future<void> purchaseExam(String examId, double priceUsd) async {
    state = state.copyWith(
      status: PurchaseFlowStatus.loading,
      productId: 'exam_$examId',
    );
    await Future.delayed(const Duration(seconds: 2));
    ref.read(entitlementProvider.notifier).unlockExam(examId);
    state = state.copyWith(status: PurchaseFlowStatus.success);
  }

  void reset() => state = PurchaseFlowState.idle;
}

final purchaseFlowProvider =
    NotifierProvider<PurchaseFlowNotifier, PurchaseFlowState>(
        PurchaseFlowNotifier.new);

// ── Available products catalog ────────────────────────────────────────────

final productsProvider = Provider<List<PurchaseProduct>>((ref) {
  return const [
    PurchaseProduct(
      id: 'witt_premium_monthly',
      title: 'Witt Premium Monthly',
      description: 'Unlimited AI, all features, 7-day free trial',
      priceUsd: 9.99,
      localizedPrice: '\$9.99',
      currencyCode: 'USD',
      plan: SubscriptionPlan.premiumMonthly,
    ),
    PurchaseProduct(
      id: 'witt_premium_yearly',
      title: 'Witt Premium Yearly',
      description: 'Best value — save 50%, all features',
      priceUsd: 59.99,
      localizedPrice: '\$59.99',
      currencyCode: 'USD',
      plan: SubscriptionPlan.premiumYearly,
    ),
  ];
});
