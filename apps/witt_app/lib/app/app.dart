import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:witt_monetization/witt_monetization.dart';
import 'package:witt_ui/witt_ui.dart';

import 'router.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/locale_provider.dart';

class WittApp extends ConsumerStatefulWidget {
  const WittApp({super.key});

  @override
  ConsumerState<WittApp> createState() => _WittAppState();
}

class _WittAppState extends ConsumerState<WittApp> {
  @override
  void initState() {
    super.initState();
    // Hydrate entitlement immediately if user is already signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateEntitlement();
    });
    // Re-hydrate on every Supabase auth state change
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        _hydrateEntitlement();
      } else {
        ref.read(entitlementProvider.notifier).reset();
      }
    });
  }

  Future<void> _hydrateEntitlement() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await ref.read(entitlementProvider.notifier).hydrateFromSubrail();
    } catch (_) {
      // Subrail not configured (missing API key) — retain current state
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final app = MaterialApp.router(
      title: 'Witt',
      debugShowCheckedModeBanner: false,
      theme: WittTheme.light,
      darkTheme: WittTheme.dark,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
    );

    // macOS: wrap with native menu bar
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return PlatformMenuBar(
        menus: [
          PlatformMenu(
            label: 'Witt',
            menus: [
              PlatformMenuItemGroup(
                members: [
                  PlatformMenuItem(
                    label: 'About Witt',
                    onSelected: () => launchUrl(
                      Uri.parse('https://witt.app'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
              PlatformMenuItemGroup(
                members: [
                  PlatformMenuItem(
                    label: 'Preferences…',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.comma,
                      meta: true,
                    ),
                    onSelected: () => router.go('/profile'),
                  ),
                ],
              ),
              PlatformMenuItemGroup(
                members: [
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.quit,
                  ),
                ],
              ),
            ],
          ),
          PlatformMenu(
            label: 'View',
            menus: [
              PlatformMenuItemGroup(
                members: [
                  PlatformMenuItem(
                    label: 'Home',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.digit1,
                      meta: true,
                    ),
                    onSelected: () => router.go('/home'),
                  ),
                  PlatformMenuItem(
                    label: 'Learn',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.digit2,
                      meta: true,
                    ),
                    onSelected: () => router.go('/learn'),
                  ),
                  PlatformMenuItem(
                    label: 'Sage AI',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.digit3,
                      meta: true,
                    ),
                    onSelected: () => router.go('/sage'),
                  ),
                  PlatformMenuItem(
                    label: 'Social',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.digit4,
                      meta: true,
                    ),
                    onSelected: () => router.go('/social'),
                  ),
                  PlatformMenuItem(
                    label: 'Profile',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.digit5,
                      meta: true,
                    ),
                    onSelected: () => router.go('/profile'),
                  ),
                ],
              ),
            ],
          ),
        ],
        child: app,
      );
    }

    return app;
  }
}
