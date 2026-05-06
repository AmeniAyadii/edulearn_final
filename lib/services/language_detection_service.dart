// lib/services/language_detection_service.dart - Version hybride
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LanguageDetectionService {
  late final LanguageIdentifier _languageIdentifier;
  
  LanguageDetectionService() {
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  }

  Future<Map<String, dynamic>> detectLanguage(String text) async {
    try {
      // Utiliser identifyPossibleLanguages qui retourne une List
      final List<IdentifiedLanguage> languages = await _languageIdentifier.identifyPossibleLanguages(text);
      
      if (languages.isEmpty) {
        return _fallbackDetection(text);
      }
      
      final bestMatch = languages.first;
      
      return {
        'success': true,
        'languageCode': bestMatch.languageTag,
        'confidence': bestMatch.confidence,
      };
    } catch (e) {
      print('Erreur détection langue: $e');
      return _fallbackDetection(text);
    }
  }

  Map<String, dynamic> _fallbackDetection(String text) {
    // Fallback basé sur les caractères
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return {'success': true, 'languageCode': 'ar', 'confidence': 0.8};
    } else if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(text)) {
      return {'success': true, 'languageCode': 'ja', 'confidence': 0.8};
    } else if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) {
      return {'success': true, 'languageCode': 'ru', 'confidence': 0.8};
    } else if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) {
      return {'success': true, 'languageCode': 'ko', 'confidence': 0.8};
    }
    
    return {'success': false, 'languageCode': null, 'confidence': 0.0};
  }

  Future<String?> translateText(String text, String targetLanguage) async {
    try {
      final targetLang = _getTranslateLanguage(targetLanguage);
      
      final translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.french,
        targetLanguage: targetLang,
      );
      final translated = await translator.translateText(text);
      await translator.close();
      return translated;
    } catch (e) {
      print('Erreur traduction: $e');
      return null;
    }
  }

  TranslateLanguage _getTranslateLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'es': return TranslateLanguage.spanish;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'ar': return TranslateLanguage.arabic;
      case 'ja': return TranslateLanguage.japanese;
      case 'ru': return TranslateLanguage.russian;
      case 'ko': return TranslateLanguage.korean;
      case 'hi': return TranslateLanguage.hindi;
      case 'tr': return TranslateLanguage.turkish;
      case 'th': return TranslateLanguage.thai;
      default: return TranslateLanguage.english;
    }
  }

  void dispose() {
    _languageIdentifier.close();
  }
}