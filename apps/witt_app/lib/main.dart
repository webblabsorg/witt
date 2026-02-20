import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/persistence/persistent_notifiers.dart';
import 'features/progress/providers/progress_providers.dart';

void main() => Bootstrap.run(
  ProviderScope(
    overrides: [
      // AI router — real Supabase credentials
      aiRouterProvider.overrideWithValue(
        AiRouter(
          supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
          supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        ),
      ),

      // Usage limits — persisted to Hive (survives restarts, cross-session)
      usageProvider.overrideWith(HiveUsageNotifier.new),

      // Progress — persisted to Hive
      xpProvider.overrideWith(HiveXpNotifier.new),
      badgeProvider.overrideWith(HiveBadgeNotifier.new),
      streakProvider.overrideWith(HiveStreakNotifier.new),
      dailyActivityProvider.overrideWith(HiveDailyActivityNotifier.new),
    ],
    child: const WittApp(),
  ),
);
