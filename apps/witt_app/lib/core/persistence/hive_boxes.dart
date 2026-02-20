import 'package:hive_flutter/hive_flutter.dart';

// Box names
const kBoxUsage = 'ai_usage';
const kBoxProgress = 'progress';
const kBoxSocial = 'social';
const kBoxGames = 'games';
const kBoxTranslation = 'translation';

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

// Social keys
const kKeyJoinedGroupIds = 'joined_group_ids';
const kKeyPostsToday = 'posts_today';
const kKeySocialLastResetDate = 'social_last_reset_date';
const kKeyLikedPostIds = 'liked_post_ids';
const kKeyUpvotedQuestionIds = 'upvoted_question_ids';

// Games keys
const kKeyGamesPlayedToday = 'games_played_today';
const kKeyGamesLastResetDate = 'games_last_reset_date';
const kKeyCompletedChallengeIds = 'completed_challenge_ids';

// Translation keys
const kKeyTranslationHistory = 'translation_history';
const kKeyLastSourceLang = 'last_source_lang';
const kKeyLastTargetLang = 'last_target_lang';

Future<void> openPersistenceBoxes() async {
  await Hive.openBox<dynamic>(kBoxUsage);
  await Hive.openBox<dynamic>(kBoxProgress);
  await Hive.openBox<dynamic>(kBoxSocial);
  await Hive.openBox<dynamic>(kBoxGames);
  await Hive.openBox<dynamic>(kBoxTranslation);
}

Box<dynamic> get usageBox => Hive.box<dynamic>(kBoxUsage);
Box<dynamic> get progressBox => Hive.box<dynamic>(kBoxProgress);
Box<dynamic> get socialBox => Hive.box<dynamic>(kBoxSocial);
Box<dynamic> get gamesBox => Hive.box<dynamic>(kBoxGames);
Box<dynamic> get translationBox => Hive.box<dynamic>(kBoxTranslation);
