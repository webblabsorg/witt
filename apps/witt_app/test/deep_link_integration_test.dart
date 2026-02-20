// Deep-link integration tests — exercises the actual redirect logic from
// router.dart with various auth/onboarding state combinations.
//
// These are pure Dart tests (no device needed) that validate the redirect
// function produces correct destinations for every deep-link scenario.

import 'package:flutter_test/flutter_test.dart';

import 'package:witt_app/app/router.dart';
import 'package:witt_app/features/auth/auth_state.dart';
import 'package:witt_app/features/onboarding/onboarding_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

const _onboardingIncomplete = OnboardingData();
const _onboardingComplete = OnboardingData(
  language: 'en',
  role: 'student',
  educationLevel: 'High School',
  isCompleted: true,
);
const _onboardingTeacher = OnboardingData(
  language: 'en',
  role: 'teacher',
  educationLevel: 'University',
  isCompleted: true,
);

const _unauthenticated = AuthState(status: AuthStatus.unauthenticated);
const _anonymous = AuthState(status: AuthStatus.anonymous);
const _authenticated = AuthState(status: AuthStatus.authenticated);

void main() {
  // ── 1. Community alias ──────────────────────────────────────────────────

  group('Deep link — /community alias', () {
    test('/community redirects to /social regardless of auth state', () {
      final result = computeRedirect(
        location: '/community',
        fullUri: '/community',
        onboarding: _onboardingComplete,
        auth: _authenticated,
      );
      expect(result, equals('/social'));
    });

    test('/community redirects to /social even when anonymous', () {
      final result = computeRedirect(
        location: '/community',
        fullUri: '/community',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, equals('/social'));
    });
  });

  // ── 2. Onboarding-incomplete deep links ─────────────────────────────────

  group('Deep link — onboarding incomplete', () {
    test('deep link to /home preserves destination in ?from=', () {
      final result = computeRedirect(
        location: '/home',
        fullUri: '/home',
        onboarding: _onboardingIncomplete,
        auth: _unauthenticated,
      );
      expect(result, isNotNull);
      expect(result, startsWith('/onboarding/splash?from='));
      expect(result, contains(Uri.encodeComponent('/home')));
    });

    test('deep link to /learn/exam/sat preserves destination', () {
      final result = computeRedirect(
        location: '/learn/exam/sat',
        fullUri: '/learn/exam/sat',
        onboarding: _onboardingIncomplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
      expect(result, contains(Uri.encodeComponent('/learn/exam/sat')));
    });

    test('deep link to /sage preserves destination', () {
      final result = computeRedirect(
        location: '/sage',
        fullUri: '/sage',
        onboarding: _onboardingIncomplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/onboarding/* routes pass through during onboarding', () {
      final result = computeRedirect(
        location: '/onboarding/wizard/1',
        fullUri: '/onboarding/wizard/1',
        onboarding: _onboardingIncomplete,
        auth: _unauthenticated,
      );
      expect(result, isNull);
    });
  });

  // ── 3. Onboarding complete — redirect away from onboarding ──────────────

  group('Deep link — onboarding complete, redirect away', () {
    test('/onboarding/paywall redirects to /home when no ?from=', () {
      final result = computeRedirect(
        location: '/onboarding/paywall',
        fullUri: '/onboarding/paywall',
        onboarding: _onboardingComplete,
        auth: _authenticated,
      );
      expect(result, equals('/home'));
    });

    test('/onboarding/auth?from=/sage redirects to /sage', () {
      final result = computeRedirect(
        location: '/onboarding/auth',
        fullUri: '/onboarding/auth?from=%2Fsage',
        onboarding: _onboardingComplete,
        auth: _authenticated,
        queryParameters: {'from': '%2Fsage'},
      );
      expect(result, equals('/sage'));
    });

    test('/onboarding/splash stays on splash for authenticated users', () {
      final result = computeRedirect(
        location: '/onboarding/splash',
        fullUri: '/onboarding/splash?from=%2Flearn%2Fexam%2Fgre',
        onboarding: _onboardingComplete,
        auth: _authenticated,
        queryParameters: {'from': '%2Flearn%2Fexam%2Fgre'},
      );
      expect(result, isNull);
    });
  });

  // ── 4. Auth guard tier 1 — unauthenticated ──────────────────────────────

  group('Deep link — unauthenticated startup flow', () {
    test('/profile goes to onboarding splash first, preserves destination', () {
      final result = computeRedirect(
        location: '/profile',
        fullUri: '/profile',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
      expect(result, contains(Uri.encodeComponent('/profile')));
    });

    test('/sage goes to onboarding splash first', () {
      final result = computeRedirect(
        location: '/sage',
        fullUri: '/sage',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/social goes to onboarding splash first', () {
      final result = computeRedirect(
        location: '/social',
        fullUri: '/social',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/learn/exam/sat goes to onboarding splash first', () {
      final result = computeRedirect(
        location: '/learn/exam/sat',
        fullUri: '/learn/exam/sat',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/home goes to onboarding splash first', () {
      final result = computeRedirect(
        location: '/home',
        fullUri: '/home',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/learn goes to onboarding splash first', () {
      final result = computeRedirect(
        location: '/learn',
        fullUri: '/learn',
        onboarding: _onboardingComplete,
        auth: _unauthenticated,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });
  });

  // ── 5. Auth guard tier 2 — anonymous ────────────────────────────────────

  group('Deep link — anonymous startup flow', () {
    test('/profile blocked for anonymous (full-auth-only)', () {
      final result = computeRedirect(
        location: '/profile',
        fullUri: '/profile',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/sage blocked for anonymous (full-auth-only)', () {
      final result = computeRedirect(
        location: '/sage',
        fullUri: '/sage',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/social goes to onboarding splash for anonymous', () {
      final result = computeRedirect(
        location: '/social',
        fullUri: '/social',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/learn/exam/sat goes to onboarding splash for anonymous', () {
      final result = computeRedirect(
        location: '/learn/exam/sat',
        fullUri: '/learn/exam/sat',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });

    test('/home goes to onboarding splash for anonymous', () {
      final result = computeRedirect(
        location: '/home',
        fullUri: '/home',
        onboarding: _onboardingComplete,
        auth: _anonymous,
      );
      expect(result, startsWith('/onboarding/splash?from='));
    });
  });

  // ── 6. Authenticated — no redirects ─────────────────────────────────────

  group('Deep link — authenticated, no redirects', () {
    const routes = [
      '/home',
      '/learn',
      '/learn/exam/sat',
      '/sage',
      '/social',
      '/profile',
      '/home/play',
      '/home/search',
      '/home/notifications',
      '/profile/progress',
    ];

    for (final route in routes) {
      test('$route passes through for authenticated student', () {
        final result = computeRedirect(
          location: route,
          fullUri: route,
          onboarding: _onboardingComplete,
          auth: _authenticated,
        );
        expect(result, isNull);
      });
    }
  });

  // ── 7. Role-based guards ────────────────────────────────────────────────

  group('Deep link — role-based guards', () {
    test('/profile/teacher blocked for student role', () {
      final result = computeRedirect(
        location: '/profile/teacher',
        fullUri: '/profile/teacher',
        onboarding: _onboardingComplete,
        auth: _authenticated,
      );
      expect(result, equals('/profile'));
    });

    test('/profile/parent blocked for student role', () {
      final result = computeRedirect(
        location: '/profile/parent',
        fullUri: '/profile/parent',
        onboarding: _onboardingComplete,
        auth: _authenticated,
      );
      expect(result, equals('/profile'));
    });

    test('/profile/teacher passes through for teacher role', () {
      final result = computeRedirect(
        location: '/profile/teacher',
        fullUri: '/profile/teacher',
        onboarding: _onboardingTeacher,
        auth: _authenticated,
      );
      expect(result, isNull);
    });
  });

  // ── 8. Cold-start simulation ────────────────────────────────────────────

  group('Deep link — cold start simulation', () {
    test('cold start with /learn/exam/sat while onboarding incomplete', () {
      // Simulates: app not yet onboarded, user taps witt://learn/exam/sat
      final result = computeRedirect(
        location: '/learn/exam/sat',
        fullUri: '/learn/exam/sat',
        onboarding: _onboardingIncomplete,
        auth: _unauthenticated,
      );
      // Should redirect to splash with preserved destination
      expect(result, startsWith('/onboarding/splash?from='));
      expect(result, contains(Uri.encodeComponent('/learn/exam/sat')));
    });

    test(
      'cold start with /sage while onboarding complete but unauthenticated',
      () {
        // Simulates: onboarding done, user signed out, taps witt://sage
        final result = computeRedirect(
          location: '/sage',
          fullUri: '/sage',
          onboarding: _onboardingComplete,
          auth: _unauthenticated,
        );
        // Should redirect to splash first with preserved destination
        expect(result, startsWith('/onboarding/splash?from='));
        expect(result, contains(Uri.encodeComponent('/sage')));
      },
    );

    test('cold start with /home while fully ready — no redirect', () {
      final result = computeRedirect(
        location: '/home',
        fullUri: '/home',
        onboarding: _onboardingComplete,
        auth: _authenticated,
      );
      expect(result, isNull);
    });
  });
}
