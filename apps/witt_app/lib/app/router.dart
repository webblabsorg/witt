import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'scaffold_with_nav.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/sage/sage_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/profile/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _learnNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'learn');
final _sageNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'sage');
final _socialNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'social');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 2: Learn
          StatefulShellBranch(
            navigatorKey: _learnNavigatorKey,
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const LearnScreen(),
              ),
            ],
          ),
          // Tab 3: Sage (AI Chat Bot)
          StatefulShellBranch(
            navigatorKey: _sageNavigatorKey,
            routes: [
              GoRoute(
                path: '/sage',
                builder: (context, state) => const SageScreen(),
              ),
            ],
          ),
          // Tab 4: Social
          StatefulShellBranch(
            navigatorKey: _socialNavigatorKey,
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialScreen(),
              ),
            ],
          ),
          // Tab 5: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
