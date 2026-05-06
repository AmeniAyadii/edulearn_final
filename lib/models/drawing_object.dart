// lib/models/drawing_object.dart
import 'package:flutter/material.dart';

class DrawingObject {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> keywords;
  final int points;
  final int difficulty;
  final String drawingTip;

  DrawingObject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.keywords,
    required this.points,
    required this.difficulty,
    required this.drawingTip,
  });

  static List<DrawingObject> getAllObjects() {
    return [
      // Niveau 1 - Très simple (20 objets)
      DrawingObject(
        id: 'sun', name: 'Soleil', emoji: '☀️',
        description: 'Dessine un soleil avec des rayons',
        keywords: ['soleil', 'sun', 'rayons', 'jaune'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine un grand cercle et ajoute des rayons tout autour',
      ),
      DrawingObject(
        id: 'moon', name: 'Lune', emoji: '🌙',
        description: 'Dessine un croissant de lune',
        keywords: ['lune', 'moon', 'croissant'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine un C arrondi pour faire un croissant',
      ),
      DrawingObject(
        id: 'star', name: 'Étoile', emoji: '⭐',
        description: 'Dessine une étoile à 5 branches',
        keywords: ['étoile', 'star', 'branches'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine une forme d\'étoile avec 5 pointes',
      ),
      DrawingObject(
        id: 'heart', name: 'Cœur', emoji: '❤️',
        description: 'Dessine un cœur',
        keywords: ['cœur', 'heart', 'amour'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine deux ronds en haut et une pointe en bas',
      ),
      DrawingObject(
        id: 'circle', name: 'Cercle', emoji: '⚪',
        description: 'Dessine un cercle parfait',
        keywords: ['cercle', 'circle', 'rond'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine un rond tout simple',
      ),
      DrawingObject(
        id: 'square', name: 'Carré', emoji: '⬛',
        description: 'Dessine un carré',
        keywords: ['carré', 'square', 'quatre côtés'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine quatre lignes égales pour faire un carré',
      ),
      DrawingObject(
        id: 'triangle', name: 'Triangle', emoji: '🔺',
        description: 'Dessine un triangle',
        keywords: ['triangle', 'trois côtés'],
        points: 20, difficulty: 1,
        drawingTip: 'Dessine trois lignes qui se rejoignent',
      ),
      
      // Niveau 2 - Simple (20 objets)
      DrawingObject(
        id: 'cat', name: 'Chat', emoji: '🐱',
        description: 'Dessine un chat',
        keywords: ['chat', 'cat', 'moustaches', 'oreilles'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine un rond pour la tête, deux triangles pour les oreilles',
      ),
      DrawingObject(
        id: 'dog', name: 'Chien', emoji: '🐶',
        description: 'Dessine un chien',
        keywords: ['chien', 'dog', 'queue', 'pattes'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine une tête ronde, deux oreilles tombantes',
      ),
      DrawingObject(
        id: 'fish', name: 'Poisson', emoji: '🐟',
        description: 'Dessine un poisson',
        keywords: ['poisson', 'fish', 'nageoires', 'queue'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine un ovale, une queue triangulaire et un œil',
      ),
      DrawingObject(
        id: 'bird', name: 'Oiseau', emoji: '🐦',
        description: 'Dessine un oiseau',
        keywords: ['oiseau', 'bird', 'ailes', 'bec'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine un ovale, un bec pointu et des ailes',
      ),
      DrawingObject(
        id: 'flower', name: 'Fleur', emoji: '🌸',
        description: 'Dessine une fleur',
        keywords: ['fleur', 'flower', 'pétales', 'tige'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine un cercle au centre et des pétales autour',
      ),
      DrawingObject(
        id: 'tree', name: 'Arbre', emoji: '🌳',
        description: 'Dessine un arbre',
        keywords: ['arbre', 'tree', 'tronc', 'branches'],
        points: 30, difficulty: 2,
        drawingTip: 'Dessine un tronc marron et un rond vert pour les feuilles',
      ),
      
      // Niveau 3 - Moyen (15 objets)
      DrawingObject(
        id: 'house', name: 'Maison', emoji: '🏠',
        description: 'Dessine une maison',
        keywords: ['maison', 'house', 'toit', 'porte', 'fenêtre'],
        points: 40, difficulty: 3,
        drawingTip: 'Dessine un carré, un triangle sur le dessus, une porte et des fenêtres',
      ),
      DrawingObject(
        id: 'car', name: 'Voiture', emoji: '🚗',
        description: 'Dessine une voiture',
        keywords: ['voiture', 'car', 'roues', 'portières'],
        points: 40, difficulty: 3,
        drawingTip: 'Dessine un rectangle, deux cercles pour les roues',
      ),
      DrawingObject(
        id: 'apple', name: 'Pomme', emoji: '🍎',
        description: 'Dessine une pomme',
        keywords: ['pomme', 'apple', 'tige', 'feuille'],
        points: 40, difficulty: 3,
        drawingTip: 'Dessine un cercle avec une petite tige sur le dessus',
      ),
      
      // Niveau 4 - Difficile (10 objets)
      DrawingObject(
        id: 'butterfly', name: 'Papillon', emoji: '🦋',
        description: 'Dessine un papillon',
        keywords: ['papillon', 'butterfly', 'ailes', 'antennes'],
        points: 50, difficulty: 4,
        drawingTip: 'Dessine deux grandes ailes symétriques et des antennes',
      ),
      DrawingObject(
        id: 'rocket', name: 'Fusée', emoji: '🚀',
        description: 'Dessine une fusée',
        keywords: ['fusée', 'rocket', 'décollage', 'flamme'],
        points: 50, difficulty: 4,
        drawingTip: 'Dessine un ovale allongé, des ailes et une flamme en bas',
      ),
      
      // Niveau 5 - Expert (5 objets)
      DrawingObject(
        id: 'dragon', name: 'Dragon', emoji: '🐉',
        description: 'Dessine un dragon',
        keywords: ['dragon', 'dragon', 'ailes', 'queue', 'écailles'],
        points: 60, difficulty: 5,
        drawingTip: 'Dessine une tête, un long cou, des ailes et une queue',
      ),
    ];
  }

  static List<DrawingObject> getObjectsByDifficulty(int difficulty) {
    return getAllObjects().where((w) => w.difficulty == difficulty).toList();
  }
}