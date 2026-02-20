import 'package:flutter/foundation.dart';

enum SubscriptionPlan { free, premiumMonthly, premiumYearly }

enum SubscriptionStatus { active, expired, trial, cancelled, none }

@immutable
class Entitlement {
  const Entitlement({
    required this.plan,
    required this.status,
    required this.unlockedExamIds,
    this.expiresAt,
    this.trialEndsAt,
    this.isLifetime = false,
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final List<String> unlockedExamIds;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final bool isLifetime;

  bool get isPremium =>
      (plan == SubscriptionPlan.premiumMonthly ||
          plan == SubscriptionPlan.premiumYearly ||
          isLifetime) &&
      (status == SubscriptionStatus.active ||
          status == SubscriptionStatus.trial);

  bool get isInTrial => status == SubscriptionStatus.trial;

  bool isExamUnlocked(String examId) =>
      isPremium || unlockedExamIds.contains(examId);

  static const free = Entitlement(
    plan: SubscriptionPlan.free,
    status: SubscriptionStatus.none,
    unlockedExamIds: [],
  );

  Entitlement copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    List<String>? unlockedExamIds,
    DateTime? expiresAt,
    DateTime? trialEndsAt,
    bool? isLifetime,
  }) =>
      Entitlement(
        plan: plan ?? this.plan,
        status: status ?? this.status,
        unlockedExamIds: unlockedExamIds ?? this.unlockedExamIds,
        expiresAt: expiresAt ?? this.expiresAt,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        isLifetime: isLifetime ?? this.isLifetime,
      );
}

@immutable
class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceUsd,
    required this.localizedPrice,
    required this.currencyCode,
    required this.plan,
  });

  final String id;
  final String title;
  final String description;
  final double priceUsd;
  final String localizedPrice;
  final String currencyCode;
  final SubscriptionPlan plan;
}
