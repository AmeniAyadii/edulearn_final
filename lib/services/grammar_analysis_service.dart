import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:flutter/material.dart';

class WordGrammar {
  final String word;
  final PartOfSpeech pos;
  final SemanticCategory? semantic;
  final Color color;
  final String emoji;
  final double confidence;

  WordGrammar({
    required this.word,
    required this.pos,
    this.semantic,
    required this.color,
    required this.emoji,
    this.confidence = 1.0,
  });
}

enum PartOfSpeech {
  noun,        // Nom
  verb,        // Verbe
  adjective,   // Adjectif
  adverb,      // Adverbe
  pronoun,     // Pronom
  preposition, // Préposition
  conjunction, // Conjonction
  interjection,// Interjection
  properNoun,  // Nom propre
  number,      // Nombre
  unknown,     // Inconnu
}

enum SemanticCategory {
  person, animal, food, place, color, emotion,
  vehicle, nature, technology, sport, time, other
}

class GrammarAnalysisService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  late final EntityExtractor _entityExtractor;

  // Dictionnaire des mots (simplifié pour l'exemple)
  final Map<String, PartOfSpeech> _posDictionary = {
    // Verbes courants
    'manger': PartOfSpeech.verb,
    'boire': PartOfSpeech.verb,
    'dormir': PartOfSpeech.verb,
    'courir': PartOfSpeech.verb,
    'lire': PartOfSpeech.verb,
    'écrire': PartOfSpeech.verb,
    'parler': PartOfSpeech.verb,
    'chanter': PartOfSpeech.verb,
    'danser': PartOfSpeech.verb,
    'jouer': PartOfSpeech.verb,
    'travailler': PartOfSpeech.verb,
    'étudier': PartOfSpeech.verb,
    'aimer': PartOfSpeech.verb,
    'détester': PartOfSpeech.verb,
    
    // Adjectifs
    'grand': PartOfSpeech.adjective,
    'petit': PartOfSpeech.adjective,
    'beau': PartOfSpeech.adjective,
    'joli': PartOfSpeech.adjective,
    'rapide': PartOfSpeech.adjective,
    'lent': PartOfSpeech.adjective,
    'chaud': PartOfSpeech.adjective,
    'froid': PartOfSpeech.adjective,
    'heureux': PartOfSpeech.adjective,
    'triste': PartOfSpeech.adjective,
    
    // Pronoms
    'je': PartOfSpeech.pronoun,
    'tu': PartOfSpeech.pronoun,
    'il': PartOfSpeech.pronoun,
    'elle': PartOfSpeech.pronoun,
    'nous': PartOfSpeech.pronoun,
    'vous': PartOfSpeech.pronoun,
    'ils': PartOfSpeech.pronoun,
    'elles': PartOfSpeech.pronoun,
    'me': PartOfSpeech.pronoun,
    'te': PartOfSpeech.pronoun,
    'se': PartOfSpeech.pronoun,
    'lui': PartOfSpeech.pronoun,
    'leur': PartOfSpeech.pronoun,
    
    // Prépositions
    'à': PartOfSpeech.preposition,
    'de': PartOfSpeech.preposition,
    'en': PartOfSpeech.preposition,
    'dans': PartOfSpeech.preposition,
    'sur': PartOfSpeech.preposition,
    'sous': PartOfSpeech.preposition,
    'avec': PartOfSpeech.preposition,
    'sans': PartOfSpeech.preposition,
    'pour': PartOfSpeech.preposition,
    'par': PartOfSpeech.preposition,
    'vers': PartOfSpeech.preposition,
    'chez': PartOfSpeech.preposition,
    
    // Conjonctions
    'et': PartOfSpeech.conjunction,
    'ou': PartOfSpeech.conjunction,
    'mais': PartOfSpeech.conjunction,
    'donc': PartOfSpeech.conjunction,
    'or': PartOfSpeech.conjunction,
    'ni': PartOfSpeech.conjunction,
    'car': PartOfSpeech.conjunction,
    'que': PartOfSpeech.conjunction,
    'si': PartOfSpeech.conjunction,
  };

  GrammarAnalysisService() {
    _initEntityExtractor();
  }

  void _initEntityExtractor() {
    // Version corrigée - EntityExtractor ne prend plus de paramètres options
    //_entityExtractor = EntityExtractor();
  }

  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text.trim();
  }

  Future<List<WordGrammar>> analyzeText(String text) async {
    final List<WordGrammar> results = [];
    final words = text.split(RegExp(r'[\s\n\r\t]+'));
    
    for (var word in words) {
      if (word.trim().isEmpty) continue;
      
      final cleanWord = _cleanWord(word);
      final pos = await _determinePartOfSpeech(cleanWord, word);
      final semantic = _getSemanticCategory(cleanWord);
      final color = _getColorForPOS(pos);
      final emoji = _getEmojiForWord(cleanWord, pos, semantic);
      
      results.add(WordGrammar(
        word: word,
        pos: pos,
        semantic: semantic,
        color: color,
        emoji: emoji,
      ));
    }
    
    return results;
  }

  Future<PartOfSpeech> _determinePartOfSpeech(String cleanWord, String originalWord) async {
    // 1. Vérifier le dictionnaire
    if (_posDictionary.containsKey(cleanWord)) {
      return _posDictionary[cleanWord]!;
    }
    
    // 2. Détection par suffixe (verbes en -er, -ir, -re)
    if (cleanWord.endsWith('er') || cleanWord.endsWith('ir') || cleanWord.endsWith('re')) {
      return PartOfSpeech.verb;
    }
    
    // 3. Détection par suffixe (adjectifs)
    if (cleanWord.endsWith('eux') || cleanWord.endsWith('euse') || 
        cleanWord.endsWith('if') || cleanWord.endsWith('ive') ||
        cleanWord.endsWith('ant') || cleanWord.endsWith('ent')) {
      return PartOfSpeech.adjective;
    }
    
    // 4. Détection par suffixe (adverbes)
    if (cleanWord.endsWith('ment')) {
      return PartOfSpeech.adverb;
    }
    
    // 5. Nombres
    if (RegExp(r'^\d+$').hasMatch(originalWord)) {
      return PartOfSpeech.number;
    }
    
    // 6. Capitalisation (noms propres)
    if (originalWord.isNotEmpty && 
        originalWord[0].toUpperCase() == originalWord[0] && 
        originalWord.length > 1) {
      return PartOfSpeech.properNoun;
    }
    
    // 7. Par défaut : nom commun
    return PartOfSpeech.noun;
  }

  SemanticCategory? _getSemanticCategory(String word) {
    // Dictionnaire sémantique simplifié
    final Map<String, SemanticCategory> semanticDict = {
      // Animaux
      'chat': SemanticCategory.animal,
      'chien': SemanticCategory.animal,
      'oiseau': SemanticCategory.animal,
      'poisson': SemanticCategory.animal,
      // Nourriture
      'pomme': SemanticCategory.food,
      'banane': SemanticCategory.food,
      'pizza': SemanticCategory.food,
      // Couleurs
      'rouge': SemanticCategory.color,
      'bleu': SemanticCategory.color,
      'vert': SemanticCategory.color,
      // Émotions
      'heureux': SemanticCategory.emotion,
      'triste': SemanticCategory.emotion,
      // Véhicules
      'voiture': SemanticCategory.vehicle,
      'avion': SemanticCategory.vehicle,
      // Nature
      'soleil': SemanticCategory.nature,
      'lune': SemanticCategory.nature,
      // Personnes (noms propres détectés par ML Kit)
      'maman': SemanticCategory.person,
      'papa': SemanticCategory.person,
    };
    
    return semanticDict[word];
  }

  String _cleanWord(String word) {
    return word.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s-]'), '');
  }

  Color _getColorForPOS(PartOfSpeech pos) {
    switch (pos) {
      case PartOfSpeech.noun: return const Color(0xFF4CAF50);      // Vert
      case PartOfSpeech.verb: return const Color(0xFF2196F3);      // Bleu
      case PartOfSpeech.adjective: return const Color(0xFFFF9800); // Orange
      case PartOfSpeech.adverb: return const Color(0xFF9C27B0);    // Violet
      case PartOfSpeech.pronoun: return const Color(0xFF009688);   // Teal
      case PartOfSpeech.preposition: return const Color(0xFF00BCD4); // Cyan
      case PartOfSpeech.conjunction: return const Color(0xFFCDDC39); // Lime
      case PartOfSpeech.interjection: return const Color(0xFFFF5722); // Deep Orange
      case PartOfSpeech.properNoun: return const Color(0xFF3F51B5); // Indigo
      case PartOfSpeech.number: return const Color(0xFFFFC107);    // Amber
      default: return const Color(0xFF9E9E9E);                     // Gris
    }
  }

  String _getEmojiForWord(String word, PartOfSpeech pos, SemanticCategory? semantic) {
    // Emojis sémantiques (priorité plus haute)
    if (semantic != null) {
      switch (semantic) {
        case SemanticCategory.person: return '👤';
        case SemanticCategory.animal: return '🐾';
        case SemanticCategory.food: return '🍽️';
        case SemanticCategory.place: return '📍';
        case SemanticCategory.color: return '🎨';
        case SemanticCategory.emotion: return '😊';
        case SemanticCategory.vehicle: return '🚗';
        case SemanticCategory.nature: return '🌿';
        case SemanticCategory.technology: return '💻';
        case SemanticCategory.sport: return '⚽';
        case SemanticCategory.time: return '⏰';
        default: return this._getPosEmoji(pos);
      }
    }
    return this._getPosEmoji(pos);
  }

  String _getPosEmoji(PartOfSpeech pos) {
    switch (pos) {
      case PartOfSpeech.noun: return '📦';
      case PartOfSpeech.verb: return '⚡';
      case PartOfSpeech.adjective: return '✨';
      case PartOfSpeech.adverb: return '⏱️';
      case PartOfSpeech.pronoun: return '🔤';
      case PartOfSpeech.preposition: return '↗️';
      case PartOfSpeech.conjunction: return '🔗';
      case PartOfSpeech.interjection: return '❗';
      case PartOfSpeech.properNoun: return '👤';
      case PartOfSpeech.number: return '🔢';
      default: return '❓';
    }
  }

  String getPOSLabel(PartOfSpeech pos) {
    switch (pos) {
      case PartOfSpeech.noun: return 'Nom';
      case PartOfSpeech.verb: return 'Verbe';
      case PartOfSpeech.adjective: return 'Adjectif';
      case PartOfSpeech.adverb: return 'Adverbe';
      case PartOfSpeech.pronoun: return 'Pronom';
      case PartOfSpeech.preposition: return 'Préposition';
      case PartOfSpeech.conjunction: return 'Conjonction';
      case PartOfSpeech.interjection: return 'Interjection';
      case PartOfSpeech.properNoun: return 'Nom propre';
      case PartOfSpeech.number: return 'Nombre';
      default: return 'Inconnu';
    }
  }

  String getSemanticLabel(SemanticCategory? semantic) {
    if (semantic == null) return '';
    switch (semantic) {
      case SemanticCategory.person: return 'Personne';
      case SemanticCategory.animal: return 'Animal';
      case SemanticCategory.food: return 'Nourriture';
      case SemanticCategory.place: return 'Lieu';
      case SemanticCategory.color: return 'Couleur';
      case SemanticCategory.emotion: return 'Sentiment';
      case SemanticCategory.vehicle: return 'Véhicule';
      case SemanticCategory.nature: return 'Nature';
      case SemanticCategory.technology: return 'Technologie';
      case SemanticCategory.sport: return 'Sport';
      case SemanticCategory.time: return 'Temps';
      default: return '';
    }
  }

  void dispose() {
    _textRecognizer.close();
    _entityExtractor.close();
  }
}