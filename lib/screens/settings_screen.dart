import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Section Profil
          _buildSectionHeader('👤 Profil', Icons.person_outline, isDarkMode),
          _buildProfileCard(isDarkMode),
          
          const SizedBox(height: 16),
          
          // Section Apparence
          _buildSectionHeader('🎨 Apparence', Icons.palette_outlined, isDarkMode),
          _buildThemeCard(isDarkMode, settingsProvider),
          
          const SizedBox(height: 16),
          
          // Section Langue
          _buildSectionHeader('🌐 Langue', Icons.language_outlined, isDarkMode),
          _buildLanguageCard(isDarkMode, settingsProvider),
          
          const SizedBox(height: 16),
          
          // Section Sons et vibrations
          _buildSectionHeader('🔊 Sons et vibrations', Icons.volume_up_outlined, isDarkMode),
          _buildSoundCard(isDarkMode, settingsProvider),
          
          const SizedBox(height: 16),
          
          // Section Notifications
          _buildSectionHeader('🔔 Notifications', Icons.notifications_outlined, isDarkMode),
          _buildNotificationCard(isDarkMode, settingsProvider),
          
          const SizedBox(height: 16),
          
          // Section À propos
          _buildSectionHeader('ℹ️ À propos', Icons.info_outline, isDarkMode),
          _buildAboutCard(isDarkMode),
          
          const SizedBox(height: 30),
          
          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.child_care,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Petit Génie',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apprenti en herbe',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(bool isDarkMode, SettingsProvider settingsProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRadioTile(
            title: 'Mode clair',
            icon: Icons.light_mode,
            value: ThemeMode.light,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) => settingsProvider.setThemeMode(value!),
            isDarkMode: isDarkMode,
          ),
          const Divider(),
          _buildRadioTile(
            title: 'Mode sombre',
            icon: Icons.dark_mode,
            value: ThemeMode.dark,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) => settingsProvider.setThemeMode(value!),
            isDarkMode: isDarkMode,
          ),
          const Divider(),
          _buildRadioTile(
            title: 'Système',
            icon: Icons.smartphone,
            value: ThemeMode.system,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) => settingsProvider.setThemeMode(value!),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDarkMode ? Colors.white : AppTheme.text,
        ),
      ),
      trailing: Radio<ThemeMode>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLanguageCard(bool isDarkMode, SettingsProvider settingsProvider) {
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: languages.map((lang) {
          return ListTile(
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(
              lang['name']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: Radio<String>(
              value: lang['code']!,
              groupValue: settingsProvider.currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setLanguage(value);
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundCard(bool isDarkMode, SettingsProvider settingsProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.audiotrack, color: AppTheme.primaryColor),
            title: Text(
              'Effets sonores',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Activer les sons de l\'application',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
              ),
            ),
            value: settingsProvider.soundEnabled,
            onChanged: (value) => settingsProvider.setSoundEnabled(value),
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(Icons.vibration, color: AppTheme.primaryColor),
            title: Text(
              'Vibrations',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Activer les retours haptiques',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
              ),
            ),
            value: settingsProvider.vibrationEnabled,
            onChanged: (value) => settingsProvider.setVibrationEnabled(value),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(bool isDarkMode, SettingsProvider settingsProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Icon(Icons.notifications_active, color: AppTheme.primaryColor),
        title: Text(
          'Notifications push',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDarkMode ? Colors.white : AppTheme.text,
          ),
        ),
        subtitle: Text(
          'Recevoir des rappels quotidiens',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
          ),
        ),
        value: settingsProvider.notifications,
        onChanged: (value) => settingsProvider.setNotifications(value),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAboutCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.primaryColor),
            title: Text(
              'À propos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            //onTap: () => _showAboutDialog(context, isDarkMode),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.star_outline, color: AppTheme.primaryColor),
            title: Text(
              'Noter l\'application',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.share_outlined, color: AppTheme.primaryColor),
            title: Text(
              'Partager',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
            title: Text(
              'Confidentialité',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'EduLearn',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Application éducative pour enfants',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade300 : AppTheme.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildAboutRow('📖', 'Version', '1.0.0', isDarkMode),
              _buildAboutRow('👨‍💻', 'Développeurs', 'EduLearn Team', isDarkMode),
              _buildAboutRow('🤖', 'ML Kit', '6 services intégrés', isDarkMode),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Services ML Kit utilisés :',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              _buildServiceChip('OCR', Colors.blue),
              _buildServiceChip('Image Labeling', Colors.green),
              _buildServiceChip('Translation', Colors.orange),
              _buildServiceChip('Language ID', Colors.purple),
              _buildServiceChip('Smart Reply', Colors.teal),
              _buildServiceChip('Face Detection', Colors.pink),
              const SizedBox(height: 16),
              Text(
                '© 2024 EduLearn',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String emoji, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade300 : AppTheme.text,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String service, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        service,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}