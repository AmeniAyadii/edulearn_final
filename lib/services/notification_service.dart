import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isNotificationEnabled = true;

  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isNotificationEnabled = prefs.getBool('notifications') ?? true;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _isNotificationEnabled);
  }

  bool get isNotificationEnabled => _isNotificationEnabled;

  void setNotificationEnabled(bool enabled) {
    _isNotificationEnabled = enabled;
    saveSettings();
  }

  // Méthodes pour la compatibilité
  Future<void> sendMotivationNotification() async {
    print('Notification de motivation (simulée)');
  }

  Future<void> sendProgressNotification({
    required int points,
    required int level,
  }) async {
    print('Progression: $points points, niveau $level');
  }

  Future<void> sendStreakNotification({required int streak}) async {
    print('Série: $streak jours');
  }
}