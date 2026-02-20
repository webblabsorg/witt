import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';

import 'scaffold_with_nav.dart';
import '../features/onboarding/onboarding_state.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/language_picker_screen.dart';
import '../features/onboarding/screens/wizard_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/screens/email_auth_screen.dart';
import '../features/auth/screens/phone_auth_screen.dart';
import '../features/paywall/screens/paywall_screen.dart';
import '../features/paywall/screens/feature_comparison_screen.dart';
import '../features/paywall/screens/free_trial_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/search_screen.dart';
import '../features/home/screens/notifications_screen.dart';
import '../features/games/screens/play_hub_screen.dart';
import '../features/learn/screens/learn_home_screen.dart';
import '../features/learn/screens/exam_hub_screen.dart';
import '../features/planner/screens/planner_screen.dart';
import '../features/offline/screens/offline_screen.dart';
import '../screens/sage/sage_screen.dart';
import '../features/social/screens/social_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/teacher/screens/teacher_screen.dart';
import '../features/teacher/screens/parent_screen.dart';
import '../features/translation/screens/translation_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _learnNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'learn');
final _sageNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'sage');
final _socialNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'social');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  final auth = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _initialLocation(onboarding, auth),
    // Deep link schemes: witt:// and https://witt.app
    // GoRouter handles these automatically via the OS intent/URL handler.
    // Routes below map 1:1 to the spec §4.4 deep-link conformance table.
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onboardingDone = onboarding.isCompleted;
      final isAuthenticated = auth.isAuthenticated;

      // /community is an alias for /social (deep-link spec §4.4)
      if (location == '/community') return '/social';

      // If onboarding not done, preserve the intended destination as a query
      // param so the user lands there after completing onboarding/auth.
      if (!onboardingDone) {
        if (!location.startsWith('/onboarding')) {
          final dest = Uri.encodeComponent(state.uri.toString());
          return '/onboarding/splash?from=$dest';
        }
        return null;
      }

      // Redirect away from onboarding screens once done
      if (onboardingDone && location.startsWith('/onboarding')) {
        // Honour ?from= redirect if present
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }
        return '/home';
      }

      // Auth guard tier 1: completely unauthenticated (no session at all)
      // → redirect to auth, preserving destination.
      if (auth.status == AuthStatus.unauthenticated &&
          _requiresAuth(location)) {
        final dest = Uri.encodeComponent(state.uri.toString());
        return '/onboarding/auth?from=$dest';
      }

      // Auth guard tier 2: anonymous session cannot access account-only routes.
      if (auth.isAnonymous && _requiresFullAuth(location)) {
        final dest = Uri.encodeComponent(state.uri.toString());
        return '/onboarding/auth?from=$dest';
      }

      // Role-based portal guards
      final role = onboarding.role;
      if (location == '/profile/teacher' && role != 'teacher') {
        return '/profile';
      }
      if (location == '/profile/parent' && role != 'parent') {
        return '/profile';
      }

      return null;
    },
    routes: [
      // ── Onboarding flow (outside shell) ──────────────────────────────────
      GoRoute(
        path: '/onboarding/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (_, __) => const LanguagePickerScreen(),
      ),
      GoRoute(
        path: '/onboarding/wizard/:step',
        builder: (_, state) {
          final step = int.tryParse(state.pathParameters['step'] ?? '1') ?? 1;
          return WizardScreen(step: step);
        },
      ),
      GoRoute(
        path: '/onboarding/auth',
        builder: (_, __) => const AuthScreen(),
        routes: [
          GoRoute(path: 'email', builder: (_, __) => const EmailAuthScreen()),
          GoRoute(
            path: 'login',
            builder: (_, __) => const EmailAuthScreen(isLogin: true),
          ),
          GoRoute(path: 'phone', builder: (_, __) => const PhoneAuthScreen()),
        ],
      ),
      GoRoute(
        path: '/onboarding/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/onboarding/feature-comparison',
        builder: (_, __) => const FeatureComparisonScreen(),
      ),
      GoRoute(
        path: '/onboarding/free-trial',
        builder: (_, __) => const FreeTrialScreen(),
      ),

      // ── Main app shell (5-tab) ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'play',
                    builder: (_, __) => const PlayHubScreen(),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, __) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, __) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'translate',
                    builder: (_, __) => const TranslationScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Learn
          StatefulShellBranch(
            navigatorKey: _learnNavigatorKey,
            routes: [
              GoRoute(
                path: '/learn',
                builder: (_, __) => const LearnHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'planner',
                    builder: (_, __) => const PlannerScreen(),
                  ),
                  GoRoute(
                    path: 'offline',
                    builder: (_, __) => const OfflineScreen(),
                  ),
                  // Deep-link: witt://learn/exam/sat → exam hub for that exam
                  GoRoute(
                    path: 'exam/:examId',
                    builder: (_, state) {
                      final examId = state.pathParameters['examId'] ?? '';
                      return ExamHubScreen(examId: examId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Sage
          StatefulShellBranch(
            navigatorKey: _sageNavigatorKey,
            routes: [
              GoRoute(path: '/sage', builder: (_, __) => const SageScreen()),
            ],
          ),
          // Tab 4: Social
          StatefulShellBranch(
            navigatorKey: _socialNavigatorKey,
            routes: [
              GoRoute(
                path: '/social',
                builder: (_, __) => const SocialScreen(),
              ),
            ],
          ),
          // Tab 5: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'progress',
                    builder: (_, __) => const ProgressScreen(),
                  ),
                  GoRoute(
                    path: 'teacher',
                    builder: (_, __) => const TeacherScreen(),
                  ),
                  GoRoute(
                    path: 'parent',
                    builder: (_, __) => const ParentScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String _initialLocation(OnboardingData onboarding, AuthState auth) {
  if (!onboarding.isCompleted) return '/onboarding/splash';
  return '/home';
}

/// Routes that require at least an anonymous session (no bare unauthenticated).
bool _requiresAuth(String location) {
  const protected = ['/profile', '/sage', '/social', '/learn/exam'];
  return protected.any((p) => location.startsWith(p));
}

/// Routes that require a full (non-anonymous) account.
/// Anonymous users are prompted to sign up when hitting these.
bool _requiresFullAuth(String location) {
  const fullAuthOnly = ['/profile', '/sage'];
  return fullAuthOnly.any((p) => location.startsWith(p));
}

// ── Testable redirect logic ─────────────────────────────────────────────────
// Extracted so integration tests can exercise redirect decisions without
// needing a full GoRouter + widget tree.

/// Computes the redirect destination for a given [location] given the current
/// [onboarding] and [auth] state. Returns null if no redirect is needed.
@visibleForTesting
String? computeRedirect({
  required String location,
  required String fullUri,
  required OnboardingData onboarding,
  required AuthState auth,
  Map<String, String> queryParameters = const {},
}) {
  final onboardingDone = onboarding.isCompleted;

  if (location == '/community') return '/social';

  if (!onboardingDone) {
    if (!location.startsWith('/onboarding')) {
      final dest = Uri.encodeComponent(fullUri);
      return '/onboarding/splash?from=$dest';
    }
    return null;
  }

  if (onboardingDone && location.startsWith('/onboarding')) {
    final from = queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      return Uri.decodeComponent(from);
    }
    return '/home';
  }

  if (auth.status == AuthStatus.unauthenticated && _requiresAuth(location)) {
    final dest = Uri.encodeComponent(fullUri);
    return '/onboarding/auth?from=$dest';
  }

  if (auth.isAnonymous && _requiresFullAuth(location)) {
    final dest = Uri.encodeComponent(fullUri);
    return '/onboarding/auth?from=$dest';
  }

  final role = onboarding.role;
  if (location == '/profile/teacher' && role != 'teacher') return '/profile';
  if (location == '/profile/parent' && role != 'parent') return '/profile';

  return null;
}
