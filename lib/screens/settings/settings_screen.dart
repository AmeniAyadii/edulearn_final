import 'package:easy_localization/easy_localization.dart';
import 'package:edulearn_final/providers/language_provider.dart';
import 'package:edulearn_final/providers/theme_provider.dart';
import 'package:edulearn_final/screens/word_history_screen.dart';
import 'package:edulearn_final/widgets/language_selector.dart';
import 'package:edulearn_final/screens/history_screen.dart'; // ✅ AJOUTER CET IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/vibration_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const SettingsScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // État des paramètres
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Français';
  String _selectedLanguageCode = 'fr';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _soundEnabled = prefs.getBool('sound') ?? true;
      _musicEnabled = prefs.getBool('music') ?? true;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
      _selectedLanguageCode = prefs.getString('language') ?? 'fr';
      _selectedLanguage = _getLanguageName(_selectedLanguageCode);
    });
  }

  String _getLanguageName(String code) {
    final language = _languages.firstWhere((l) => l['code'] == code, orElse: () => _languages.first);
    return language['name']!;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('sound', _soundEnabled);
    await prefs.setBool('music', _musicEnabled);
    await prefs.setBool('vibration', _vibrationEnabled);
    await prefs.setBool('darkMode', _darkModeEnabled);
    await prefs.setString('language', _selectedLanguageCode);
    
    // Mettre à jour les services
    SoundService().setSoundEnabled(_soundEnabled);
    SoundService().setMusicEnabled(_musicEnabled);
    VibrationService().setVibrationEnabled(_vibrationEnabled);
  }

  Future<void> _applyTheme(BuildContext context) async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen(
          childId: widget.childId,
          childName: widget.childName,
        )),
      );
    }
  }

  Future<void> _playSound() async {
    await SoundService().playClick();
  }

  void _navigateToHistory() async {
    await _playSound();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordHistoryScreen(
            childId: widget.childId,
            //childName: widget.childName,
          ),
        ),
      );
    }
  }

  void _showLanguageDialog() async {
    await _playSound();
    final isDark = _darkModeEnabled;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choisir la langue',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sélectionnez votre langue préférée',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ..._languages.map((lang) => ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 30)),
              title: Text(
                lang['name']!,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: _selectedLanguageCode == lang['code']
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 18, color: AppTheme.primaryColor),
                    )
                  : null,
              onTap: () async {
                await _playSound();
                setState(() {
                  _selectedLanguageCode = lang['code']!;
                  _selectedLanguage = lang['name']!;
                });
                await _saveSettings();
                if (mounted) Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() async {
    await _playSound();
    final isDark = _darkModeEnabled;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'À propos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school, size: 50, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'EduLearn',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Application éducative pour enfants',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.copyright, size: 14),
    SizedBox(width: 4),
    Expanded(
      child: Text(
        '2026 EduLearn. Tous droits réservés.',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    ),
  ],
)
              
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _playSound();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    await _playSound();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Vider le cache',
          style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Cette action supprimera les données temporaires. Voulez-vous continuer ?',
          style: TextStyle(color: _darkModeEnabled ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _playSound();
              if (mounted) Navigator.pop(context, false);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _playSound();
              if (mounted) Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache vidé avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : AppTheme.lightBackground;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Paramètres',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showAboutDialog,
              tooltip: 'À propos',
            ),
          ],
        ),
        body: isTablet
            ? Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildSettingsMenu(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildSettingsContent(),
                  ),
                ],
              )
            : _buildSettingsContent(),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    final isDark = _darkModeEnabled;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _buildMenuTile(Icons.person, 'Profil', 0),
          _buildMenuTile(Icons.history, 'Historique', 1), // ✅ AJOUTER CETTE LIGNE
          _buildMenuTile(Icons.notifications, 'Notifications', 2),
          _buildMenuTile(Icons.language, 'Langue', 3),
          _buildMenuTile(Icons.volume_up, 'Son', 4),
          _buildMenuTile(Icons.security, 'Confidentialité', 5),
          _buildMenuTile(Icons.storage, 'Stockage', 6),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, int index) {
    final textColor = _darkModeEnabled ? Colors.white : Colors.black87;
    
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: () async {
        await _playSound();
        // Navigation selon l'index
        if (title == 'Historique') {
          _navigateToHistory();
        }
      },
    );
  }

  Widget _buildSettingsContent() {
    final isDark = _darkModeEnabled;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.text;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Profil
        _buildSectionHeader(Icons.person, 'Profil', Colors.blue),
        const SizedBox(height: 8),
        _buildProfileCard(),
        const SizedBox(height: 24),
        
        // ✅ NOUVELLE SECTION HISTORIQUE
        _buildSectionHeader(Icons.history, 'Historique', Colors.teal),
        const SizedBox(height: 8),
        _buildNavigationTile(
          icon: Icons.history,
          title: 'Historique des activités',
          subtitle: 'Consulter l\'historique des scans et jeux',
          onTap: _navigateToHistory,
          color: Colors.teal,
        ),
        const SizedBox(height: 24),
        
        // Section Préférences
        _buildSectionHeader(Icons.settings, 'Préférences', Colors.purple),
        const SizedBox(height: 8),
        
        // Notifications
        _buildSwitchTile(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Recevoir des alertes et rappels',
          value: _notificationsEnabled,
          onChanged: (value) async {
            await _playSound();
            setState(() => _notificationsEnabled = value);
            await _saveSettings();
          },
          color: Colors.blue,
        ),
        
        // Effets sonores
        _buildSwitchTile(
          icon: Icons.volume_up,
          title: 'Effets sonores',
          subtitle: 'Activer les sons dans l\'application',
          value: _soundEnabled,
          onChanged: (value) async {
            await _playSound();
            setState(() => _soundEnabled = value);
            SoundService().setSoundEnabled(value);
            await _saveSettings();
            if (value) await SoundService().playClick();
          },
          color: Colors.green,
        ),
        
        // Musique de fond
        _buildSwitchTile(
          icon: Icons.music_note,
          title: 'Musique de fond',
          subtitle: 'Activer la musique d\'ambiance',
          value: _musicEnabled,
          onChanged: (value) async {
            await _playSound();
            setState(() => _musicEnabled = value);
            SoundService().setMusicEnabled(value);
            await _saveSettings();
            
            if (value) {
              await SoundService().startBackgroundMusic();
            } else {
              await SoundService().stopBackgroundMusic();
            }
          },
          color: Colors.purple,
        ),
        
        // Vibration
        _buildSwitchTile(
          icon: Icons.vibration,
          title: 'Vibration',
          subtitle: 'Retour haptique au toucher',
          value: _vibrationEnabled,
          onChanged: (value) async {
            setState(() => _vibrationEnabled = value);
            VibrationService().setVibrationEnabled(value);
            await _saveSettings();
            if (value) await VibrationService().click();
          },
          color: Colors.orange,
        ),
        
        // Mode sombre
        _buildSwitchTile(
          icon: Icons.dark_mode,
          title: 'Mode sombre',
          subtitle: 'Interface adaptative',
          value: _darkModeEnabled,
          onChanged: (value) async {
            await _playSound();
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            await themeProvider.setTheme(value);
            setState(() {
              _darkModeEnabled = value;
            });
            await _saveSettings();
          },
          color: Colors.indigo,
        ),
        
        const SizedBox(height: 16),
        
        // Langue
        _buildNavigationTile(
          icon: Icons.language,
          title: 'Langue'.tr(),
          subtitle: _getLanguageDisplay(),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const LanguageSelector(),
            );
          },
          color: Colors.teal,
        ),
        
        const SizedBox(height: 24),
        
        // Section Données
        _buildSectionHeader(Icons.data_usage, 'Données', Colors.orange),
        const SizedBox(height: 8),
        
        // Cache
        _buildNavigationTile(
          icon: Icons.storage,
          title: 'Cache',
          subtitle: 'Gérer les données temporaires',
          onTap: _clearCache,
          color: Colors.amber,
        ),
        
        // Confidentialité
        _buildNavigationTile(
          icon: Icons.security,
          title: 'Confidentialité',
          subtitle: 'Gérer vos données personnelles',
          onTap: () async {
            await _playSound();
          },
          color: Colors.red,
        ),
        
        const SizedBox(height: 24),
        
        // Section Support
        _buildSectionHeader(Icons.support, 'Support', Colors.green),
        const SizedBox(height: 8),
        
        // Aide
        _buildNavigationTile(
          icon: Icons.help,
          title: 'Aide',
          subtitle: 'Guide d\'utilisation',
          onTap: () async {
            await _playSound();
          },
          color: Colors.blue,
        ),
        
        // Nous contacter
        _buildNavigationTile(
          icon: Icons.email,
          title: 'Nous contacter',
          subtitle: 'support@edulearn.com',
          onTap: () async {
            await _playSound();
          },
          color: Colors.purple,
        ),
        
        const SizedBox(height: 16),
        
        // Version
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 32),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 EduLearn',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: subtitleColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    final textColor = _darkModeEnabled ? Colors.white : AppTheme.text;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () async {
        await _playSound();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 35,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.childName ?? 'Utilisateur',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Modifier votre profil',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    final isDark = _darkModeEnabled;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: color,
        activeTrackColor: color.withOpacity(0.3),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = _darkModeEnabled;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getLanguageDisplay() {
    switch (_selectedLanguageCode) {
      case 'fr': return '🇫🇷 Français';
      case 'en': return '🇬🇧 English';
      case 'ar': return '🇸🇦 العربية';
      default: return '🇫🇷 Français';
    }
  }
}