import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes all services before the app starts.
/// Called once from main() before runApp().
class Bootstrap {
  Bootstrap._();

  static Future<void> init() async {
    // Load environment config
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    await dotenv.load(fileName: '.env.$env');

    // Initialize Hive (local key-value storage)
    await Hive.initFlutter();

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );

    // TODO: Initialize Sentry (Session 0.3 — requires SENTRY_DSN)
    // await SentryFlutter.init((options) {
    //   options.dsn = dotenv.env['SENTRY_DSN'];
    //   options.tracesSampleRate = 1.0;
    //   options.environment = env;
    // });

    // TODO: Initialize Mixpanel/PostHog (Session 0.3 — requires token)
    // final mixpanel = await Mixpanel.init(dotenv.env['MIXPANEL_TOKEN']!);

    // TODO: Initialize OneSignal (Session 0.3 — requires app ID)
    // OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
    // OneSignal.Notifications.requestPermission(true);
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get supabase => Supabase.instance.client;
}
