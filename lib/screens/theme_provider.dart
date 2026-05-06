import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoading = true;
  
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  
  ThemeProvider() {
    loadThemePreference();
  }
  
  // Charger le thème depuis Firebase
  Future<void> loadThemePreference() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Charger depuis Firebase
        final savedTheme = await FirebaseThemeService.loadTheme(user.uid);
        if (savedTheme != null) {
          _isDarkMode = savedTheme;
        } else {
          // Valeur par défaut
          _isDarkMode = false;
        }
      } else {
        // Mode par défaut si non connecté
        _isDarkMode = false;
      }
    } catch (e) {
      print("Erreur chargement thème: $e");
      _isDarkMode = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Changer le thème
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    // Sauvegarder dans Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseThemeService.saveTheme(user.uid, _isDarkMode);
    }
  }
  
  // Définir le thème manuellement
  Future<void> setTheme(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;
    
    _isDarkMode = isDarkMode;
    notifyListeners();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseThemeService.saveTheme(user.uid, _isDarkMode);
    }
  }
  
  // Écouter les changements en temps réel (multi-appareils)
  void listenToThemeChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseThemeService.listenThemeChanges(user.uid).listen((isDarkMode) {
      if (isDarkMode != null && _isDarkMode != isDarkMode) {
        _isDarkMode = isDarkMode;
        notifyListeners();
      }
    });
  }
}