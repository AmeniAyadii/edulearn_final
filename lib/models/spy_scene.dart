// lib/models/spy_scene.dart
import 'package:flutter/material.dart';

class SpyItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> keywords;
  final Color color;
  final int points;
  final int difficulty;

  SpyItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.keywords,
    required this.color,
    required this.points,
    required this.difficulty,
  });
}

class SpyScene {
  final String id;
  final String name;
  final String emoji;
  final String backgroundHint;
  final List<SpyItem> items;
  final int level;

  SpyScene({
    required this.id,
    required this.name,
    required this.emoji,
    required this.backgroundHint,
    required this.items,
    required this.level,
  });

  static List<SpyScene> getAllScenes() {
    return [
      // Niveau 1 - Salon
      SpyScene(
        id: 'living_room',
        name: 'Salon',
        emoji: '🛋️',
        backgroundHint: 'Un endroit où on se détend, avec canapé et télévision',
        level: 1,
        items: [
          SpyItem(
            id: 'sofa', name: 'Canapé', emoji: '🛋️',
            description: 'Trouve le canapé où on s\'assoit',
            keywords: ['canapé', 'sofa', 'divan'],
            color: Colors.brown,
            points: 20,
            difficulty: 1,
          ),
          SpyItem(
            id: 'tv', name: 'Télévision', emoji: '📺',
            description: 'Trouve la télévision pour regarder des dessins animés',
            keywords: ['télévision', 'tv', 'téléviseur', 'écran'],
            color: Colors.black,
            points: 20,
            difficulty: 1,
          ),
          SpyItem(
            id: 'lamp', name: 'Lampe', emoji: '💡',
            description: 'Trouve la lampe qui éclaire la pièce',
            keywords: ['lampe', 'lamp', 'lumière'],
            color: Colors.yellow,
            points: 20,
            difficulty: 1,
          ),
        ],
      ),
      
      // Niveau 2 - Cuisine
      SpyScene(
        id: 'kitchen', name: 'Cuisine', emoji: '🍳',
        backgroundHint: 'Un endroit où on prépare à manger',
        level: 2,
        items: [
          SpyItem(
            id: 'refrigerator', name: 'Réfrigérateur', emoji: '🧊',
            description: 'Trouve le réfrigérateur qui garde la nourriture au frais',
            keywords: ['réfrigérateur', 'frigo', 'refrigerator'],
            color: Colors.white,
            points: 25,
            difficulty: 2,
          ),
          SpyItem(
            id: 'microwave', name: 'Micro-ondes', emoji: '🔥',
            description: 'Trouve le micro-ondes pour réchauffer les plats',
            keywords: ['micro-ondes', 'microonde', 'microwave'],
            color: Colors.grey,
            points: 25,
            difficulty: 2,
          ),
          SpyItem(
            id: 'toaster', name: 'Grille-pain', emoji: '🍞',
            description: 'Trouve le grille-pain pour faire du pain grillé',
            keywords: ['grille-pain', 'toaster', 'grille pain'],
            color: Colors.grey,
            points: 25,
            difficulty: 2,
          ),
        ],
      ),
      
      // Niveau 3 - Chambre
      SpyScene(
        id: 'bedroom', name: 'Chambre', emoji: '🛏️',
        backgroundHint: 'Un endroit où on dort et on se repose',
        level: 3,
        items: [
          SpyItem(
            id: 'bed', name: 'Lit', emoji: '🛏️',
            description: 'Trouve le lit pour dormir',
            keywords: ['lit', 'bed', 'coucher'],
            color: Colors.blue,
            points: 30,
            difficulty: 3,
          ),
          SpyItem(
            id: 'wardrobe', name: 'Armoire', emoji: '👚',
            description: 'Trouve l\'armoire pour ranger les vêtements',
            keywords: ['armoire', 'wardrobe', 'closet'],
            color: Colors.brown,
            points: 30,
            difficulty: 3,
          ),
          SpyItem(
            id: 'pillow', name: 'Oreiller', emoji: '🛌',
            description: 'Trouve l\'oreiller pour la tête',
            keywords: ['oreiller', 'pillow', 'coussin'],
            color: Colors.white,
            points: 30,
            difficulty: 3,
          ),
        ],
      ),
      
      // Niveau 4 - Salle de bain
      SpyScene(
        id: 'bathroom', name: 'Salle de bain', emoji: '🛁',
        backgroundHint: 'Un endroit où on se lave',
        level: 4,
        items: [
          SpyItem(
            id: 'shower', name: 'Douche', emoji: '🚿',
            description: 'Trouve la douche pour se laver',
            keywords: ['douche', 'shower', 'doucher'],
            color: Colors.lightBlue,
            points: 35,
            difficulty: 4,
          ),
          SpyItem(
            id: 'sink', name: 'Lavabo', emoji: '💧',
            description: 'Trouve le lavabo pour se laver les mains',
            keywords: ['lavabo', 'sink', 'évier'],
            color: Colors.grey,
            points: 35,
            difficulty: 4,
          ),
          SpyItem(
            id: 'towel', name: 'Serviette', emoji: '🧣',
            description: 'Trouve la serviette pour se sécher',
            keywords: ['serviette', 'towel', 'essuie'],
            color: Colors.blue,
            points: 35,
            difficulty: 4,
          ),
        ],
      ),
      
      // Niveau 5 - Jardin
      SpyScene(
        id: 'garden', name: 'Jardin', emoji: '🌻',
        backgroundHint: 'Un endroit dehors avec des plantes',
        level: 5,
        items: [
          SpyItem(
            id: 'flower', name: 'Fleur', emoji: '🌸',
            description: 'Trouve une fleur colorée',
            keywords: ['fleur', 'flower', 'plante'],
            color: Colors.pink,
            points: 40,
            difficulty: 5,
          ),
          SpyItem(
            id: 'tree', name: 'Arbre', emoji: '🌳',
            description: 'Trouve un grand arbre vert',
            keywords: ['arbre', 'tree', 'plante'],
            color: Colors.green,
            points: 40,
            difficulty: 5,
          ),
          SpyItem(
            id: 'bench', name: 'Banc', emoji: '🪑',
            description: 'Trouve le banc pour s\'asseoir',
            keywords: ['banc', 'bench', 'siège'],
            color: Colors.brown,
            points: 40,
            difficulty: 5,
          ),
        ],
      ),
    ];
  }
}