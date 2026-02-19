import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes all services before the app starts.
/// Called once from main() before runApp().
class Bootstrap {
  Bootstrap._();

  static Mixpanel? _mixpanel;

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

    // Initialize Sentry error tracking
    final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = kDebugMode ? 0.0 : 1.0;
        options.environment = env;
        options.debug = kDebugMode;
      });
    }

    // Initialize Mixpanel analytics
    final mixpanelToken = dotenv.env['MIXPANEL_TOKEN'] ?? '';
    if (mixpanelToken.isNotEmpty) {
      _mixpanel = await Mixpanel.init(
        mixpanelToken,
        optOutTrackingDefault: false,
        trackAutomaticEvents: true,
      );
      _mixpanel?.track('app_open');
    }

    // Initialize OneSignal push notifications
    final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    if (oneSignalAppId.isNotEmpty) {
      OneSignal.initialize(oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
    }
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Convenience accessor for Mixpanel analytics.
  static Mixpanel? get mixpanel => _mixpanel;

  /// Track an analytics event.
  static void track(String event, {Map<String, dynamic>? properties}) {
    _mixpanel?.track(event, properties: properties);
  }
}
