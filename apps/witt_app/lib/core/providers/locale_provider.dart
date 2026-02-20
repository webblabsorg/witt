/// App locale provider — persisted to Hive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _kBoxPrefs = 'app_prefs';
const _kKeyLocale = 'app_locale';

/// Supported app interface languages.
const appLocales = [
  _AppLocale('en', 'English', '🇬🇧'),
  _AppLocale('fr', 'Français', '🇫🇷'),
  _AppLocale('es', 'Español', '🇪🇸'),
  _AppLocale('ar', 'العربية', '🇸🇦'),
  _AppLocale('pt', 'Português', '🇧🇷'),
  _AppLocale('sw', 'Kiswahili', '🇰🇪'),
  _AppLocale('ha', 'Hausa', '🇳🇬'),
  _AppLocale('yo', 'Yorùbá', '🇳🇬'),
  _AppLocale('ig', 'Igbo', '🇳🇬'),
  _AppLocale('hi', 'हिन्दी', '🇮🇳'),
];

class _AppLocale {
  const _AppLocale(this.code, this.name, this.flag);
  final String code;
  final String name;
  final String flag;
}

class LocaleNotifier extends Notifier<Locale> {
  late Box<dynamic> _box;

  @override
  Locale build() {
    _box = Hive.box<dynamic>(_kBoxPrefs);
    final saved = _box.get(_kKeyLocale, defaultValue: 'en') as String;
    return Locale(saved);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _box.put(_kKeyLocale, languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

final appLocalesProvider = Provider<List<_AppLocale>>((_) => appLocales);
