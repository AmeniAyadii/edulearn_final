import 'dart:math';

import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/material.dart';

// ============================================================================
// MODÈLES DE DONNÉES
// ============================================================================

/// Représente une entité extraite d'un texte
class Entity {
  final String text;
  final EntityType type;
  final int startIndex;
  final int endIndex;
  final double confidence;
  
  const Entity({
    required this.text,
    required this.type,
    required this.startIndex,
    required this.endIndex,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type.name,
    'startIndex': startIndex,
    'endIndex': endIndex,
    'confidence': confidence,
  };

  @override
  String toString() => 'Entity(text: $text, type: $type)';
}

/// Types d'entités reconnues
enum EntityType {
  address('Adresse', Icons.location_on, Colors.orange),
  dateTime('Date/Heure', Icons.calendar_today, Colors.green),
  email('Email', Icons.email, Colors.blue),
  phoneNumber('Téléphone', Icons.phone, Colors.purple),
  url('URL', Icons.link, Colors.teal),
  person('Personne', Icons.person, Colors.red),
  location('Lieu', Icons.place, Colors.brown),
  organization('Organisation', Icons.business, Colors.indigo),
  number('Nombre', Icons.numbers, Colors.cyan),
  currency('Monnaie', Icons.attach_money, Color.fromARGB(255, 36, 133, 41)),
  unknown('Inconnu', Icons.help_outline, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;
  
  const EntityType(this.label, this.icon, this.color);
}

/// Représente un message pour les suggestions de réponses
class Message {
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final String? userId;
  
  const Message({
    required this.text,
    required this.timestamp,
    required this.isUser,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isUser': isUser,
    'userId': userId,
  };
}

/// Résultat de traduction avec métadonnées
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final double confidence;
  final DateTime timestamp;
  final bool fromCache;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.confidence = 1.0,
    required this.timestamp,
    this.fromCache = false,
  });

  @override
  String toString() => 'TranslationResult: $originalText -> $translatedText';
}

// ============================================================================
// SERVICE PRINCIPAL
// ============================================================================

/// Service ML Kit complet avec gestion avancée
class KitService {
  // Singleton
  static final KitService _instance = KitService._internal();
  factory KitService() => _instance;
  KitService._internal();

  // Services ML Kit
  late final LanguageIdentifier _languageIdentifier;
  OnDeviceTranslator? _currentTranslator;
  
  // Cache
  final Map<String, TranslationResult> _translationCache = {};
  final Map<String, List<IdentifiedLanguage>> _languageCache = {};
  
  // Configuration
  static const int _maxCacheSize = 1000;
  static const double _defaultConfidenceThreshold = 0.5;
  
  // État
  bool _isInitialized = false;
  String? _currentSourceLang;
  String? _currentTargetLang;

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _languageIdentifier = LanguageIdentifier(
        confidenceThreshold: _defaultConfidenceThreshold,
      );
      _isInitialized = true;
      print('✅ KitService initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  // ============================================================================
  // IDENTIFICATION DE LANGUE
  // ============================================================================

  /// Identifie les langues possibles d'un texte
  Future<List<IdentifiedLanguage>> identifyLanguage(String text) async {
    await initialize();
    
    if (text.trim().isEmpty) return [];
    
    // Vérifier le cache
    final cacheKey = text.toLowerCase().substring(0, min(50, text.length));
    if (_languageCache.containsKey(cacheKey)) {
      return _languageCache[cacheKey]!;
    }
    
    try {
      final result = await _languageIdentifier.identifyPossibleLanguages(text);
      
      // Mettre en cache
      if (_languageCache.length > _maxCacheSize) {
        _languageCache.clear();
      }
      _languageCache[cacheKey] = result;
      
      return result;
    } catch (e) {
      print('Erreur identification langue: $e');
      return [];
    }
  }

  /// Identifie la langue principale d'un texte
  Future<IdentifiedLanguage?> identifyPrimaryLanguage(String text) async {
    final languages = await identifyLanguage(text);
    return languages.isNotEmpty ? languages.first : null;
  }

  /// Obtient le nom complet d'une langue à partir de son code
  String getLanguageName(String languageCode) {
    final languages = {
      'fr': 'Français',
      'en': 'English',
      'ar': 'العربية',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'nl': 'Nederlands',
      'pl': 'Polski',
      'tr': 'Türkçe',
      'vi': 'Tiếng Việt',
    };
    return languages[languageCode] ?? languageCode.toUpperCase();
  }

  /// Obtient le drapeau d'une langue
  String getLanguageFlag(String languageCode) {
    final flags = {
      'fr': '🇫🇷',
      'en': '🇬🇧',
      'ar': '🇸🇦',
      'es': '🇪🇸',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'zh': '🇨🇳',
      'ja': '🇯🇵',
    };
    return flags[languageCode] ?? '🌐';
  }

  // ============================================================================
  // TRADUCTION
  // ============================================================================

  /// Traduit un texte avec gestion de cache
  Future<TranslationResult?> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    bool useCache = true,
  }) async {
    await initialize();
    
    if (text.trim().isEmpty) return null;
    if (sourceLang == targetLang) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: 1.0,
        timestamp: DateTime.now(),
        fromCache: false,
      );
    }
    
    final cacheKey = _getCacheKey(text, sourceLang, targetLang);
    
    // Vérifier le cache
    if (useCache && _translationCache.containsKey(cacheKey)) {
      final cached = _translationCache[cacheKey]!;
      return TranslationResult(
        originalText: cached.originalText,
        translatedText: cached.translatedText,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: cached.confidence,
        timestamp: DateTime.now(),
        fromCache: true,
      );
    }
    
    // Traduction rapide pour les mots courts
    if (text.length <= 10) {
      final quickResult = _quickTranslate(text, sourceLang, targetLang);
      if (quickResult != text) {
        final result = TranslationResult(
          originalText: text,
          translatedText: quickResult,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          confidence: 0.95,
          timestamp: DateTime.now(),
          fromCache: false,
        );
        _addToCache(cacheKey, result);
        return result;
      }
    }
    
    try {
      // Créer le traducteur
      final translator = OnDeviceTranslator(
        sourceLanguage: _getTranslateLanguage(sourceLang),
        targetLanguage: _getTranslateLanguage(targetLang),
      );
      
      // Traduire
      final translatedText = await translator.translateText(text);
      await translator.close();
      
      if (translatedText == null || translatedText.isEmpty) {
        return null;
      }
      
      final result = TranslationResult(
        originalText: text,
        translatedText: translatedText,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: 0.98,
        timestamp: DateTime.now(),
        fromCache: false,
      );
      
      _addToCache(cacheKey, result);
      return result;
      
    } catch (e) {
      print('Erreur traduction: $e');
      
      // Fallback: traduction par dictionnaire
      final fallbackResult = _quickTranslate(text, sourceLang, targetLang);
      if (fallbackResult != text) {
        return TranslationResult(
          originalText: text,
          translatedText: fallbackResult,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
          confidence: 0.5,
          timestamp: DateTime.now(),
          fromCache: false,
        );
      }
      
      return null;
    }
  }

  /// Traduction par dictionnaire pour les mots courts
  String _quickTranslate(String text, String sourceLang, String targetLang) {
    final lowerText = text.toLowerCase().trim();
    
    // Dictionnaire complet
    final Map<String, Map<String, Map<String, String>>> dictionary = {
      'fr': {
        'en': {
          // Animaux
          'chat': 'cat', 'chien': 'dog', 'oiseau': 'bird', 'poisson': 'fish',
          'souris': 'mouse', 'lapin': 'rabbit', 'cheval': 'horse', 'vache': 'cow',
          // Fruits
          'pomme': 'apple', 'banane': 'banana', 'orange': 'orange', 'fraise': 'strawberry',
          'poire': 'pear', 'raisin': 'grape', 'cerise': 'cherry', 'melon': 'melon',
          // Couleurs
          'rouge': 'red', 'bleu': 'blue', 'vert': 'green', 'jaune': 'yellow',
          'noir': 'black', 'blanc': 'white', 'gris': 'grey', 'rose': 'pink',
          'violet': 'purple', 'marron': 'brown',
          // Adjectifs
          'grand': 'big', 'petit': 'small', 'chaud': 'hot', 'froid': 'cold',
          'content': 'happy', 'triste': 'sad', 'fatigué': 'tired', 'rapide': 'fast',
          'lent': 'slow', 'bon': 'good', 'mauvais': 'bad', 'beau': 'beautiful',
          // Verbes
          'manger': 'eat', 'boire': 'drink', 'dormir': 'sleep', 'courir': 'run',
          'marcher': 'walk', 'lire': 'read', 'écrire': 'write', 'parler': 'speak',
          // Salutations
          'bonjour': 'hello', 'merci': 'thank you', 'au revoir': 'goodbye',
          'oui': 'yes', 'non': 'no', 's\'il vous plaît': 'please',
          // Objets
          'livre': 'book', 'école': 'school', 'maison': 'house', 'voiture': 'car',
          'téléphone': 'phone', 'ordinateur': 'computer', 'table': 'table', 'chaise': 'chair',
          // Famille
          'papa': 'dad', 'maman': 'mom', 'frère': 'brother', 'sœur': 'sister',
          'grand-père': 'grandfather', 'grand-mère': 'grandmother',
        },
        'ar': {
          'chat': 'قط', 'chien': 'كلب', 'oiseau': 'طائر',
          'pomme': 'تفاحة', 'banane': 'موز', 'orange': 'برتقال',
          'rouge': 'أحمر', 'bleu': 'أزرق', 'vert': 'أخضر', 'jaune': 'أصفر',
          'grand': 'كبير', 'petit': 'صغير',
          'bonjour': 'مرحبا', 'merci': 'شكرا', 'oui': 'نعم', 'non': 'لا',
          'livre': 'كتاب', 'école': 'مدرسة', 'maison': 'منزل',
          'papa': 'أبي', 'maman': 'أمي',
        },
      },
      'en': {
        'fr': {
          'cat': 'chat', 'dog': 'chien', 'bird': 'oiseau', 'fish': 'poisson',
          'mouse': 'souris', 'rabbit': 'lapin', 'horse': 'cheval', 'cow': 'vache',
          'apple': 'pomme', 'banana': 'banane', 'orange': 'orange', 'strawberry': 'fraise',
          'pear': 'poire', 'grape': 'raisin', 'cherry': 'cerise', 'melon': 'melon',
          'red': 'rouge', 'blue': 'bleu', 'green': 'vert', 'yellow': 'jaune',
          'black': 'noir', 'white': 'blanc', 'grey': 'gris', 'pink': 'rose',
          'purple': 'violet', 'brown': 'marron',
          'big': 'grand', 'small': 'petit', 'hot': 'chaud', 'cold': 'froid',
          'happy': 'content', 'sad': 'triste', 'tired': 'fatigué', 'fast': 'rapide',
          'slow': 'lent', 'good': 'bon', 'bad': 'mauvais', 'beautiful': 'beau',
          'eat': 'manger', 'drink': 'boire', 'sleep': 'dormir', 'run': 'courir',
          'walk': 'marcher', 'read': 'lire', 'write': 'écrire', 'speak': 'parler',
          'hello': 'bonjour', 'thank you': 'merci', 'goodbye': 'au revoir',
          'yes': 'oui', 'no': 'non', 'please': 's\'il vous plaît',
          'book': 'livre', 'school': 'école', 'house': 'maison', 'car': 'voiture',
          'phone': 'téléphone', 'computer': 'ordinateur', 'table': 'table', 'chair': 'chaise',
          'dad': 'papa', 'mom': 'maman', 'brother': 'frère', 'sister': 'sœur',
          'grandfather': 'grand-père', 'grandmother': 'grand-mère',
        },
      },
      'ar': {
        'fr': {
          'قط': 'chat', 'كلب': 'chien', 'طائر': 'oiseau',
          'تفاحة': 'pomme', 'موز': 'banane', 'برتقال': 'orange',
          'أحمر': 'rouge', 'أزرق': 'bleu', 'أخضر': 'vert', 'أصفر': 'jaune',
          'كبير': 'grand', 'صغير': 'petit',
          'مرحبا': 'bonjour', 'شكرا': 'merci', 'نعم': 'oui', 'لا': 'non',
          'كتاب': 'livre', 'مدرسة': 'école', 'منزل': 'maison',
          'أبي': 'papa', 'أمي': 'maman',
        },
      },
    };
    
    // Chercher dans le dictionnaire
    if (dictionary.containsKey(sourceLang) &&
        dictionary[sourceLang]!.containsKey(targetLang)) {
      if (dictionary[sourceLang]![targetLang]!.containsKey(lowerText)) {
        return dictionary[sourceLang]![targetLang]![lowerText]!;
      }
    }
    
    // Chercher dans le sens inverse
    if (dictionary.containsKey(targetLang) &&
        dictionary[targetLang]!.containsKey(sourceLang)) {
      for (final entry in dictionary[targetLang]![sourceLang]!.entries) {
        if (entry.value == lowerText) {
          return entry.key;
        }
      }
    }
    
    return text;
  }

  String _getCacheKey(String text, String sourceLang, String targetLang) {
    return '${sourceLang}_${targetLang}_${text.toLowerCase().trim()}';
  }

  void _addToCache(String key, TranslationResult result) {
    if (_translationCache.length > _maxCacheSize) {
      _translationCache.clear();
    }
    _translationCache[key] = result;
  }

  TranslateLanguage _getTranslateLanguage(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'ar': return TranslateLanguage.arabic;
      case 'es': return TranslateLanguage.spanish;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ru': return TranslateLanguage.russian;
      case 'zh': return TranslateLanguage.chinese;
      case 'ja': return TranslateLanguage.japanese;
      case 'ko': return TranslateLanguage.korean;
      case 'nl': return TranslateLanguage.dutch;
      case 'pl': return TranslateLanguage.polish;
      case 'tr': return TranslateLanguage.turkish;
      default: return TranslateLanguage.english;
    }
  }

  // ============================================================================
  // SUGGESTIONS DE RÉPONSES
  // ============================================================================

  /// Génère des suggestions de réponses intelligentes
  Future<List<String>> getSmartReplies(List<Message> conversation) async {
    if (conversation.isEmpty) return [];
    
    final lastMessage = conversation.last.text.toLowerCase();
    final Set<String> suggestions = {};
    
    // Patterns de reconnaissance
    final patterns = {
      r'\b(bonjour|salut|hello|hey|coucou)\b': ['Bonjour !', 'Salut, comment ça va ?', 'Hey !'],
      r'\b(comment ça va|how are you|ça va|comment vas-tu)\b': ['Bien, merci !', 'Ça va, et toi ?', 'Très bien, merci'],
      r'\b(merci|thanks|thank you)\b': ['De rien !', 'Avec plaisir !', 'Pas de problème'],
      r'\?$': ['Oui', 'Non', 'Peut-être', 'Je ne sais pas'],
      r'\b(prix|coût|tarif|combien)\b': ['Combien ça coûte ?', 'Quel est le prix ?', 'C\'est combien ?'],
      r'\b(heure|quand|time|moment)\b': ['À quelle heure ?', 'Quand ?', 'Quel est l\'horaire ?'],
      r'\b(où|location|endroit|place)\b': ['Où ça ?', 'Quel est l\'adresse ?', 'Où se trouve-t-il ?'],
      r'\b(pourquoi|reason|cause)\b': ['Pourquoi ?', 'Quelle est la raison ?', 'Explique-moi'],
      r'\b(qui|personne|who)\b': ['Qui ?', 'De qui parles-tu ?', 'Quelle personne ?'],
      r'\b(quand|date|moment)\b': ['Quand ?', 'À quelle date ?', 'C\'est quand ?'],
    };
    
    for (final entry in patterns.entries) {
      final regex = RegExp(entry.key, caseSensitive: false);
      if (regex.hasMatch(lastMessage)) {
        suggestions.addAll(entry.value);
      }
    }
    
    // Suggestions par défaut
    if (suggestions.isEmpty) {
      suggestions.addAll(['D\'accord', 'Intéressant', 'Je vois', 'Ok', 'Merci']);
    }
    
    return suggestions.take(6).toList();
  }

  // ============================================================================
  // EXTRACTION D'ENTITÉS
  // ============================================================================

  /// Extrait les entités d'un texte
  Future<List<Entity>> extractEntities(String text) async {
    final List<Entity> entities = [];
    
    // Email
    _addMatches(entities, text, RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), EntityType.email);
    
    // Téléphone (français et international)
    _addMatches(entities, text, RegExp(r'(\+\d{1,3}[- ]?)?(0[1-9]|\(0[1-9]\))[- ]?\d{2}[- ]?\d{2}[- ]?\d{2}[- ]?\d{2}|\+\d{1,3}[- ]?\d{9,10}'), EntityType.phoneNumber);
    
    // URL
    _addMatches(entities, text, RegExp(r'(https?:\/\/)?(www\.)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?'), EntityType.url);
    
    // Dates
    _addMatches(entities, text, RegExp(
      r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|'
      r'\d{1,2} (janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre) \d{4}',
      caseSensitive: false
    ), EntityType.dateTime);
    
    // Nombres
    _addMatches(entities, text, RegExp(r'\b\d+(?:[.,]\d+)?\b'), EntityType.number);
    
    // Monnaies
    _addMatches(entities, text, RegExp(r'\b\d+\s*(€|EUR|euros|euro|dollar|USD|\$)\b', caseSensitive: false), EntityType.currency);
    
    return entities;
  }

  void _addMatches(List<Entity> entities, String text, RegExp regex, EntityType type) {
    for (final match in regex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: type,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  void dispose() {
    _languageIdentifier.close();
    _currentTranslator?.close();
    _translationCache.clear();
    _languageCache.clear();
    print('🧹 KitService nettoyé');
  }
}

// ============================================================================
// EXTENSIONS UTILES
// ============================================================================

extension StringExtension on String {
  String get capitalized => '${this[0].toUpperCase()}${substring(1)}';
  
  bool get isEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  
  bool get isPhoneNumber => RegExp(r'^(\+\d{1,3}[- ]?)?\d{9,10}$').hasMatch(this);
  
  bool get isUrl => RegExp(r'^(https?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?$').hasMatch(this);
}