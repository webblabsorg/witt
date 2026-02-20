/// ThemeMode provider — persisted to Hive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _kBoxPrefs = 'app_prefs';
const _kKeyTheme = 'theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  late Box<dynamic> _box;

  @override
  ThemeMode build() {
    _box = Hive.box<dynamic>(_kBoxPrefs);
    final saved = _box.get(_kKeyTheme, defaultValue: 'system') as String;
    return _fromString(saved);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _box.put(_kKeyTheme, _toString(mode));
  }

  static ThemeMode _fromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
