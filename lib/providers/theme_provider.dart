// lib/providers/theme_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // ✅ AJOUTER CETTE MÉTHODE
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  // Si vous utilisez Firebase Realtime Database
  void listenToThemeChanges() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final themeRef = FirebaseDatabase.instance.ref('users/$userId/theme/isDarkMode');
      themeRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          _isDarkMode = event.snapshot.value as bool;
          notifyListeners();
        }
      });
    }
  }
}