import 'package:hive_flutter/hive_flutter.dart';

// Box names
const kBoxUsage = 'ai_usage';
const kBoxProgress = 'progress';

// Usage keys
const kKeyDailyMessages = 'daily_messages';
const kKeyMonthlyMessages = 'monthly_messages';
const kKeyDailyHomework = 'daily_homework';
const kKeyDailyQuizGens = 'daily_quiz_gens';
const kKeyDailyFlashcardGens = 'daily_flashcard_gens';
const kKeyDailySummarizations = 'daily_summarizations';
const kKeyDailyAttachments = 'daily_attachments';
const kKeyLastResetDate = 'last_reset_date';

// Progress keys
const kKeyXp = 'xp';
const kKeyBadges = 'badges';
const kKeyStreakCurrent = 'streak_current';
const kKeyStreakLongest = 'streak_longest';
const kKeyStreakLastStudied = 'streak_last_studied';
const kKeyStreakDates = 'streak_dates';
const kKeyDailyActivity = 'daily_activity';

Future<void> openPersistenceBoxes() async {
  await Hive.openBox<dynamic>(kBoxUsage);
  await Hive.openBox<dynamic>(kBoxProgress);
}

Box<dynamic> get usageBox => Hive.box<dynamic>(kBoxUsage);
Box<dynamic> get progressBox => Hive.box<dynamic>(kBoxProgress);
