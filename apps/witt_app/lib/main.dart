import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Bootstrap.init();
  await SentryFlutter.init((options) {
    // DSN already set in Bootstrap.init(); this call just wraps runApp
    // so Sentry captures Flutter framework errors automatically.
  }, appRunner: () => runApp(const ProviderScope(child: WittApp())));
}
