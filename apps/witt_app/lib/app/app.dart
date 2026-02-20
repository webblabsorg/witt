import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';

import 'router.dart';

class WittApp extends ConsumerWidget {
  const WittApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
