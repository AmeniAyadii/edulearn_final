// lib/models/local_notification_model.dart

import 'package:awesome_notifications/awesome_notifications.dart';

class LocalNotificationModel {
  final int id;
  final String title;
  final String body;
  final DateTime? scheduledDate;
  final bool isScheduled;

  LocalNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.scheduledDate,
    this.isScheduled = false,
  });

  factory LocalNotificationModel.fromAwesome(ReceivedNotification notification) {
    return LocalNotificationModel(
      id: notification.id ?? 0,
      title: notification.title ?? '',
      body: notification.body ?? '',
      isScheduled: notification.scheduledDate != null,
    );
  }
}