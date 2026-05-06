// lib/services/notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static bool _initialized = false;

  // Initialiser le service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser avec l'icône par défaut
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'achievements_channel',
          channelName: 'Récompenses et succès',
          channelDescription: 'Notifications pour les récompenses et succès',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'reminders_channel',
          channelName: 'Rappels',
          channelDescription: 'Rappels quotidiens',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'games_channel',
          channelName: 'Jeux',
          channelDescription: 'Notifications liées aux jeux',
          defaultColor: const Color(0xFFFF9800),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'test_channel',
          channelName: 'Test',
          channelDescription: 'Tests de notification',
          defaultColor: const Color(0xFF9C27B0),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      channelGroups: [],
    );

    // Demander la permission
    await AwesomeNotifications().requestPermissionToSendNotifications();
    
    _initialized = true;
    debugPrint('✅ Service de notifications initialisé');
  }

  // ==================== MÉTHODES PRINCIPALES ====================

  // Notification simple immédiate
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? actionRoute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'test_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF9C27B0),
        payload: {'route': actionRoute ?? '/'},
      ),
    );
  }

  // Notification de succès
  static Future<void> showSuccessNotification(String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'achievements_channel',
        title: '✨ Bravo ! ✨',
        body: message,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF4CAF50),
        payload: {'route': '/'},
      ),
    );
  }

  // Notification planifiée
  static Future<void> scheduleReminderNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? actionRoute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: scheduledTime.millisecondsSinceEpoch.remainder(100000),
        channelKey: 'reminders_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
        payload: {'route': actionRoute ?? '/'},
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime,
        preciseAlarm: true,
      ),
    );
  }

  // ==================== AUTRES MÉTHODES ====================

  // Notification de succès / récompense
  static Future<void> showAchievementNotification({
    required String title,
    required String body,
    String? actionRoute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'achievements_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF4CAF50),
        payload: {'route': actionRoute ?? '/'},
      ),
    );
  }

  // Notification de jeu terminé
  static Future<void> showGameCompletedNotification({
    required String gameName,
    required int score,
    required int points,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'games_channel',
        title: '🎮 Jeu terminé !',
        body: 'Félicitations ! "$gameName" terminé: $score/100 (+$points pts)',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFFFF9800),
        payload: {'route': '/games_menu'},
      ),
    );
  }

  // Notification de niveau supérieur
  static Future<void> showLevelUpNotification(int newLevel) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'achievements_channel',
        title: '⭐ Niveau supérieur !',
        body: 'Félicitations ! Vous avez atteint le niveau $newLevel !',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF9C27B0),
        payload: {'route': '/child_dashboard'},
      ),
    );
  }

  // Notification de série (streak)
  static Future<void> showStreakNotification(int streak) async {
    String message = '🔥 Incroyable ! $streak jours d\'affilée !';
    if (streak == 1) {
      message = '🔥 Vous avez commencé une série de $streak jour(s) ! Continuez !';
    } else if (streak == 7) {
      message = '🏆 7 jours de suite ! Vous êtes sur une bonne lancée !';
    } else if (streak == 30) {
      message = '🎉 30 jours consécutifs ! Vous êtes une légende !';
    }
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'achievements_channel',
        title: 'Série en cours',
        body: message,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFFF44336),
        payload: {'route': '/child_dashboard'},
      ),
    );
  }

  // Rappel quotidien instantané
  static Future<void> showDailyReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'reminders_channel',
        title: '🌙 C\'est l\'heure d\'apprendre !',
        body: 'N\'oubliez pas votre session d\'apprentissage du soir.',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
        payload: {'route': '/activities_menu'},
      ),
    );
  }

  // Notification d'information
  static Future<void> showInfoNotification({
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'reminders_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
      ),
    );
  }

  // Programmer un rappel quotidien (à une heure précise)
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'reminders_channel',
        title: '⏰ Rappel quotidien',
        body: 'N\'oubliez pas votre session d\'apprentissage aujourd\'hui !',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
        payload: {'route': '/activities_menu'},
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  // Programmer une notification unique
  static Future<void> scheduleSingleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? actionRoute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: scheduledDate.millisecondsSinceEpoch.remainder(100000),
        channelKey: 'reminders_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
        payload: {'route': actionRoute ?? '/'},
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );
  }

  // Annuler une notification programmée
  static Future<void> cancelScheduledNotification(int id) async {
    await AwesomeNotifications().cancelSchedule(id);
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // Vérifier si les permissions sont accordées
  static Future<bool> arePermissionsGranted() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Demander les permissions
  static Future<void> requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}