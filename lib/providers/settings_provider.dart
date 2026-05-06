import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  String _currentLanguage = 'fr';
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get notifications => _notifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs.getString('language') ?? 'fr';
    _notifications = _prefs.getBool('notifications') ?? true;
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
    
    final isDark = _prefs.getBool('dark_mode');
    if (isDark == true) {
      _themeMode = ThemeMode.dark;
    } else if (isDark == false) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _prefs.setString('language', languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setBool('dark_mode', mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
  if (_themeMode == ThemeMode.light) {
    _themeMode = ThemeMode.dark;
    await _prefs.setBool('dark_mode', true);
  } else if (_themeMode == ThemeMode.dark) {
    _themeMode = ThemeMode.light;
    await _prefs.setBool('dark_mode', false);
  } else {
    // Si c'est system, passer en light par défaut
    _themeMode = ThemeMode.light;
    await _prefs.setBool('dark_mode', false);
  }
  notifyListeners();
}

  Future<void> setNotifications(bool enabled) async {
    _notifications = enabled;
    await _prefs.setBool('notifications', enabled);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs.setBool('sound_enabled', enabled);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs.setBool('vibration_enabled', enabled);
    notifyListeners();
  }

  Locale get locale {
    switch (_currentLanguage) {
      case 'en':
        return const Locale('en', '');
      case 'ar':
        return const Locale('ar', '');
      default:
        return const Locale('fr', '');
    }
  }
}