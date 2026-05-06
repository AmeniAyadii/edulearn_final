// lib/models/category_word.dart
import 'package:flutter/material.dart';

enum WordCategory {
  // Niveau 1 (Très facile)
  fruit('🍎', 'Fruits', 1),
  animal('🐶', 'Animaux', 1),
  color('🎨', 'Couleurs', 1),
  
  // Niveau 2 (Facile)
  vehicle('🚗', 'Véhicules', 2),
  food('🍕', 'Nourriture', 2),
  clothing('👕', 'Vêtements', 2),
  shapes('🔷', 'Formes', 2),
  numbers('🔢', 'Nombres', 2),
  
  // Niveau 3 (Moyen)
  nature('🌳', 'Nature', 3),
  profession('👨‍⚕️', 'Métiers', 3),
  sport('⚽', 'Sports', 3),
  music('🎵', 'Musique', 3),
  weather('☀️', 'Météo', 3),
  body('🦷', 'Corps humain', 3),
  
  // Niveau 4 (Difficile)
  furniture('🪑', 'Meubles', 4),
  emotion('😊', 'Émotions', 4),
  school('📚', 'École', 4),
  technology('💻', 'Technologie', 4),
  travel('✈️', 'Voyage', 4),
  art('🎨', 'Art', 4),
  
  // Niveau 5 (Expert)
  science('🔬', 'Science', 5),
  geography('🌍', 'Géographie', 5),
  history('📜', 'Histoire', 5),
  literature('📖', 'Littérature', 5),
  mythology('🏛️', 'Mythologie', 5),
  astronomy('🌙', 'Astronomie', 5),
  biology('🧬', 'Biologie', 5),
  chemistry('🧪', 'Chimie', 5),
  physics('⚛️', 'Physique', 5);

  final String emoji;
  final String label;
  final int difficulty;

  const WordCategory(this.emoji, this.label, this.difficulty);

  Color get categoryColor {
    switch (this) {
      case WordCategory.fruit:
        return Colors.red;
      case WordCategory.animal:
        return Colors.orange;
      case WordCategory.color:
        return Colors.purple;
      case WordCategory.vehicle:
        return Colors.blue;
      case WordCategory.food:
        return Colors.green;
      case WordCategory.clothing:
        return Colors.pink;
      case WordCategory.shapes:
        return Colors.indigo;
      case WordCategory.numbers:
        return Colors.teal;
      case WordCategory.nature:
        return Colors.lightGreen;
      case WordCategory.profession:
        return Colors.indigo;
      case WordCategory.sport:
        return Colors.cyan;
      case WordCategory.music:
        return Colors.deepPurple;
      case WordCategory.weather:
        return Colors.lightBlue;
      case WordCategory.body:
        return Colors.pinkAccent;
      case WordCategory.furniture:
        return Colors.brown;
      case WordCategory.emotion:
        return Colors.amber;
      case WordCategory.school:
        return Colors.blueGrey;
      case WordCategory.technology:
        return Colors.blueAccent;
      case WordCategory.travel:
        return Colors.lightBlueAccent;
      case WordCategory.art:
        return Colors.deepOrange;
      case WordCategory.science:
        return Colors.lime;
      case WordCategory.geography:
        return Colors.tealAccent;
      case WordCategory.history:
        return Colors.brown;
      case WordCategory.literature:
        return Colors.deepPurpleAccent;
      case WordCategory.mythology:
        return Colors.purpleAccent;
      case WordCategory.astronomy:
        return Colors.indigoAccent;
      case WordCategory.biology:
        return Colors.greenAccent;
      case WordCategory.chemistry:
        return Colors.orangeAccent;
      case WordCategory.physics:
        return Colors.blueAccent;
    }
  }

  static WordCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'fruit': return WordCategory.fruit;
      case 'animal': return WordCategory.animal;
      case 'color': return WordCategory.color;
      case 'vehicle': return WordCategory.vehicle;
      case 'food': return WordCategory.food;
      case 'clothing': return WordCategory.clothing;
      case 'shapes': return WordCategory.shapes;
      case 'numbers': return WordCategory.numbers;
      case 'nature': return WordCategory.nature;
      case 'profession': return WordCategory.profession;
      case 'sport': return WordCategory.sport;
      case 'music': return WordCategory.music;
      case 'weather': return WordCategory.weather;
      case 'body': return WordCategory.body;
      case 'furniture': return WordCategory.furniture;
      case 'emotion': return WordCategory.emotion;
      case 'school': return WordCategory.school;
      case 'technology': return WordCategory.technology;
      case 'travel': return WordCategory.travel;
      case 'art': return WordCategory.art;
      case 'science': return WordCategory.science;
      case 'geography': return WordCategory.geography;
      case 'history': return WordCategory.history;
      case 'literature': return WordCategory.literature;
      case 'mythology': return WordCategory.mythology;
      case 'astronomy': return WordCategory.astronomy;
      case 'biology': return WordCategory.biology;
      case 'chemistry': return WordCategory.chemistry;
      case 'physics': return WordCategory.physics;
      default: return WordCategory.fruit;
    }
  }
}

class CategoryWord {
  final String id;
  final String word;
  final WordCategory category;
  final int points;
  final int difficulty;
  final String emoji;

  CategoryWord({
    required this.id,
    required this.word,
    required this.category,
    required this.points,
    required this.difficulty,
    required this.emoji,
  });

  static List<CategoryWord> getAllWords() {
    return [
      // ==================== NIVEAU 1 - TRÈS FACILE ====================
      // Fruits (10 mots)
      CategoryWord(id: 'apple', word: 'Pomme', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍎'),
      CategoryWord(id: 'banana', word: 'Banane', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍌'),
      CategoryWord(id: 'orange', word: 'Orange', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍊'),
      CategoryWord(id: 'strawberry', word: 'Fraise', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍓'),
      CategoryWord(id: 'grapes', word: 'Raisin', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍇'),
      CategoryWord(id: 'watermelon', word: 'Pastèque', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍉'),
      CategoryWord(id: 'pear', word: 'Poire', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍐'),
      CategoryWord(id: 'cherry', word: 'Cerise', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍒'),
      CategoryWord(id: 'lemon', word: 'Citron', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🍋'),
      CategoryWord(id: 'kiwi', word: 'Kiwi', category: WordCategory.fruit, points: 15, difficulty: 1, emoji: '🥝'),
      
      // Animaux (10 mots)
      CategoryWord(id: 'cat', word: 'Chat', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐱'),
      CategoryWord(id: 'dog', word: 'Chien', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐶'),
      CategoryWord(id: 'bird', word: 'Oiseau', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐦'),
      CategoryWord(id: 'fish', word: 'Poisson', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐟'),
      CategoryWord(id: 'rabbit', word: 'Lapin', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐰'),
      CategoryWord(id: 'horse', word: 'Cheval', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐴'),
      CategoryWord(id: 'cow', word: 'Vache', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐮'),
      CategoryWord(id: 'pig', word: 'Cochon', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐷'),
      CategoryWord(id: 'chicken', word: 'Poulet', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🐔'),
      CategoryWord(id: 'duck', word: 'Canard', category: WordCategory.animal, points: 15, difficulty: 1, emoji: '🦆'),
      
      // Couleurs (8 mots)
      CategoryWord(id: 'red', word: 'Rouge', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🔴'),
      CategoryWord(id: 'blue', word: 'Bleu', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🔵'),
      CategoryWord(id: 'yellow', word: 'Jaune', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🟡'),
      CategoryWord(id: 'green', word: 'Vert', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🟢'),
      CategoryWord(id: 'purple', word: 'Violet', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🟣'),
      CategoryWord(id: 'pink', word: 'Rose', category: WordCategory.color, points: 15, difficulty: 1, emoji: '💗'),
      CategoryWord(id: 'orange_color', word: 'Orange', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🟠'),
      CategoryWord(id: 'brown', word: 'Marron', category: WordCategory.color, points: 15, difficulty: 1, emoji: '🟤'),
      
      // ==================== NIVEAU 2 - FACILE ====================
      // Véhicules (10 mots)
      CategoryWord(id: 'car', word: 'Voiture', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚗'),
      CategoryWord(id: 'truck', word: 'Camion', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚚'),
      CategoryWord(id: 'bus', word: 'Bus', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚌'),
      CategoryWord(id: 'motorcycle', word: 'Moto', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🏍️'),
      CategoryWord(id: 'bicycle', word: 'Vélo', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚲'),
      CategoryWord(id: 'airplane', word: 'Avion', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '✈️'),
      CategoryWord(id: 'helicopter', word: 'Hélicoptère', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚁'),
      CategoryWord(id: 'boat', word: 'Bateau', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '⛵'),
      CategoryWord(id: 'train', word: 'Train', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚆'),
      CategoryWord(id: 'subway', word: 'Métro', category: WordCategory.vehicle, points: 20, difficulty: 2, emoji: '🚇'),
      
      // Nourriture (15 mots)
      CategoryWord(id: 'pizza', word: 'Pizza', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍕'),
      CategoryWord(id: 'burger', word: 'Burger', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍔'),
      CategoryWord(id: 'fries', word: 'Frites', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍟'),
      CategoryWord(id: 'ice_cream', word: 'Glace', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍦'),
      CategoryWord(id: 'cake', word: 'Gâteau', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍰'),
      CategoryWord(id: 'bread', word: 'Pain', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍞'),
      CategoryWord(id: 'cheese', word: 'Fromage', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🧀'),
      CategoryWord(id: 'eggs', word: 'Œufs', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🥚'),
      CategoryWord(id: 'milk', word: 'Lait', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🥛'),
      CategoryWord(id: 'juice', word: 'Jus', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🧃'),
      CategoryWord(id: 'soup', word: 'Soupe', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍲'),
      CategoryWord(id: 'salad', word: 'Salade', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🥗'),
      CategoryWord(id: 'pasta', word: 'Pâtes', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍝'),
      CategoryWord(id: 'rice', word: 'Riz', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍚'),
      CategoryWord(id: 'sushi', word: 'Sushi', category: WordCategory.food, points: 20, difficulty: 2, emoji: '🍣'),
      
      // Vêtements (8 mots)
      CategoryWord(id: 'shirt', word: 'Chemise', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '👕'),
      CategoryWord(id: 'pants', word: 'Pantalon', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '👖'),
      CategoryWord(id: 'dress', word: 'Robe', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '👗'),
      CategoryWord(id: 'shoes', word: 'Chaussures', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '👟'),
      CategoryWord(id: 'hat', word: 'Chapeau', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '🧢'),
      CategoryWord(id: 'socks', word: 'Chaussettes', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '🧦'),
      CategoryWord(id: 'jacket', word: 'Veste', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '🧥'),
      CategoryWord(id: 'gloves', word: 'Gants', category: WordCategory.clothing, points: 20, difficulty: 2, emoji: '🧤'),
      
      // ==================== NIVEAU 3 - MOYEN ====================
      // Nature (10 mots)
      CategoryWord(id: 'tree', word: 'Arbre', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌳'),
      CategoryWord(id: 'flower', word: 'Fleur', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌸'),
      CategoryWord(id: 'mountain', word: 'Montagne', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '⛰️'),
      CategoryWord(id: 'river', word: 'Rivière', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌊'),
      CategoryWord(id: 'forest', word: 'Forêt', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌲'),
      CategoryWord(id: 'sun', word: 'Soleil', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '☀️'),
      CategoryWord(id: 'moon', word: 'Lune', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌙'),
      CategoryWord(id: 'star', word: 'Étoile', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '⭐'),
      CategoryWord(id: 'ocean', word: 'Océan', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🌊'),
      CategoryWord(id: 'desert', word: 'Désert', category: WordCategory.nature, points: 25, difficulty: 3, emoji: '🏜️'),
      
      // ==================== NIVEAU 4 - DIFFICILE ====================
      // Sports (10 mots)
      CategoryWord(id: 'football', word: 'Football', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '⚽'),
      CategoryWord(id: 'basketball', word: 'Basketball', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🏀'),
      CategoryWord(id: 'tennis', word: 'Tennis', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🎾'),
      CategoryWord(id: 'swimming', word: 'Natation', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🏊'),
      CategoryWord(id: 'running', word: 'Course', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🏃'),
      CategoryWord(id: 'cycling', word: 'Cyclisme', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🚵'),
      CategoryWord(id: 'volleyball', word: 'Volley', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🏐'),
      CategoryWord(id: 'baseball', word: 'Baseball', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '⚾'),
      CategoryWord(id: 'golf', word: 'Golf', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '⛳'),
      CategoryWord(id: 'boxing', word: 'Boxe', category: WordCategory.sport, points: 30, difficulty: 4, emoji: '🥊'),
      
      // ==================== NIVEAU 5 - EXPERT ====================
      // Science (8 mots)
      CategoryWord(id: 'atom', word: 'Atome', category: WordCategory.science, points: 40, difficulty: 5, emoji: '⚛️'),
      CategoryWord(id: 'dna', word: 'ADN', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🧬'),
      CategoryWord(id: 'microscope', word: 'Microscope', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🔬'),
      CategoryWord(id: 'telescope', word: 'Télescope', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🔭'),
      CategoryWord(id: 'magnet', word: 'Aimant', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🧲'),
      CategoryWord(id: 'gravity', word: 'Gravité', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🌎'),
      CategoryWord(id: 'evolution', word: 'Évolution', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🦍'),
      CategoryWord(id: 'climate', word: 'Climat', category: WordCategory.science, points: 40, difficulty: 5, emoji: '🌡️'),
      
      // Émotions (8 mots)
      CategoryWord(id: 'happy', word: 'Heureux', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😊'),
      CategoryWord(id: 'sad', word: 'Triste', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😢'),
      CategoryWord(id: 'angry', word: 'En colère', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😠'),
      CategoryWord(id: 'scared', word: 'Peur', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😨'),
      CategoryWord(id: 'surprised', word: 'Surpris', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😮'),
      CategoryWord(id: 'love', word: 'Amour', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '❤️'),
      CategoryWord(id: 'excited', word: 'Excité', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '🤩'),
      CategoryWord(id: 'calm', word: 'Calme', category: WordCategory.emotion, points: 30, difficulty: 4, emoji: '😌'),
      
      // Technologie (8 mots)
      CategoryWord(id: 'computer', word: 'Ordinateur', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '💻'),
      CategoryWord(id: 'smartphone', word: 'Smartphone', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '📱'),
      CategoryWord(id: 'internet', word: 'Internet', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '🌐'),
      CategoryWord(id: 'robot', word: 'Robot', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '🤖'),
      CategoryWord(id: 'tablet', word: 'Tablette', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '📟'),
      CategoryWord(id: 'virtual', word: 'Virtuel', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '🥽'),
      CategoryWord(id: 'artificial', word: 'IA', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '🧠'),
      CategoryWord(id: 'coding', word: 'Programmation', category: WordCategory.technology, points: 35, difficulty: 5, emoji: '💻'),
    ];
  }

  static List<CategoryWord> getWordsByDifficulty(int difficulty) {
    return getAllWords().where((w) => w.difficulty == difficulty).toList();
  }

  static List<CategoryWord> getWordsByCategory(WordCategory category) {
    return getAllWords().where((w) => w.category == category).toList();
  }

  static List<WordCategory> getAvailableCategories() {
    return WordCategory.values;
  }

  static Map<String, dynamic> getStatistics() {
    final words = getAllWords();
    final categories = getAvailableCategories();
    
    return {
      'totalWords': words.length,
      'totalCategories': categories.length,
      'wordsByDifficulty': {
        for (int i = 1; i <= 5; i++)
          'Niveau $i': words.where((w) => w.difficulty == i).length,
      },
      'wordsByCategory': {
        for (var cat in categories)
          cat.label: words.where((w) => w.category == cat).length,
      },
    };
  }
}