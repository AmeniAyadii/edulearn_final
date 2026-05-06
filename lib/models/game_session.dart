// lib/games/guess_game/models/game_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum GameStatus { 
  waiting,      // En attente de joueur
  inProgress,   // En cours
  finished,     // Terminé
  cancelled     // Annulé
}

enum GameMode {
  multiplayer,  // Multijoueur
  solo         // Solo contre IA
}

enum Difficulty {
  easy,     // Facile
  medium,   // Moyen
  hard      // Difficile
}

// ============================================================================
// CLASSES
// ============================================================================

class Clue {
  String clueText;
  int clueNumber;
  DateTime generatedAt;

  Clue({
    required this.clueText,
    required this.clueNumber,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'clueText': clueText,
    'clueNumber': clueNumber,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory Clue.fromMap(Map<String, dynamic> map) {
    return Clue(
      clueText: map['clueText'] ?? '',
      clueNumber: map['clueNumber'] ?? 0,
      generatedAt: DateTime.tryParse(map['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class GameSession {
  String sessionId;
  String creatorChildId;
  String? guesserChildId;
  String secretObjectLabel;
  double confidence;
  String? imageUrl;
  List<Clue> clues;
  int currentClueIndex;      // ✅ AJOUTÉ
  GameStatus status;
  GameMode mode;
  Difficulty difficulty;
  int attemptsUsed;
  DateTime createdAt;
  DateTime? completedAt;
  int pointsEarned;
  String? joinCode;

  GameSession({
    required this.sessionId,
    required this.creatorChildId,
    this.guesserChildId,
    required this.secretObjectLabel,
    required this.confidence,
    this.imageUrl,
    required this.clues,
    required this.currentClueIndex,    // ✅ AJOUTÉ
    required this.status,
    required this.mode,
    required this.difficulty,
    this.attemptsUsed = 0,
    required this.createdAt,
    this.completedAt,
    this.pointsEarned = 0,
    this.joinCode,
  });

  // Getters
  Clue? get nextClue {
    if (currentClueIndex < clues.length) {
      return clues[currentClueIndex];
    }
    return null;
  }
  
  bool get allCluesRevealed => currentClueIndex >= clues.length;
  
  int get remainingClues => clues.length - currentClueIndex;

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'creatorChildId': creatorChildId,
    'guesserChildId': guesserChildId,
    'secretObjectLabel': secretObjectLabel,
    'confidence': confidence,
    'imageUrl': imageUrl,
    'clues': clues.map((c) => c.toMap()).toList(),
    'currentClueIndex': currentClueIndex,    // ✅ AJOUTÉ
    'status': status.index,
    'mode': mode.index,
    'difficulty': difficulty.index,
    'attemptsUsed': attemptsUsed,
    'createdAt': FieldValue.serverTimestamp(),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'pointsEarned': pointsEarned,
    'joinCode': joinCode,
  };

  factory GameSession.fromFirestore(Map<String, dynamic> doc, String id) {
    // Récupérer les indices
    final cluesList = <Clue>[];
    final cluesData = doc['clues'] as List<dynamic>?;
    if (cluesData != null) {
      for (var clueData in cluesData) {
        cluesList.add(Clue.fromMap(clueData as Map<String, dynamic>));
      }
    }
    
    return GameSession(
      sessionId: id,
      creatorChildId: doc['creatorChildId'] ?? '',
      guesserChildId: doc['guesserChildId'],
      secretObjectLabel: doc['secretObjectLabel'] ?? 'Objet inconnu',
      confidence: (doc['confidence'] ?? 0.5).toDouble(),
      imageUrl: doc['imageUrl'],
      clues: cluesList,
      currentClueIndex: doc['currentClueIndex'] ?? 0,    // ✅ AJOUTÉ
      status: GameStatus.values[doc['status'] ?? 0],
      mode: GameMode.values[doc['mode'] ?? 0],
      difficulty: Difficulty.values[doc['difficulty'] ?? 1],  // ✅ CORRIGÉ (1 = medium)
      attemptsUsed: doc['attemptsUsed'] ?? 0,
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (doc['completedAt'] as Timestamp?)?.toDate(),
      pointsEarned: doc['pointsEarned'] ?? 0,
      joinCode: doc['joinCode'],
    );
  }
  
  // ✅ Méthode pour révéler l'indice suivant
  void revealNextClue() {
    if (currentClueIndex < clues.length) {
      currentClueIndex++;
    }
  }
  
  // ✅ Méthode pour ajouter une tentative
  void addAttempt() {
    attemptsUsed++;
  }
  
  // ✅ Méthode pour terminer la partie
  void finishGame(int points) {
    status = GameStatus.finished;
    pointsEarned = points;
    completedAt = DateTime.now();
  }
}

class GameHistory {
  final String sessionId;
  final String objectName;
  final int pointsEarned;
  final int attemptsUsed;
  final DateTime completedAt;
  final bool isVictory;

  GameHistory({
    required this.sessionId,
    required this.objectName,
    required this.pointsEarned,
    required this.attemptsUsed,
    required this.completedAt,
    required this.isVictory,
  });

  factory GameHistory.fromFirestore(Map<String, dynamic> doc, String id) {
    return GameHistory(
      sessionId: id,
      objectName: doc['objectName'] ?? '?',
      pointsEarned: doc['pointsEarned'] ?? 0,
      attemptsUsed: doc['attemptsUsed'] ?? 0,
      completedAt: (doc['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVictory: doc['isVictory'] ?? false,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'objectName': objectName,
    'pointsEarned': pointsEarned,
    'attemptsUsed': attemptsUsed,
    'completedAt': Timestamp.fromDate(completedAt),
    'isVictory': isVictory,
  };
}

// ============================================================================
// EXTENSIONS
// ============================================================================

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Facile';
      case Difficulty.medium:
        return 'Moyen';
      case Difficulty.hard:
        return 'Difficile';
    }
  }
  
  IconData get icon {
    switch (this) {
      case Difficulty.easy:
        return Icons.star;
      case Difficulty.medium:
        return Icons.star_half;
      case Difficulty.hard:
        return Icons.star_outline;
    }
  }
  
  Color get color {
    switch (this) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }
  
  int get pointsMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
    }
  }
}

extension GameStatusExtension on GameStatus {
  String get displayName {
    switch (this) {
      case GameStatus.waiting:
        return 'En attente';
      case GameStatus.inProgress:
        return 'En cours';
      case GameStatus.finished:
        return 'Terminé';
      case GameStatus.cancelled:
        return 'Annulé';
    }
  }
  
  Color get color {
    switch (this) {
      case GameStatus.waiting:
        return Colors.orange;
      case GameStatus.inProgress:
        return Colors.green;
      case GameStatus.finished:
        return Colors.blue;
      case GameStatus.cancelled:
        return Colors.red;
    }
  }
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.multiplayer:
        return 'Multijoueur';
      case GameMode.solo:
        return 'Solo';
    }
  }
  
  IconData get icon {
    switch (this) {
      case GameMode.multiplayer:
        return Icons.people;
      case GameMode.solo:
        return Icons.person;
    }
  }
}