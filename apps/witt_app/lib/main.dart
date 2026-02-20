import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/persistence/persistent_notifiers.dart';
import 'features/progress/providers/progress_providers.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  Bootstrap.run(
    ProviderScope(
      overrides: [
        usageProvider.overrideWith(HiveUsageNotifier.new),
        xpProvider.overrideWith(HiveXpNotifier.new),
        badgeProvider.overrideWith(HiveBadgeNotifier.new),
        streakProvider.overrideWith(HiveStreakNotifier.new),
        dailyActivityProvider.overrideWith(HiveDailyActivityNotifier.new),
      ],
      child: const WittApp(),
    ),
  );
}
