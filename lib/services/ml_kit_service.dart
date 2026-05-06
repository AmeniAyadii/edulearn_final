import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/material.dart';

// Classes personnalisées pour remplacer les packages manquants
class Entity {
  final String text;
  final EntityType type;
  final int startIndex;
  final int endIndex;
  
  Entity({
    required this.text,
    required this.type,
    required this.startIndex,
    required this.endIndex,
  });
}

enum EntityType {
  address,
  dateTime,
  email,
  phoneNumber,
  url,
  person,
  location,
  organization,
  unknown,
}

class Message {
  final String text;
  final DateTime timestamp;
  final bool isUser;
  
  Message({
    required this.text,
    required this.timestamp,
    required this.isUser,
  });
}

class MLKitService {
  // Language Identification
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  
  // Translation
  OnDeviceTranslator? _currentTranslator;
  
  // Language Identification
  Future<List<IdentifiedLanguage>> identifyLanguage(String text) async {
    try {
      return await _languageIdentifier.identifyPossibleLanguages(text);
    } catch (e) {
      print('Error identifying language: $e');
      return [];
    }
  }
  
  // Get language name from code
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
    };
    return languages[languageCode] ?? languageCode;
  }
  
  // Translation - Version corrigée sans loadModel()
  Future<String?> translateText(String text, String sourceLang, String targetLang) async {
    if (text.trim().isEmpty) return null;
    
    try {
      // Créer un nouveau traducteur
      final translator = OnDeviceTranslator(
        sourceLanguage: _getTranslateLanguage(sourceLang),
        targetLanguage: _getTranslateLanguage(targetLang),
      );
      
      // Dans les versions récentes, le modèle est chargé automatiquement
      // lors du premier appel à translateText
      final translatedText = await translator.translateText(text);
      
      // Fermer le traducteur pour libérer les ressources
      await translator.close();
      
      return translatedText;
    } catch (e) {
      print('Error translating text: $e');
      return null;
    }
  }
  
  // Version alternative avec gestion de cache
  Future<String?> translateTextWithCache(String text, String sourceLang, String targetLang) async {
    if (text.trim().isEmpty) return null;
    
    try {
      // Réutiliser le traducteur si les langues sont les mêmes
      if (_currentTranslator != null) {
        // Vérifier si les langues ont changé
        // Note: On ne peut pas vérifier directement, donc on recrée
        await _currentTranslator?.close();
      }
      
      _currentTranslator = OnDeviceTranslator(
        sourceLanguage: _getTranslateLanguage(sourceLang),
        targetLanguage: _getTranslateLanguage(targetLang),
      );
      
      // Traduire directement (le chargement du modèle est automatique)
      final translatedText = await _currentTranslator!.translateText(text);
      
      return translatedText;
    } catch (e) {
      print('Error translating text: $e');
      return null;
    }
  }
  
  TranslateLanguage _getTranslateLanguage(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'fr':
        return TranslateLanguage.french;
      case 'en':
        return TranslateLanguage.english;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'es':
        return TranslateLanguage.spanish;
      case 'de':
        return TranslateLanguage.german;
      case 'it':
        return TranslateLanguage.italian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ru':
        return TranslateLanguage.russian;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      default:
        return TranslateLanguage.english;
    }
  }
  
  // Smart Reply Suggestions
  Future<List<String>> getSmartReplies(List<Message> conversation) async {
    if (conversation.isEmpty) return [];
    
    final lastMessage = conversation.last.text.toLowerCase();
    final List<String> suggestions = [];
    
    // Logique de suggestions basée sur des mots-clés
    if (lastMessage.contains('bonjour') || lastMessage.contains('hello') || lastMessage.contains('salut')) {
      suggestions.addAll(['Bonjour !', 'Salut, comment ça va ?', 'Hey !']);
    } else if (lastMessage.contains('comment') || lastMessage.contains('how')) {
      suggestions.addAll(['Bien, merci !', 'Ça va, et toi ?', 'Très bien, merci de demander']);
    } else if (lastMessage.contains('merci') || lastMessage.contains('thanks')) {
      suggestions.addAll(['De rien !', 'Avec plaisir !', 'Pas de problème']);
    } else if (lastMessage.contains('?') || lastMessage.contains('?')) {
      suggestions.addAll(['Oui', 'Non', 'Peut-être', 'Je ne sais pas']);
    } else if (lastMessage.contains('prix') || lastMessage.contains('coût') || lastMessage.contains('tarif')) {
      suggestions.addAll(['Combien ça coûte ?', 'Quel est le prix ?', 'C\'est combien ?']);
    } else if (lastMessage.contains('heure') || lastMessage.contains('time')) {
      suggestions.addAll(['À quelle heure ?', 'Quand ?', 'Quel est l\'horaire ?']);
    } else {
      suggestions.addAll(['D\'accord', 'Intéressant', 'Je vois', 'Ok', 'Merci']);
    }
    
    return suggestions;
  }
  
  // Entity Extraction avec regex améliorés
  Future<List<Entity>> extractEntities(String text) async {
    final List<Entity> entities = [];
    
    // Extraction des emails
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    for (final match in emailRegex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: EntityType.email,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extraction des numéros de téléphone (format international et français)
    final phoneRegex = RegExp(r'(\+\d{1,3}[- ]?)?(0[1-9]|\(0[1-9]\))[- ]?\d{2}[- ]?\d{2}[- ]?\d{2}[- ]?\d{2}|(\+\d{1,3}[- ]?)?\d{9,10}');
    for (final match in phoneRegex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: EntityType.phoneNumber,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extraction des URLs
    final urlRegex = RegExp(r'(https?:\/\/)?(www\.)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?');
    for (final match in urlRegex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: EntityType.url,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extraction des dates
    final dateRegex = RegExp(
      r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|'
      r'\d{1,2} (janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre) \d{4}|'
      r'(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche) \d{1,2} (janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre) \d{4}'
    );
    for (final match in dateRegex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: EntityType.dateTime,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    // Extraction des adresses (simple)
    final addressRegex = RegExp(r'\d{1,5}\s+rue\s+\w+|\d{1,5}\s+avenue\s+\w+|\d{1,5}\s+boulevard\s+\w+');
    for (final match in addressRegex.allMatches(text)) {
      entities.add(Entity(
        text: match.group(0)!,
        type: EntityType.address,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    
    return entities;
  }
  
  // Get entity type name en français
  String getEntityTypeName(EntityType type) {
    switch (type) {
      case EntityType.address:
        return 'Adresse';
      case EntityType.dateTime:
        return 'Date/Heure';
      case EntityType.email:
        return 'Email';
      case EntityType.phoneNumber:
        return 'Téléphone';
      case EntityType.url:
        return 'URL';
      case EntityType.person:
        return 'Personne';
      case EntityType.location:
        return 'Lieu';
      case EntityType.organization:
        return 'Organisation';
      case EntityType.unknown:
        return 'Inconnu';
    }
  }
  
  // Obtenir l'icône pour le type d'entité
  IconData getEntityIcon(EntityType type) {
    switch (type) {
      case EntityType.address:
        return Icons.location_on;
      case EntityType.dateTime:
        return Icons.calendar_today;
      case EntityType.email:
        return Icons.email;
      case EntityType.phoneNumber:
        return Icons.phone;
      case EntityType.url:
        return Icons.link;
      case EntityType.person:
        return Icons.person;
      case EntityType.location:
        return Icons.place;
      case EntityType.organization:
        return Icons.business;
      case EntityType.unknown:
        return Icons.help_outline;
    }
  }
  
  // Obtenir la couleur pour le type d'entité
  Color getEntityColor(EntityType type) {
    switch (type) {
      case EntityType.address:
        return Colors.orange;
      case EntityType.dateTime:
        return Colors.green;
      case EntityType.email:
        return Colors.blue;
      case EntityType.phoneNumber:
        return Colors.purple;
      case EntityType.url:
        return Colors.teal;
      case EntityType.person:
        return Colors.red;
      case EntityType.location:
        return Colors.brown;
      case EntityType.organization:
        return Colors.indigo;
      case EntityType.unknown:
        return Colors.grey;
    }
  }
  
  void dispose() async {
    _languageIdentifier.close();
    await _currentTranslator?.close();
  }
}

