/// User roles from onboarding Q1
enum UserRole { student, teacher, parent }

/// Education levels from onboarding Q2
enum EducationLevel {
  middleSchool,
  highSchool,
  college,
  graduateSchool,
  professional,
  other,
}

/// AI provider routing
enum AIProvider { groq, openai, claude }

/// User subscription tier
enum SubscriptionTier { free, premiumMonthly, premiumYearly }

/// Learning preference from onboarding Q9
enum LearningPreference {
  flashcards,
  practiceTests,
  games,
  reading,
  videoLectures,
  aiTutoring,
}

/// Study time commitment from onboarding Q7
enum StudyTime {
  fifteenMin,
  thirtyMin,
  oneHour,
  twoHoursPlus,
}

/// App theme mode
enum WittThemeMode { light, dark, system }

/// Bottom navigation tabs
enum WittTab { home, learn, sage, social, profile }
