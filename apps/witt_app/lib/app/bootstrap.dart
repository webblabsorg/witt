import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subrail_flutter/subrail_flutter.dart';

import '../features/onboarding/onboarding_state.dart';
import '../core/persistence/hive_boxes.dart';

/// Initializes all services and runs the app.
/// Single entry point — call Bootstrap.run(app) from main().
class Bootstrap {
  Bootstrap._();

  static Mixpanel? _mixpanel;

  /// Initializes all services then calls [appRunner] inside Sentry's zone
  /// so Flutter framework errors are captured automatically.
  static Future<void> run(Widget app) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment config
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    await dotenv.load(fileName: '.env.$env');

    // Initialize Hive (local key-value storage)
    await Hive.initFlutter();
    await openOnboardingBox();
    await openPersistenceBoxes();

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );

    // Initialize Subrail billing SDK
    final subrailApiKey = dotenv.env['SUBRAIL_API_KEY'] ?? '';
    if (subrailApiKey.isNotEmpty) {
      await Subrail.configure(
        apiKey: subrailApiKey,
        useSandbox: kDebugMode,
        logLevel: kDebugMode ? LogLevel.debug : LogLevel.warn,
      );
      // Sync Supabase user identity with Subrail on auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final user = data.session?.user;
        if (user != null) {
          await Subrail.logIn(user.id);
        } else {
          await Subrail.logOut();
        }
      });
      // Log in immediately if already authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await Subrail.logIn(currentUser.id);
      }
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

    // Initialize Sentry last — wraps runApp so all Flutter errors are captured.
    final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn; // empty string = disabled (no-op)
      options.tracesSampleRate = kDebugMode ? 0.0 : 1.0;
      options.environment = env;
      options.debug = kDebugMode;
    }, appRunner: () => runApp(app));
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
