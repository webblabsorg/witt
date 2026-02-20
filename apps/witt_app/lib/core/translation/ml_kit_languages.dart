library;

class MlKitLanguage {
  const MlKitLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
  });

  final String code;
  final String englishName;
  final String nativeName;
  final String flag;
}

/// Full on-device translation set supported by google_mlkit_translation (59).
const mlKitLanguages = <MlKitLanguage>[
  MlKitLanguage(code: 'af', englishName: 'Afrikaans', nativeName: 'Afrikaans', flag: '🇿🇦'),
  MlKitLanguage(code: 'sq', englishName: 'Albanian', nativeName: 'Shqip', flag: '🇦🇱'),
  MlKitLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
  MlKitLanguage(code: 'be', englishName: 'Belarusian', nativeName: 'Беларуская', flag: '🇧🇾'),
  MlKitLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
  MlKitLanguage(code: 'bg', englishName: 'Bulgarian', nativeName: 'Български', flag: '🇧🇬'),
  MlKitLanguage(code: 'ca', englishName: 'Catalan', nativeName: 'Català', flag: '🇪🇸'),
  MlKitLanguage(code: 'zh', englishName: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  MlKitLanguage(code: 'hr', englishName: 'Croatian', nativeName: 'Hrvatski', flag: '🇭🇷'),
  MlKitLanguage(code: 'cs', englishName: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
  MlKitLanguage(code: 'da', englishName: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
  MlKitLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
  MlKitLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇬🇧'),
  MlKitLanguage(code: 'eo', englishName: 'Esperanto', nativeName: 'Esperanto', flag: '🌍'),
  MlKitLanguage(code: 'et', englishName: 'Estonian', nativeName: 'Eesti', flag: '🇪🇪'),
  MlKitLanguage(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
  MlKitLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', flag: '🇫🇷'),
  MlKitLanguage(code: 'gl', englishName: 'Galician', nativeName: 'Galego', flag: '🇪🇸'),
  MlKitLanguage(code: 'ka', englishName: 'Georgian', nativeName: 'ქართული', flag: '🇬🇪'),
  MlKitLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
  MlKitLanguage(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά', flag: '🇬🇷'),
  MlKitLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
  MlKitLanguage(code: 'ht', englishName: 'Haitian Creole', nativeName: 'Kreyòl Ayisyen', flag: '🇭🇹'),
  MlKitLanguage(code: 'he', englishName: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱'),
  MlKitLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
  MlKitLanguage(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
  MlKitLanguage(code: 'is', englishName: 'Icelandic', nativeName: 'Íslenska', flag: '🇮🇸'),
  MlKitLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
  MlKitLanguage(code: 'ga', englishName: 'Irish', nativeName: 'Gaeilge', flag: '🇮🇪'),
  MlKitLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
  MlKitLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
  MlKitLanguage(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
  MlKitLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  MlKitLanguage(code: 'lv', englishName: 'Latvian', nativeName: 'Latviešu', flag: '🇱🇻'),
  MlKitLanguage(code: 'lt', englishName: 'Lithuanian', nativeName: 'Lietuvių', flag: '🇱🇹'),
  MlKitLanguage(code: 'mk', englishName: 'Macedonian', nativeName: 'Македонски', flag: '🇲🇰'),
  MlKitLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  MlKitLanguage(code: 'mt', englishName: 'Maltese', nativeName: 'Malti', flag: '🇲🇹'),
  MlKitLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
  MlKitLanguage(code: 'no', englishName: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
  MlKitLanguage(code: 'fa', englishName: 'Persian', nativeName: 'فارسی', flag: '🇮🇷'),
  MlKitLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
  MlKitLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
  MlKitLanguage(code: 'ro', englishName: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
  MlKitLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
  MlKitLanguage(code: 'sk', englishName: 'Slovak', nativeName: 'Slovenčina', flag: '🇸🇰'),
  MlKitLanguage(code: 'sl', englishName: 'Slovenian', nativeName: 'Slovenščina', flag: '🇸🇮'),
  MlKitLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  MlKitLanguage(code: 'sw', englishName: 'Swahili', nativeName: 'Kiswahili', flag: '🇰🇪'),
  MlKitLanguage(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
  MlKitLanguage(code: 'tl', englishName: 'Tagalog', nativeName: 'Tagalog', flag: '🇵🇭'),
  MlKitLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
  MlKitLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
  MlKitLanguage(code: 'th', englishName: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
  MlKitLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
  MlKitLanguage(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська', flag: '🇺🇦'),
  MlKitLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
  MlKitLanguage(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
  MlKitLanguage(code: 'cy', englishName: 'Welsh', nativeName: 'Cymraeg', flag: '🏴'),
];
