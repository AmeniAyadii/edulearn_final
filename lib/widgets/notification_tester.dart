// lib/widgets/notification_tester.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationTester extends StatelessWidget {
  const NotificationTester({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '🧪 Test des notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  context,
                  'Succès',
                  Colors.green,
                  () => NotificationService.showAchievementNotification(
                    title: '🎉 Nouveau succès !',
                    body: 'Vous avez complété 10 activités !',
                  ),
                ),
                _buildTestButton(
                  context,
                  'Jeu terminé',
                  Colors.orange,
                  () => NotificationService.showGameCompletedNotification(
                    gameName: 'Quiz Éducatif',
                    score: 95,
                    points: 150,
                  ),
                ),
                _buildTestButton(
                  context,
                  'Niveau +',
                  Colors.purple,
                  () => NotificationService.showLevelUpNotification(5),
                ),
                _buildTestButton(
                  context,
                  'Série',
                  Colors.red,
                  () => NotificationService.showStreakNotification(7),
                ),
                _buildTestButton(
                  context,
                  'Rappel maintenant',
                  Colors.blue,
                  () => NotificationService.showDailyReminder(),
                ),
                _buildTestButton(
                  context,
                  'Rappel 18h',
                  Colors.teal,
                  () => NotificationService.scheduleDailyReminder(hour: 18, minute: 0),
                ),
                _buildTestButton(
                  context,
                  'Annuler tout',
                  Colors.grey,
                  () => NotificationService.cancelAllNotifications(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Mettez l\'application en arrière-plan pour voir les notifications',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '• Les notifications s\'affichent dans la barre de notification',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '• Vérifiez que les permissions sont activées dans les paramètres du téléphone',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notification "$label" envoyée'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}