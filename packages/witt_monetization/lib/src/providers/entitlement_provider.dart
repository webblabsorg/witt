import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subrail_flutter/subrail_flutter.dart';
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
    state = state.copyWith(unlockedExamIds: [...state.unlockedExamIds, examId]);
  }

  /// Revoke (e.g. subscription expired or cancelled).
  void revoke() {
    state = state.copyWith(status: SubscriptionStatus.expired);
  }

  /// Reset to free (e.g. on sign-out).
  void reset() {
    state = Entitlement.free;
  }

  /// Hydrates entitlement from Subrail on app start / auth change.
  /// Fetches live CustomerInfo and applies it — ensures cross-device consistency.
  Future<void> hydrateFromSubrail() async {
    try {
      final info = await Subrail.getCustomerInfo();
      final active = info.entitlements.active;

      SubscriptionPlan plan = SubscriptionPlan.free;
      SubscriptionStatus status = SubscriptionStatus.none;
      DateTime? expiresAt;
      DateTime? trialEndsAt;
      bool isLifetime = false;

      if (active.containsKey('premium_yearly') ||
          active.containsKey('witt_premium_yearly')) {
        plan = SubscriptionPlan.premiumYearly;
      } else if (active.containsKey('premium_monthly') ||
          active.containsKey('witt_premium_monthly')) {
        plan = SubscriptionPlan.premiumMonthly;
      } else if (active.containsKey('lifetime')) {
        plan = SubscriptionPlan.premiumYearly;
        isLifetime = true;
      }

      if (plan != SubscriptionPlan.free || isLifetime) {
        final entitlement = active.values.isNotEmpty
            ? active.values.first
            : null;
        if (entitlement != null) {
          status = entitlement.periodType == PeriodType.trial
              ? SubscriptionStatus.trial
              : SubscriptionStatus.active;
          if (entitlement.expirationDate != null) {
            expiresAt = DateTime.tryParse(entitlement.expirationDate!);
          }
          if (entitlement.periodType == PeriodType.trial &&
              entitlement.expirationDate != null) {
            trialEndsAt = DateTime.tryParse(entitlement.expirationDate!);
          }
        } else {
          status = SubscriptionStatus.active;
        }
        grant(
          plan: plan,
          status: status,
          expiresAt: expiresAt,
          trialEndsAt: trialEndsAt,
          isLifetime: isLifetime,
        );
      } else {
        // No active entitlement — ensure state reflects free
        state = Entitlement.free;
      }
    } catch (_) {
      // Network failure — retain current local state, do not downgrade
    }
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

final entitlementProvider = NotifierProvider<EntitlementNotifier, Entitlement>(
  EntitlementNotifier.new,
);

// ── Convenience derived providers ─────────────────────────────────────────

final isPaidProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).isPremium;
});

final isExamUnlockedByEntitlementProvider = Provider.family<bool, String>((
  ref,
  examId,
) {
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
  }) => PurchaseFlowState(
    status: status ?? this.status,
    productId: productId ?? this.productId,
    errorMessage: errorMessage,
  );

  static const idle = PurchaseFlowState(status: PurchaseFlowStatus.idle);
}

class PurchaseFlowNotifier extends Notifier<PurchaseFlowState> {
  @override
  PurchaseFlowState build() => PurchaseFlowState.idle;

  /// Initiates a purchase via the Subrail SDK.
  Future<void> purchase(PurchaseProduct product) async {
    state = state.copyWith(
      status: PurchaseFlowStatus.loading,
      productId: product.id,
    );
    try {
      final products = await Subrail.getProducts([product.id]);
      if (products.isEmpty) {
        state = state.copyWith(
          status: PurchaseFlowStatus.error,
          errorMessage: 'Product not found: ${product.id}',
        );
        return;
      }
      final result = await Subrail.purchaseProduct(products.first);
      _applyCustomerInfo(result.customerInfo, product.plan);
      state = state.copyWith(
        status: PurchaseFlowStatus.success,
        productId: product.id,
      );
    } catch (e) {
      state = state.copyWith(
        status: PurchaseFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Restore previous purchases via the Subrail SDK.
  Future<void> restore() async {
    state = state.copyWith(status: PurchaseFlowStatus.loading);
    try {
      final customerInfo = await Subrail.restorePurchases();
      _applyCustomerInfo(customerInfo, null);
      state = PurchaseFlowState.idle;
    } catch (e) {
      state = state.copyWith(
        status: PurchaseFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Unlock a single exam via the Subrail SDK.
  Future<void> purchaseExam(String examId, double priceUsd) async {
    final productId = 'exam_$examId';
    state = state.copyWith(
      status: PurchaseFlowStatus.loading,
      productId: productId,
    );
    try {
      final products = await Subrail.getProducts([productId]);
      if (products.isEmpty) {
        state = state.copyWith(
          status: PurchaseFlowStatus.error,
          errorMessage: 'Exam product not found: $productId',
        );
        return;
      }
      await Subrail.purchaseProduct(products.first);
      ref.read(entitlementProvider.notifier).unlockExam(examId);
      state = state.copyWith(status: PurchaseFlowStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: PurchaseFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = PurchaseFlowState.idle;

  /// Maps a Subrail [CustomerInfo] response to the app's [Entitlement] model
  /// and grants it via [EntitlementNotifier].
  void _applyCustomerInfo(CustomerInfo info, SubscriptionPlan? hintPlan) {
    final active = info.entitlements.active;

    // Determine plan from active entitlement identifiers
    SubscriptionPlan plan = SubscriptionPlan.free;
    SubscriptionStatus status = SubscriptionStatus.none;
    DateTime? expiresAt;
    DateTime? trialEndsAt;
    bool isLifetime = false;

    if (active.containsKey('premium_yearly') ||
        active.containsKey('witt_premium_yearly')) {
      plan = SubscriptionPlan.premiumYearly;
    } else if (active.containsKey('premium_monthly') ||
        active.containsKey('witt_premium_monthly')) {
      plan = SubscriptionPlan.premiumMonthly;
    } else if (active.containsKey('lifetime')) {
      plan = SubscriptionPlan.premiumYearly;
      isLifetime = true;
    } else if (hintPlan != null && hintPlan != SubscriptionPlan.free) {
      plan = hintPlan;
    }

    if (plan != SubscriptionPlan.free || isLifetime) {
      final entitlement = active.values.isNotEmpty ? active.values.first : null;
      if (entitlement != null) {
        status = entitlement.periodType == PeriodType.trial
            ? SubscriptionStatus.trial
            : SubscriptionStatus.active;
        if (entitlement.expirationDate != null) {
          expiresAt = DateTime.tryParse(entitlement.expirationDate!);
        }
        if (entitlement.periodType == PeriodType.trial &&
            entitlement.expirationDate != null) {
          trialEndsAt = DateTime.tryParse(entitlement.expirationDate!);
        }
      } else {
        status = SubscriptionStatus.active;
      }
    }

    ref
        .read(entitlementProvider.notifier)
        .grant(
          plan: plan,
          status: status,
          expiresAt: expiresAt,
          trialEndsAt: trialEndsAt,
          isLifetime: isLifetime,
        );
  }
}

final purchaseFlowProvider =
    NotifierProvider<PurchaseFlowNotifier, PurchaseFlowState>(
      PurchaseFlowNotifier.new,
    );

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
