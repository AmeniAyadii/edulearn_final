// lib/games/guess_game/config/game_config.dart

import 'package:edulearn_final/models/game_session.dart';

import '../data/objects_database.dart';

class GameConfig {
  // Nombre d'indices à afficher par objet
  static const int cluesPerObject = 3;
  
  // Points par difficulté
  static const Map<Difficulty, int> pointsPerDifficulty = {
    Difficulty.easy: 10,
    Difficulty.medium: 15,
    Difficulty.hard: 20,
  };
  
  // Bonus si trouvé du premier coup
  static const int firstTryBonus = 5;
  
  // Bonus si aucun indice utilisé
  static const int noHintBonus = 10;
  
  // Temps limite par partie (secondes)
  static const int timeLimitSeconds = 90;
}