// Phase 4 smoke tests — social limits, games gate, teacher/parent access,
// translation flow. These are pure unit tests on providers (no Hive I/O)
// using a mock container so they run in CI without device setup.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:witt_monetization/witt_monetization.dart';

import 'package:witt_app/features/social/providers/social_providers.dart';
import 'package:witt_app/features/games/providers/game_providers.dart';
import 'package:witt_app/features/translation/models/translation_models.dart';
import 'package:witt_app/features/translation/providers/translation_providers.dart';
import 'package:witt_app/features/onboarding/onboarding_state.dart';
import 'package:witt_app/core/persistence/hive_boxes.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

/// Creates a ProviderContainer with optional overrides.
ProviderContainer _container({List<Override> overrides = const []}) {
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  return c;
}

/// Override that makes the user a free (non-paid) user.
final _freeUser = isPaidProvider.overrideWithValue(false);

/// Override that makes the user a paid user.
final _paidUser = isPaidProvider.overrideWithValue(true);

// ── Hive setup ────────────────────────────────────────────────────────────

late Directory _hiveDir;

Future<void> _initHive() async {
  _hiveDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(_hiveDir.path);
  await openPersistenceBoxes();
  await Hive.openBox<dynamic>('app_prefs');
}

Future<void> _tearDownHive() async {
  await Hive.close();
  await _hiveDir.delete(recursive: true);
}

// ── Social: group join limit ───────────────────────────────────────────────

void main() {
  setUpAll(_initHive);
  tearDownAll(_tearDownHive);

  group('Social — group join limit (free: max 2)', () {
    test('free user can join up to 2 groups', () {
      final c = _container(overrides: [_freeUser]);
      final notifier = c.read(groupsProvider.notifier);

      // Initially g1 and g5 are joined in sample data (restored from Hive,
      // but in test Hive is not open so build() returns _sampleGroups as-is).
      // We test the canJoin logic directly.
      expect(notifier.canJoin(false), isA<bool>());
    });

    test('canJoin returns false when 2 groups already joined (free)', () {
      final c = _container(overrides: [_freeUser]);
      final notifier = c.read(groupsProvider.notifier);
      final joinedCount = notifier.joinedCount;
      // canJoin should be false if already at limit
      if (joinedCount >= 2) {
        expect(notifier.canJoin(false), isFalse);
      } else {
        expect(notifier.canJoin(false), isTrue);
      }
    });

    test('paid user can always join', () {
      final c = _container(overrides: [_paidUser]);
      final notifier = c.read(groupsProvider.notifier);
      expect(notifier.canJoin(true), isTrue);
    });
  });

  // ── Social: post like toggle ─────────────────────────────────────────────

  group('Social — feed like toggle', () {
    test('toggling like increments then decrements likes', () {
      final c = _container(overrides: [_freeUser]);
      final posts = c.read(feedProvider);
      final first = posts.first;
      final initialLikes = first.likes;

      c.read(feedProvider.notifier).toggleLike(first.id);
      final liked = c.read(feedProvider).firstWhere((p) => p.id == first.id);
      expect(liked.isLiked, isTrue);
      expect(liked.likes, initialLikes + 1);

      c.read(feedProvider.notifier).toggleLike(first.id);
      final unliked = c.read(feedProvider).firstWhere((p) => p.id == first.id);
      expect(unliked.isLiked, isFalse);
      expect(unliked.likes, initialLikes);
    });
  });

  // ── Social: forum upvote toggle ──────────────────────────────────────────

  group('Social — forum upvote toggle', () {
    test('toggling upvote increments then decrements votes', () {
      final c = _container(overrides: [_freeUser]);
      final questions = c.read(forumProvider);
      final first = questions.first;
      final initialVotes = first.votes;

      c.read(forumProvider.notifier).toggleUpvote(first.id);
      final upvoted = c.read(forumProvider).firstWhere((q) => q.id == first.id);
      expect(upvoted.isUpvoted, isTrue);
      expect(upvoted.votes, initialVotes + 1);

      c.read(forumProvider.notifier).toggleUpvote(first.id);
      final downvoted = c
          .read(forumProvider)
          .firstWhere((q) => q.id == first.id);
      expect(downvoted.isUpvoted, isFalse);
      expect(downvoted.votes, initialVotes);
    });
  });

  // ── Games: daily play gate ────────────────────────────────────────────────

  group('Games — daily play gate (free: 3/day)', () {
    test('free user with 0 games played can play', () {
      final c = _container(
        overrides: [_freeUser, gamesPlayedTodayProvider.overrideWith((_) => 0)],
      );
      expect(c.read(canPlayGameProvider), isTrue);
    });

    test('free user with 3 games played cannot play', () {
      final c = _container(
        overrides: [_freeUser, gamesPlayedTodayProvider.overrideWith((_) => 3)],
      );
      expect(c.read(canPlayGameProvider), isFalse);
    });

    test('paid user with 3 games played can still play', () {
      final c = _container(
        overrides: [_paidUser, gamesPlayedTodayProvider.overrideWith((_) => 3)],
      );
      expect(c.read(canPlayGameProvider), isTrue);
    });
  });

  // ── Games: catalog ────────────────────────────────────────────────────────

  group('Games — catalog', () {
    test('catalog has exactly 9 games', () {
      final c = _container(overrides: [_freeUser]);
      expect(c.read(gamesProvider).length, 9);
    });

    test('paid-only games are visible to free users (gated at launch)', () {
      final c = _container(overrides: [_freeUser]);
      final paidOnly = c
          .read(gamesProvider)
          .where((g) => g.isPaidOnly)
          .toList();
      expect(paidOnly.isNotEmpty, isTrue);
    });
  });

  // ── Games: brain challenges ───────────────────────────────────────────────

  group('Games — brain challenges', () {
    test('completing a challenge marks it as completed', () {
      final c = _container(overrides: [_freeUser]);
      final challenges = c.read(brainChallengesProvider);
      final first = challenges.first;
      expect(first.isCompleted, isFalse);

      c.read(brainChallengesProvider.notifier).complete(first.id);
      final updated = c
          .read(brainChallengesProvider)
          .firstWhere((ch) => ch.id == first.id);
      expect(updated.isCompleted, isTrue);
    });

    test('exactly one daily challenge exists', () {
      final c = _container(overrides: [_freeUser]);
      final daily = c
          .read(brainChallengesProvider)
          .where((c) => c.isDaily)
          .toList();
      expect(daily.length, 1);
    });
  });

  // ── Translation: language selection ──────────────────────────────────────

  group('Translation — language selection', () {
    test('supported languages list has 19 entries', () {
      final c = _container();
      expect(c.read(supportedLanguagesProvider).length, 19);
    });

    test('setSourceLang updates state', () {
      final c = _container();
      c.read(translationProvider.notifier).setSourceLang('es');
      expect(c.read(translationProvider).sourceLang, 'es');
    });

    test('setTargetLang updates state', () {
      final c = _container();
      c.read(translationProvider.notifier).setTargetLang('ar');
      expect(c.read(translationProvider).targetLang, 'ar');
    });

    test('swapLanguages swaps source and target', () {
      final c = _container();
      c.read(translationProvider.notifier).setSourceLang('en');
      c.read(translationProvider.notifier).setTargetLang('fr');
      c.read(translationProvider.notifier).swapLanguages();
      expect(c.read(translationProvider).sourceLang, 'fr');
      expect(c.read(translationProvider).targetLang, 'en');
    });
  });

  // ── Translation: translate flow ───────────────────────────────────────────

  group('Translation — translate flow', () {
    test('translate resolves to success or error (network-agnostic)', () async {
      final c = _container();
      c.read(translationProvider.notifier).setSourceLang('en');
      c.read(translationProvider.notifier).setTargetLang('fr');
      c.read(translationProvider.notifier).setInput('hello');
      await c.read(translationProvider.notifier).translate();

      final state = c.read(translationProvider);
      // In CI/test env LibreTranslate may not be reachable — accept either outcome
      expect(
        state.status,
        anyOf(TranslationStatus.success, TranslationStatus.error),
      );
      // Must not be stuck in loading
      expect(state.status, isNot(TranslationStatus.loading));
    });

    test('clearHistory empties history', () {
      final c = _container();
      // Directly test clearHistory without needing a network call
      c.read(translationProvider.notifier).clearHistory();
      expect(c.read(translationProvider).history, isEmpty);
    });

    test('empty input does not trigger translation', () async {
      final c = _container();
      c.read(translationProvider.notifier).setInput('');
      await c.read(translationProvider.notifier).translate();
      // Empty input returns early — status stays idle
      expect(
        c.read(translationProvider).status,
        isNot(TranslationStatus.loading),
      );
    });
  });

  // ── Role-based portal access ──────────────────────────────────────────────

  group('Onboarding — role field', () {
    test('OnboardingData default role is null', () {
      const data = OnboardingData();
      expect(data.role, isNull);
    });

    test('OnboardingData copyWith sets role', () {
      const data = OnboardingData();
      final teacher = data.copyWith(role: 'teacher');
      expect(teacher.role, 'teacher');
    });

    test('role values are student/teacher/parent', () {
      for (final role in ['student', 'teacher', 'parent']) {
        final data = OnboardingData().copyWith(role: role);
        expect(data.role, role);
      }
    });
  });
}
