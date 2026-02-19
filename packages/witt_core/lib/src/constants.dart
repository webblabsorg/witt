/// App-wide constants
class WittConstants {
  WittConstants._();

  static const String appName = 'Witt';
  static const String tagline =
      'The AI-Powered Study Companion for Every Student, Everywhere';

  // Supabase
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  // OneSignal
  static const String oneSignalAppIdKey = 'ONESIGNAL_APP_ID';

  // Sentry
  static const String sentryDsnKey = 'SENTRY_DSN';

  // AI daily limits (free tier)
  static const int freeSageMessagesPerDay = 10;
  static const int freeSageMessagesPerMonth = 300;
  static const int freeMaxInputChars = 500;
  static const int freeMaxOutputWords = 500;
  static const int freeQuizQuestionsPerGen = 5;
  static const int freeQuizGensPerDay = 1;
  static const int freeAiQuestionsPerMonth = 30;
}
