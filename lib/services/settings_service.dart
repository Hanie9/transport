import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();
  factory SettingsService() => instance;

  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';

  /// App preferences stored in SharedPreferences — survive logout and session
  /// expiry. They are removed only when the app is uninstalled or app data is cleared.

  Locale _locale = const Locale('fa', 'IR');
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode == 'en') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('fa', 'IR');
    }

    final themeModeName = prefs.getString(_themeModeKey);
    _themeMode = switch (themeModeName) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };

    _initialized = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> toggleDarkMode(bool enabled) => setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);

  Future<void> setEnglish(bool enabled) => setLocale(
        enabled ? const Locale('en', 'US') : const Locale('fa', 'IR'),
      );
}
