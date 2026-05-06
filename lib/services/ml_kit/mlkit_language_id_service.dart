import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:flutter/foundation.dart';

class MLKitLanguageIdService {
  late LanguageIdentifier _languageIdentifier;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      _isInitialized = true;
      debugPrint('✅ Language ID ML Kit initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Language ID: $e');
    }
  }
  
  Future<LanguageDetectionResult?> detectLanguage(String text) async {
    if (!_isInitialized) await initialize();
    if (text.trim().isEmpty) return null;
    
    try {
      // ✅ Dans les versions récentes, identifyLanguage retourne directement un String
      final String? languageTag = await _languageIdentifier.identifyLanguage(text);
      
      if (languageTag != null && languageTag.isNotEmpty) {
        // Récupérer la confiance via une autre méthode
        final double confidence = await _getConfidence(text, languageTag);
        
        return LanguageDetectionResult(
          languageCode: _mapToSimpleCode(languageTag),
          languageName: _getLanguageName(languageTag),
          confidence: confidence,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur détection langue: $e');
      return null;
    }
  }
  
  Future<double> _getConfidence(String text, String detectedLanguage) async {
    try {
      // Alternative: utiliser identifyPossibleLanguages pour avoir les scores
      final List<IdentifiedLanguage> possibleLanguages = 
          await _languageIdentifier.identifyPossibleLanguages(text);
      
      for (final lang in possibleLanguages) {
        if (lang.languageTag == detectedLanguage) {
          return lang.confidence;
        }
      }
      return 0.7; // Valeur par défaut si non trouvé
    } catch (e) {
      return 0.7;
    }
  }
  
  Future<bool> isCorrectLanguage(String text, String expectedLanguage) async {
    final result = await detectLanguage(text);
    if (result == null) return false;
    return result.languageCode == expectedLanguage && result.confidence > 0.6;
  }
  
  // Méthode alternative plus simple et fiable
  Future<Map<String, double>> detectAllLanguages(String text) async {
    if (!_isInitialized) await initialize();
    if (text.trim().isEmpty) return {};
    
    try {
      final List<IdentifiedLanguage> results = 
          await _languageIdentifier.identifyPossibleLanguages(text);
      
      final Map<String, double> languages = {};
      for (final lang in results) {
        languages[_mapToSimpleCode(lang.languageTag)] = lang.confidence;
      }
      return languages;
    } catch (e) {
      debugPrint('❌ Erreur détection langues: $e');
      return {};
    }
  }
  
  String _mapToSimpleCode(String languageTag) {
    final code = languageTag.split('_')[0];
    switch (code) {
      case 'fr': return 'fr';
      case 'en': return 'en';
      case 'es': return 'es';
      case 'de': return 'de';
      case 'it': return 'it';
      case 'pt': return 'pt';
      case 'nl': return 'nl';
      case 'ru': return 'ru';
      case 'zh': return 'zh';
      case 'ja': return 'ja';
      case 'ar': return 'ar';
      case 'hi': return 'hi';
      default: return 'unknown';
    }
  }
  
  String _getLanguageName(String languageTag) {
    const names = {
      'fr': 'Français',
      'en': 'English',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'nl': 'Nederlands',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ar': 'العربية',
      'hi': 'हिन्दी',
    };
    final code = languageTag.split('_')[0];
    return names[code] ?? 'Inconnu';
  }
  
  void dispose() {
    if (_isInitialized) {
      _languageIdentifier.close();
    }
  }
}

class LanguageDetectionResult {
  final String languageCode;
  final String languageName;
  final double confidence;
  
  LanguageDetectionResult({
    required this.languageCode,
    required this.languageName,
    required this.confidence,
  });
}