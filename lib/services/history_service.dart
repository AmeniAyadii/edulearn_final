import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recognition_history.dart';

class HistoryService {
  static const String _historyKey = 'recognition_history';
  static const int _maxHistorySize = 50;

  Future<void> saveHistory(RecognitionHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getHistory();
    
    historyList.insert(0, history);
    
    // Limiter la taille de l'historique
    if (historyList.length > _maxHistorySize) {
      historyList.removeLast();
    }
    
    final jsonList = historyList.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<RecognitionHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    
    if (historyString == null || historyString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(historyString);
      return jsonList.map((json) => RecognitionHistory.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteHistory(String id) async {
    final historyList = await getHistory();
    historyList.removeWhere((h) => h.id == id);
    
    final jsonList = historyList.map((h) => h.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<RecognitionHistory?> getHistoryById(String id) async {
    final historyList = await getHistory();
    try {
      return historyList.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
}