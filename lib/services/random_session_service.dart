// lib/games/guess_game/services/random_session_service.dart

import 'dart:math';

import 'package:edulearn_final/screens/games/guess_game/data/objects_database.dart';

import '../models/game_session.dart';

class RandomSessionService {
  static final Random _random = Random();
  
  // Configuration des sessions
  static const int defaultObjectsPerSession = 5;
  static const int easyObjectsPerSession = 3;
  static const int mediumObjectsPerSession = 5;
  static const int hardObjectsPerSession = 7;
  
  // Liste de tous les objets disponibles
  static List<GameObject> getAllAvailableObjects() {
    return GameObjectsDatabase.allObjects;
  }
  
  // Obtenir des objets aléatoires par difficulté
  static List<GameObject> getRandomObjectsByDifficulty(
    Difficulty difficulty, {
    int count = 5,
  }) {
    List<GameObject> filteredObjects;
    
    switch (difficulty) {
      case Difficulty.easy:
        filteredObjects = GameObjectsDatabase.getEasyObjects();
        count = min(count, easyObjectsPerSession);
        break;
      case Difficulty.medium:
        filteredObjects = GameObjectsDatabase.getMediumObjects();
        count = min(count, mediumObjectsPerSession);
        break;
      case Difficulty.hard:
        filteredObjects = GameObjectsDatabase.getHardObjects();
        count = min(count, hardObjectsPerSession);
        break;
    }
    
    if (filteredObjects.isEmpty) {
      return [];
    }
    
    // Mélanger et prendre 'count' objets
    final shuffled = List<GameObject>.from(filteredObjects);
    shuffled.shuffle(_random);
    return shuffled.take(count).toList();
  }
  
  // Obtenir des objets aléatoires avec catégories mélangées
  static List<GameObject> getMixedRandomObjects({
    int count = 5,
    List<Difficulty>? difficulties,
  }) {
    List<GameObject> allObjects = [];
    
    if (difficulties != null) {
      for (var difficulty in difficulties) {
        allObjects.addAll(GameObjectsDatabase.getObjectsByDifficulty(difficulty));
      }
    } else {
      allObjects = GameObjectsDatabase.allObjects;
    }
    
    if (allObjects.isEmpty) {
      return [];
    }
    
    final shuffled = List<GameObject>.from(allObjects);
    shuffled.shuffle(_random);
    return shuffled.take(count).toList();
  }
  
  // Générer une session complète
  static RandomGameSession generateRandomSession({
    required String childId,
    required Difficulty difficulty,
    int objectCount = 5,
  }) {
    final objects = getRandomObjectsByDifficulty(difficulty, count: objectCount);
    final sessionId = 'RANDOM_SESSION_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
    
    return RandomGameSession(
      id: sessionId,
      childId: childId,
      difficulty: difficulty,
      objects: objects,
      createdAt: DateTime.now(),
    );
  }
  
  // Générer un marathon (très longue session)
  static RandomGameSession generateMarathonSession({
    required String childId,
    required Difficulty difficulty,
  }) {
    int objectCount;
    switch (difficulty) {
      case Difficulty.easy:
        objectCount = 10;
        break;
      case Difficulty.medium:
        objectCount = 15;
        break;
      case Difficulty.hard:
        objectCount = 20;
        break;
    }
    
    return generateRandomSession(
      childId: childId,
      difficulty: difficulty,
      objectCount: objectCount,
    );
  }
  
  // Générer une session thématique (objets d'une même catégorie)
  static RandomGameSession generateThematicSession({
    required String childId,
    required String category,
    int objectCount = 5,
  }) {
    final categoryMap = {
      'animaux': GameObjectsDatabase.getAnimals(),
      'fruits': GameObjectsDatabase.getFruits(),
      'vehicules': GameObjectsDatabase.getVehicles(),
      'maison': GameObjectsDatabase.getHouseObjects(),
      'nature': GameObjectsDatabase.getNatureObjects(),
      'nourriture': GameObjectsDatabase.getFoodObjects(),
    };
    
    final objects = categoryMap[category] ?? [];
    final shuffled = List<GameObject>.from(objects);
    shuffled.shuffle(_random);
    final selectedObjects = shuffled.take(objectCount).toList();
    
    return RandomGameSession(
      id: 'THEMATIC_${category}_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      difficulty: Difficulty.medium,
      objects: selectedObjects,
      createdAt: DateTime.now(),
      isThematic: true,
      theme: category,
    );
  }
}

class RandomGameSession {
  final String id;
  final String childId;
  final Difficulty difficulty;
  final List<GameObject> objects;
  final DateTime createdAt;
  final bool isThematic;
  final String? theme;
  
  int currentObjectIndex = 0;
  int totalScore = 0;
  List<bool> completedObjects = [];
  Map<String, int> objectScores = {};
  DateTime? completedAt;
  
  RandomGameSession({
    required this.id,
    required this.childId,
    required this.difficulty,
    required this.objects,
    required this.createdAt,
    this.isThematic = false,
    this.theme,
  }) {
    completedObjects = List.filled(objects.length, false);
  }
  
  double get progress {
    if (objects.isEmpty) return 0;
    return completedObjects.where((c) => c).length / objects.length;
  }
  
  int get completedCount => completedObjects.where((c) => c).length;
  
  bool get isCompleted => completedCount == objects.length;
  
  int get totalPossiblePoints {
    return objects.length * 15; // 15 points max par objet
  }
  
  GameObject getCurrentObject() {
    if (currentObjectIndex >= objects.length) {
      return objects.last;
    }
    return objects[currentObjectIndex];
  }
  
  void completeCurrentObject(int points) {
    if (currentObjectIndex < objects.length) {
      completedObjects[currentObjectIndex] = true;
      objectScores[objects[currentObjectIndex].name] = points;
      totalScore += points;
      currentObjectIndex++;
    }
    
    if (isCompleted) {
      completedAt = DateTime.now();
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'difficulty': difficulty.index,
      'objects': objects.map((o) => o.name).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalScore': totalScore,
      'objectScores': objectScores,
      'isThematic': isThematic,
      'theme': theme,
    };
  }
}