import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

class TranslationGameService {
  // Map pour stocker les traducteurs par paire de langues
  final Map<String, OnDeviceTranslator> _translators = {};
  
  TranslationGameService() {
    _initialize();
  }
  
  void _initialize() {
    // Initialisation différée - les traducteurs sont créés à la demande
    debugPrint('TranslationGameService initialisé');
  }
  
  // Traduire un texte
  Future<String> translateText(String text, String sourceLang, String targetLang) async {
    if (sourceLang == targetLang) return text;
    
    final key = '$sourceLang-$targetLang';
    
    if (!_translators.containsKey(key)) {
      final source = _mapLanguageCode(sourceLang);
      final target = _mapLanguageCode(targetLang);
      
      if (source == null || target == null) {
        debugPrint('Langue non supportée: $sourceLang -> $targetLang');
        return text;
      }
      
      try {
        _translators[key] = OnDeviceTranslator(
          sourceLanguage: source,
          targetLanguage: target,
        );
      } catch (e) {
        debugPrint('Erreur création traducteur: $e');
        return text;
      }
    }
    
    try {
      final translator = _translators[key]!;
      final translatedText = await translator.translateText(text);
      return translatedText;
    } catch (e) {
      debugPrint('Erreur traduction: $e');
      return text;
    }
  }
  
  // Traduire dans plusieurs langues
  Future<Map<String, String>> translateToMultipleLanguages(
    String text,
    String sourceLang,
    List<String> targetLanguages,
  ) async {
    final results = <String, String>{};
    
    for (final targetLang in targetLanguages) {
      if (targetLang != sourceLang) {
        results[targetLang] = await translateText(text, sourceLang, targetLang);
      } else {
        results[targetLang] = text;
      }
    }
    
    return results;
  }
  
  // Vérifier si une traduction est correcte
  Future<bool> verifyTranslation(
    String userInput,
    String expectedTranslation,
    String sourceLang,
    String targetLang,
  ) async {
    try {
      // Normaliser les entrées
      final normalizedUser = _normalizeText(userInput);
      final normalizedExpected = _normalizeText(expectedTranslation);
      
      // Vérification exacte
      if (normalizedUser == normalizedExpected) {
        return true;
      }
      
      // Vérification avec tolérance (pour les fautes de frappe)
      if (_isCloseMatch(normalizedUser, normalizedExpected)) {
        return true;
      }
      
      // Vérification via traduction inverse
      final backTranslation = await translateText(userInput, targetLang, sourceLang);
      final normalizedBack = _normalizeText(backTranslation);
      
      return normalizedBack == normalizedExpected;
    } catch (e) {
      debugPrint('Erreur vérification traduction: $e');
      return false;
    }
  }
  
  // Vérifier si deux mots sont proches (tolérance aux fautes)
  bool _isCloseMatch(String input, String target) {
    if (input.isEmpty || target.isEmpty) return false;
    
    // Différence de longueur max de 2 caractères
    if ((input.length - target.length).abs() > 2) return false;
    
    int differences = 0;
    final minLength = input.length < target.length ? input.length : target.length;
    
    for (int i = 0; i < minLength; i++) {
      if (i < input.length && i < target.length && input[i] != target[i]) {
        differences++;
      }
      if (differences > 2) return false;
    }
    
    // Prendre en compte la différence de longueur
    differences += (input.length - target.length).abs();
    
    return differences > 0 && differences <= 2;
  }
  
  // Normaliser le texte (minuscules, sans accents, sans ponctuation)
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
        .replaceAll('î', 'i')
        .replaceAll('ÿ', 'y')
        .replaceAll('ñ', 'n');
  }
  
  // Convertir un code de langue en enum TranslateLanguage
  TranslateLanguage? _mapLanguageCode(String code) {
    switch (code.toLowerCase()) {
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
      case 'nl':
        return TranslateLanguage.dutch;
      case 'ru':
        return TranslateLanguage.russian;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'hi':
        return TranslateLanguage.hindi;
      default:
        return null;
    }
  }
  
  // Obtenir la liste des langues supportées
  List<String> getSupportedLanguages() {
    return [
      'fr', 'en', 'es', 'de', 'it', 'pt', 'nl', 'ru', 'zh', 'ja', 'ar', 'hi'
    ];
  }
  
  // Vérifier si une langue est supportée
  bool isLanguageSupported(String languageCode) {
    return _mapLanguageCode(languageCode) != null;
  }
  
  // Nettoyage des ressources
  void dispose() {
    for (final translator in _translators.values) {
      try {
        translator.close();
      } catch (e) {
        debugPrint('Erreur fermeture traducteur: $e');
      }
    }
    _translators.clear();
    debugPrint('TranslationGameService disposé');
  }
}