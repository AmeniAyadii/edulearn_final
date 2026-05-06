// lib/services/translation_game_service.dart
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'dart:io';
import '../models/translation_word.dart';

class TranslationGameService {
  late final OnDeviceTranslator _translator;
  
  TranslationGameService() {
    _initTranslator();
  }

  void _initTranslator() {
    try {
      // ✅ Utiliser TranslateLanguage enum au lieu de String
      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.french,      // Code pour français
        targetLanguage: TranslateLanguage.english,     // Code pour anglais
      );
    } catch (e) {
      print('Erreur initialisation traducteur: $e');
    }
  }

  Future<bool> checkTranslation(String userInput, TranslationWord targetWord) async {
    try {
      // Normaliser les entrées
      final normalizedUserInput = _normalizeText(userInput);
      final normalizedTarget = _normalizeText(targetWord.translation);
      
      // Vérification exacte
      if (normalizedUserInput == normalizedTarget) {
        return true;
      }
      
      // Vérification avec tolérance
      if (normalizedUserInput.contains(normalizedTarget) || 
          normalizedTarget.contains(normalizedUserInput)) {
        return true;
      }
      
      // Vérification avec erreurs courantes (1 lettre de différence)
      if (_isCloseMatch(normalizedUserInput, normalizedTarget)) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur vérification: $e');
      return false;
    }
  }

  bool _isCloseMatch(String input, String target) {
    if (input.length != target.length) return false;
    
    int differences = 0;
    for (int i = 0; i < input.length; i++) {
      if (input[i] != target[i]) differences++;
      if (differences > 2) return false;
    }
    return differences > 0 && differences <= 2;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i');
  }

  // Méthode utilitaire pour obtenir le code de langue
  TranslateLanguage getLanguageCode(String lang) {
    switch (lang.toLowerCase()) {
      case 'fr':
        return TranslateLanguage.french;
      case 'en':
        return TranslateLanguage.english;
      case 'es':
        return TranslateLanguage.spanish;
      case 'de':
        return TranslateLanguage.german;
      case 'it':
        return TranslateLanguage.italian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ar':
        return TranslateLanguage.arabic;
      default:
        return TranslateLanguage.english;
    }
  }

  void dispose() {
    try {
      _translator.close();
    } catch (e) {
      print('Erreur fermeture traducteur: $e');
    }
  }
}