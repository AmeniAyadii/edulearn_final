// lib/providers/child_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildProvider extends ChangeNotifier {
  String? _currentChildId;
  String? _currentChildName;
  int? _currentChildPoints;
  int? _currentChildLevel;
  
  String? get currentChildId => _currentChildId;
  String? get currentChildName => _currentChildName;
  int? get currentChildPoints => _currentChildPoints;
  int? get currentChildLevel => _currentChildLevel;
  
  Future<void> setCurrentChild(String id, String name) async {
    _currentChildId = id;
    _currentChildName = name;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_child_id', id);
    await prefs.setString('current_child_name', name);
    
    notifyListeners();
  }
  
  Future<void> loadCurrentChild() async {
    final prefs = await SharedPreferences.getInstance();
    _currentChildId = prefs.getString('current_child_id');
    _currentChildName = prefs.getString('current_child_name');
    notifyListeners();
  }
  
  void clearChild() {
    _currentChildId = null;
    _currentChildName = null;
    notifyListeners();
  }
  
  void updateChildStats(int points, int level) {
    _currentChildPoints = points;
    _currentChildLevel = level;
    notifyListeners();
  }
}