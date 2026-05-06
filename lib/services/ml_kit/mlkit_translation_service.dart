import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

class MLKitTranslationService {
  final Map<String, OnDeviceTranslator> _translators = {};
  bool _isModelDownloaded = false;
  
  // Liste des langues supportées par ML Kit Translation
  static const List<String> supportedLanguages = [
    'fr', 'en', 'es', 'de', 'it', 'pt', 'nl', 'ru', 'zh', 'ja', 'ar', 'hi'
  ];
  
  Future<void> downloadModel(String languageCode) async {
    if (_isModelDownloaded) return;
    
    try {
      final language = _mapLanguageCode(languageCode);
      if (language != null) {
        final manager = OnDeviceTranslatorModelManager();
        // ✅ Correction: downloadModel attend un String, pas TranslateLanguage
        // Utiliser le code de langue en String
        final languageString = _getLanguageString(language);
        await manager.downloadModel(languageString);
        _isModelDownloaded = true;
        debugPrint('✅ Modèle de traduction téléchargé pour: $languageCode');
      }
    } catch (e) {
      debugPrint('❌ Erreur téléchargement modèle: $e');
    }
  }
  
  String _getLanguageString(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.french: return 'fr';
      case TranslateLanguage.english: return 'en';
      case TranslateLanguage.spanish: return 'es';
      case TranslateLanguage.german: return 'de';
      case TranslateLanguage.italian: return 'it';
      case TranslateLanguage.portuguese: return 'pt';
      case TranslateLanguage.dutch: return 'nl';
      case TranslateLanguage.russian: return 'ru';
      case TranslateLanguage.chinese: return 'zh';
      case TranslateLanguage.japanese: return 'ja';
      case TranslateLanguage.arabic: return 'ar';
      case TranslateLanguage.hindi: return 'hi';
      default: return 'en';
    }
  }
  
  Future<String> translateText(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    if (sourceLang == targetLang) return text;
    if (text.isEmpty) return text;
    
    final key = '$sourceLang-$targetLang';
    
    try {
      if (!_translators.containsKey(key)) {
        final source = _mapLanguageCode(sourceLang);
        final target = _mapLanguageCode(targetLang);
        
        if (source == null || target == null) {
          debugPrint('⚠️ Langue non supportée: $sourceLang -> $targetLang');
          return text;
        }
        
        _translators[key] = OnDeviceTranslator(
          sourceLanguage: source,
          targetLanguage: target,
        );
      }
      
      final translator = _translators[key]!;
      final translatedText = await translator.translateText(text);
      return translatedText;
    } catch (e) {
      debugPrint('❌ Erreur traduction: $e');
      return text;
    }
  }
  
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
  
  TranslateLanguage? _mapLanguageCode(String code) {
    switch (code.toLowerCase()) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'es': return TranslateLanguage.spanish;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'nl': return TranslateLanguage.dutch;
      case 'ru': return TranslateLanguage.russian;
      case 'zh': return TranslateLanguage.chinese;
      case 'ja': return TranslateLanguage.japanese;
      case 'ar': return TranslateLanguage.arabic;
      case 'hi': return TranslateLanguage.hindi;
      default: return null;
    }
  }
  
  void dispose() {
    for (final translator in _translators.values) {
      try {
        translator.close();
      } catch (e) {
        debugPrint('Erreur fermeture traducteur: $e');
      }
    }
    _translators.clear();
  }
}