// lib/models/grammar_models.dart

import 'package:flutter/material.dart';

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