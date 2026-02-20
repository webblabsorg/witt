import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:witt_monetization/witt_monetization.dart';
import 'package:witt_ui/witt_ui.dart';

import 'router.dart';

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

    return MaterialApp.router(
      title: 'Witt',
      debugShowCheckedModeBanner: false,
      theme: WittTheme.light,
      darkTheme: WittTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
