import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
//import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildSettingsScreen extends StatefulWidget {
  final String childId;
  const ChildSettingsScreen({super.key, required this.childId});

  @override
  State<ChildSettingsScreen> createState() => _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends State<ChildSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Section Apparence
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Apparence', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer le thème sombre'),
            value: settingsProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              settingsProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          
          const Divider(),
          
          // Section Sons et vibrations
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Sons et vibrations', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Effets sonores'),
            subtitle: const Text('Activer les sons de l\'application'),
            value: settingsProvider.soundEnabled,
            onChanged: (value) => settingsProvider.setSoundEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Vibrations'),
            subtitle: const Text('Activer les vibrations au scan'),
            value: settingsProvider.vibrationEnabled,
            onChanged: (value) => settingsProvider.setVibrationEnabled(value),
          ),
          
          const Divider(),
          
          // Section Notifications
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir des rappels et récompenses'),
            value: settingsProvider.notifications,
            onChanged: (value) => settingsProvider.setNotifications(value),
          ),
          
          const Divider(),
          
          // Section Langue
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Langue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Français'),
            leading: Radio<String>(
              value: 'fr',
              groupValue: settingsProvider.currentLanguage,
              onChanged: (value) => settingsProvider.setLanguage(value!),
            ),
          ),
          ListTile(
            title: const Text('English'),
            leading: Radio<String>(
              value: 'en',
              groupValue: settingsProvider.currentLanguage,
              onChanged: (value) => settingsProvider.setLanguage(value!),
            ),
          ),
          ListTile(
            title: const Text('العربية'),
            leading: Radio<String>(
              value: 'ar',
              groupValue: settingsProvider.currentLanguage,
              onChanged: (value) => settingsProvider.setLanguage(value!),
            ),
          ),
          
          const Divider(),
          
          // Section À propos
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('À propos', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos d\'EduLearn'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos d\'EduLearn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application éducative pour enfants'),
            const SizedBox(height: 8),
            const Text('Services ML Kit utilisés:'),
            const Text('• Reconnaissance de texte (OCR)'),
            const Text('• Identification de langue'),
            const Text('• Traduction'),
            const Text('• Étiquetage d\'image'),
            const Text('• Détection d\'objets'),
            const Text('• Smart Reply'),
            const SizedBox(height: 16),
            Text(
              '© 2024 EduLearn',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}