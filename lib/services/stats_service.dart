// lib/services/stats_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  StatsService._internal();

  // Sauvegarder les points gagnés
  Future<void> addPoints(String childId, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt('points_$childId') ?? 0;
    await prefs.setInt('points_$childId', currentPoints + points);
    print('💰 +$points points pour $childId (total: ${currentPoints + points})');
  }

  // Sauvegarder une partie de jeu terminée
  Future<void> addGameCompleted(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentGames = prefs.getInt('total_games_$childId') ?? 0;
    await prefs.setInt('total_games_$childId', currentGames + 1);
    print('🎮 Jeu complété pour $childId (total: ${currentGames + 1})');
  }

  // Sauvegarder une activité terminée
  Future<void> addActivityCompleted(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentActivities = prefs.getInt('total_activities_$childId') ?? 0;
    await prefs.setInt('total_activities_$childId', currentActivities + 1);
    print('📚 Activité complétée pour $childId (total: ${currentActivities + 1})');
  }

  // Mettre à jour la série (streak)
  Future<void> updateStreak(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getString('last_active_$childId');
    final now = DateTime.now();
    
    int newStreak = 1;
    if (lastActive != null) {
      final lastDate = DateTime.parse(lastActive);
      final difference = now.difference(lastDate).inDays;
      
      if (difference == 1) {
        final currentStreak = prefs.getInt('streak_$childId') ?? 0;
        newStreak = currentStreak + 1;
      } else if (difference > 1) {
        newStreak = 1;
      } else {
        newStreak = prefs.getInt('streak_$childId') ?? 1;
      }
    }
    
    await prefs.setInt('streak_$childId', newStreak);
    await prefs.setString('last_active_$childId', now.toIso8601String());
    print('🔥 Streak mis à jour: $newStreak jours');
  }

  // Ajouter tous (pour un jeu complété)
  Future<void> addGameCompletion(String childId, int pointsGagnes) async {  // ← 'é' remplacé par 'e'
    await addGameCompleted(childId);
    await addPoints(childId, pointsGagnes);
    await updateStreak(childId);
  }

  // Ajouter tous (pour une activité complétée)
  Future<void> addActivityCompletion(String childId, int pointsGagnes) async {  // ← 'é' remplacé par 'e'
    await addActivityCompleted(childId);
    await addPoints(childId, pointsGagnes);
    await updateStreak(childId);
  }

  // Récupérer toutes les statistiques
  Future<Map<String, int>> getStats(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalGames': prefs.getInt('total_games_$childId') ?? 0,
      'totalPoints': prefs.getInt('points_$childId') ?? 0,
      'totalActivities': prefs.getInt('total_activities_$childId') ?? 0,
      'streak': prefs.getInt('streak_$childId') ?? 0,
    };
  }
}