/// App locale provider — English only for US launch.
/// Multi-language support commented out; re-enable when expanding internationally.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../translation/ml_kit_languages.dart'; // Re-enable for multi-language support

// const _kBoxPrefs = 'app_prefs'; // Unused: locale hard-coded to English
// const _kKeyLocale = 'app_locale';

class AppLocale {
  const AppLocale(this.code, this.name, this.flag);
  final String code;
  final String name;
  final String flag;
}

/// Active locale — English only for US launch.
/// Re-enable multi-language list when expanding internationally:
// final appLocales = mlKitLanguages
//     .map((l) => AppLocale(l.code, l.nativeName, l.flag))
//     .toList(growable: false);
final appLocales = const [AppLocale('en', 'English', '🇺🇸')];

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Hard-coded to English for US-only launch.
    // To restore dynamic locale:
    //   final box = Hive.box<dynamic>(_kBoxPrefs);
    //   return Locale(box.get(_kKeyLocale, defaultValue: 'en') as String);
    return const Locale('en');
  }

  Future<void> setLocale(String languageCode) async {
    // Language switching disabled for US-only launch.
    // Re-enable when multi-language support is restored:
    // state = Locale(languageCode);
    // final box = Hive.box<dynamic>(_kBoxPrefs);
    // await box.put(_kKeyLocale, languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

final appLocalesProvider = Provider<List<AppLocale>>((_) => appLocales);
