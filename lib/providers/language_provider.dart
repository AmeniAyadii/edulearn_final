// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  final LanguageService _languageService = LanguageService();
  String _currentLanguage = 'fr';
  bool _isInitialized = false;
  
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  
  LanguageProvider() {
    _initLanguage();
  }
  
  Future<void> _initLanguage() async {
    _currentLanguage = await _languageService.getLanguage();
    _isInitialized = true;
    notifyListeners();
    
    // Écouter les changements multi-appareils
    _languageService.watchLanguage().listen((language) {
      if (language != _currentLanguage && _isInitialized) {
        _currentLanguage = language;
        notifyListeners();
        debugPrint('🔄 Langue synchronisée: ${_languageService.getLanguageName(language)}');
      }
    });
  }
  
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    if (_currentLanguage == languageCode) return;
    
    await _languageService.changeLanguage(context, languageCode);
    _currentLanguage = languageCode;
    notifyListeners();
  }
  
  String getLanguageName(String code) {
    return _languageService.getLanguageName(code);
  }
  
  String getLanguageFlag(String code) {
    return _languageService.getLanguageFlag(code);
  }
}