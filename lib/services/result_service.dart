import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/result_model.dart';

class ResultService {
  static const String _resultsKey = 'app_results';
  static ResultService? _instance;
  
  static ResultService get instance {
    _instance ??= ResultService._internal();
    return _instance!;
  }
  
  ResultService._internal();
  
  // Sauvegarder un résultat
  Future<void> saveResult(ResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_resultsKey);
    List<Map<String, dynamic>> results = [];
    
    if (resultsJson != null) {
      results = List<Map<String, dynamic>>.from(jsonDecode(resultsJson));
    }
    
    results.add(result.toJson());
    await prefs.setString(_resultsKey, jsonEncode(results));
    
    // Mettre à jour les points de l'enfant
    await _updateChildPoints(result.childId, result.score);
  }
  
  // Mettre à jour les points de l'enfant
  Future<void> _updateChildPoints(String childId, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final childrenJson = prefs.getString('app_children');
    
    if (childrenJson != null) {
      final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      final index = children.indexWhere((c) => c['id'] == childId);
      
      if (index != -1) {
        children[index]['points'] = (children[index]['points'] ?? 0) + points;
        await prefs.setString('app_children', jsonEncode(children));
      }
    }
  }
  
  // Récupérer tous les résultats d'un enfant
  Future<List<ResultModel>> getChildResults(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_resultsKey);
    
    if (resultsJson == null) return [];
    
    final results = List<Map<String, dynamic>>.from(jsonDecode(resultsJson));
    return results
        .where((r) => r['childId'] == childId)
        .map((r) => ResultModel.fromJson(r))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  // Récupérer les résultats par type d'activité
  Future<List<ResultModel>> getResultsByType(String childId, String activityType) async {
    final allResults = await getChildResults(childId);
    return allResults.where((r) => r.activityType == activityType).toList();
  }
  
  // Récupérer les résultats des 7 derniers jours
  Future<List<ResultModel>> getLastWeekResults(String childId) async {
    final allResults = await getChildResults(childId);
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return allResults.where((r) => r.date.isAfter(oneWeekAgo)).toList();
  }
  
  // Statistiques globales
  Future<Map<String, dynamic>> getStatistics(String childId) async {
    final results = await getChildResults(childId);
    
    if (results.isEmpty) {
      return {
        'totalActivities': 0,
        'totalPoints': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'totalTimeSpent': 0,
        'activitiesByType': {},
        'dailyProgress': [],
      };
    }
    
    final activitiesByType = <String, int>{};
    for (var result in results) {
      activitiesByType[result.activityType] = (activitiesByType[result.activityType] ?? 0) + 1;
    }
    
    // Progression quotidienne
    final dailyProgress = <String, int>{};
    for (var result in results) {
      final dateKey = result.formattedDate;
      dailyProgress[dateKey] = (dailyProgress[dateKey] ?? 0) + result.score;
    }
    
    return {
      'totalActivities': results.length,
      'totalPoints': results.fold(0, (sum, r) => sum + r.score),
      'averageScore': results.fold(0.0, (sum, r) => sum + r.percentage) / results.length,
      'bestScore': results.map((r) => r.score).reduce((a, b) => a > b ? a : b),
      'totalTimeSpent': results.fold(0, (sum, r) => sum + r.timeSpent),
      'activitiesByType': activitiesByType,
      'dailyProgress': dailyProgress,
    };
  }
  
  // Supprimer un résultat
  Future<void> deleteResult(String resultId) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_resultsKey);
    
    if (resultsJson != null) {
      final results = List<Map<String, dynamic>>.from(jsonDecode(resultsJson));
      results.removeWhere((r) => r['id'] == resultId);
      await prefs.setString(_resultsKey, jsonEncode(results));
    }
  }
  
  // Supprimer tous les résultats d'un enfant
  Future<void> deleteAllResults(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_resultsKey);
    
    if (resultsJson != null) {
      final results = List<Map<String, dynamic>>.from(jsonDecode(resultsJson));
      results.removeWhere((r) => r['childId'] == childId);
      await prefs.setString(_resultsKey, jsonEncode(results));
    }
  }
  
  // Exporter les résultats en JSON
  Future<String> exportResultsToJson(String childId) async {
    final results = await getChildResults(childId);
    final exportData = {
      'childId': childId,
      'exportDate': DateTime.now().toIso8601String(),
      'totalResults': results.length,
      'results': results.map((r) => r.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }
}