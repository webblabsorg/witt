import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../features/home/screens/play_hub_screen.dart';
import '../features/learn/screens/learn_home_screen.dart';
import '../features/planner/screens/planner_screen.dart';
import '../features/offline/screens/offline_screen.dart';
import '../screens/sage/sage_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../features/progress/screens/progress_screen.dart';

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
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onboardingDone = onboarding.isCompleted;

      // If onboarding not done, keep in onboarding flow
      if (!onboardingDone) {
        if (!location.startsWith('/onboarding')) {
          return '/onboarding/splash';
        }
        return null;
      }

      // If onboarding done but not authed, allow home (anonymous access)
      // Redirect away from onboarding screens once done
      if (onboardingDone && location.startsWith('/onboarding')) {
        return '/home';
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
