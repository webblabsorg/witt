import 'package:flutter/foundation.dart';

enum ExamRegion { us, uk, africa, india, europe, latinAmerica, china, global }

enum ExamTier {
  free,
  tier1,
  tier2,
  tier3,
}

enum ScoringMethod {
  sumCorrect,
  scaledScore,
  percentile,
  bandScore,
  negativeMarking,
}

@immutable
class ExamSection {
  const ExamSection({
    required this.id,
    required this.name,
    required this.questionCount,
    required this.timeLimitMinutes,
    this.topics = const [],
    this.allowCalculator = false,
  });

  final String id;
  final String name;
  final int questionCount;
  final int timeLimitMinutes;
  final List<String> topics;
  final bool allowCalculator;

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
        id: json['id'] as String,
        name: json['name'] as String,
        questionCount: json['question_count'] as int,
        timeLimitMinutes: json['time_limit_minutes'] as int,
        topics: List<String>.from(json['topics'] ?? []),
        allowCalculator: json['allow_calculator'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'question_count': questionCount,
        'time_limit_minutes': timeLimitMinutes,
        'topics': topics,
        'allow_calculator': allowCalculator,
      };
}

@immutable
class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.fullName,
    required this.region,
    required this.tier,
    required this.sections,
    required this.scoringMethod,
    required this.minScore,
    required this.maxScore,
    required this.purpose,
    this.emoji = '📚',
    this.freeQuestionCount = 15,
    this.hasNegativeMarking = false,
    this.negativeMarkPenalty = 0.0,
    this.hasBreaks = false,
    this.breakDurationMinutes = 0,
    this.weeklyPriceUsd = 1.99,
    this.monthlyPriceUsd = 4.99,
    this.yearlyPriceUsd = 29.99,
  });

  final String id;
  final String name;
  final String fullName;
  final ExamRegion region;
  final ExamTier tier;
  final List<ExamSection> sections;
  final ScoringMethod scoringMethod;
  final double minScore;
  final double maxScore;
  final String purpose;
  final String emoji;
  final int freeQuestionCount;
  final bool hasNegativeMarking;
  final double negativeMarkPenalty;
  final bool hasBreaks;
  final int breakDurationMinutes;
  final double weeklyPriceUsd;
  final double monthlyPriceUsd;
  final double yearlyPriceUsd;

  int get totalQuestions =>
      sections.fold(0, (sum, s) => sum + s.questionCount);
  int get totalTimeMinutes =>
      sections.fold(0, (sum, s) => sum + s.timeLimitMinutes);

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        name: json['name'] as String,
        fullName: json['full_name'] as String,
        region: ExamRegion.values.firstWhere(
          (e) => e.name == json['region'],
          orElse: () => ExamRegion.global,
        ),
        tier: ExamTier.values.firstWhere(
          (e) => e.name == json['tier'],
          orElse: () => ExamTier.tier2,
        ),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((s) => ExamSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        scoringMethod: ScoringMethod.values.firstWhere(
          (e) => e.name == json['scoring_method'],
          orElse: () => ScoringMethod.scaledScore,
        ),
        minScore: (json['min_score'] as num).toDouble(),
        maxScore: (json['max_score'] as num).toDouble(),
        purpose: json['purpose'] as String,
        emoji: json['emoji'] as String? ?? '📚',
        freeQuestionCount: json['free_question_count'] as int? ?? 15,
        hasNegativeMarking: json['has_negative_marking'] as bool? ?? false,
        negativeMarkPenalty:
            (json['negative_mark_penalty'] as num?)?.toDouble() ?? 0.0,
        hasBreaks: json['has_breaks'] as bool? ?? false,
        breakDurationMinutes: json['break_duration_minutes'] as int? ?? 0,
        weeklyPriceUsd:
            (json['weekly_price_usd'] as num?)?.toDouble() ?? 1.99,
        monthlyPriceUsd:
            (json['monthly_price_usd'] as num?)?.toDouble() ?? 4.99,
        yearlyPriceUsd:
            (json['yearly_price_usd'] as num?)?.toDouble() ?? 29.99,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'full_name': fullName,
        'region': region.name,
        'tier': tier.name,
        'sections': sections.map((s) => s.toJson()).toList(),
        'scoring_method': scoringMethod.name,
        'min_score': minScore,
        'max_score': maxScore,
        'purpose': purpose,
        'emoji': emoji,
        'free_question_count': freeQuestionCount,
        'has_negative_marking': hasNegativeMarking,
        'negative_mark_penalty': negativeMarkPenalty,
        'has_breaks': hasBreaks,
        'break_duration_minutes': breakDurationMinutes,
        'weekly_price_usd': weeklyPriceUsd,
        'monthly_price_usd': monthlyPriceUsd,
        'yearly_price_usd': yearlyPriceUsd,
      };
}
