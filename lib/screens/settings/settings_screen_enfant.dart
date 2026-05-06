// lib/screens/settings/settings_screen_enfant.dart

import 'package:edulearn_final/providers/animation_provider.dart';
import 'package:edulearn_final/providers/theme_provider.dart';
import 'package:edulearn_final/services/notifications/notification_service.dart';
import 'package:edulearn_final/widgets/text_size_customizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../providers/text_size_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/local_auth_service.dart';


class SettingsScreenEnfant extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const SettingsScreenEnfant({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<SettingsScreenEnfant> createState() => _SettingsScreenEnfantState();
}

class _SettingsScreenEnfantState extends State<SettingsScreenEnfant>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final SoundService _soundService = SoundService();
  final LocalAuthService _auth = LocalAuthService();
  Map<String, dynamic>? _childData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadChildData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  Widget _buildAnimationCard(bool isDarkMode, SettingsProvider settingsProvider) {
    final animationProvider = Provider.of<AnimationProvider>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.animation, size: 20, color: Colors.orange),
            ),
            title: Text(
              'Animations',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Activer les animations dans l\'application',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            value: animationProvider.animationsEnabled,
            onChanged: (value) {
              _playClickSound();
              animationProvider.setAnimationsEnabled(value);
            },
            activeColor: AppTheme.primaryColor,
          ),
          if (animationProvider.animationsEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.speed, size: 20, color: Colors.purple),
              ),
              title: Text(
                'Vitesse des animations',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : AppTheme.text,
                ),
              ),
              subtitle: Slider(
                value: animationProvider.animationSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${(animationProvider.animationSpeed * 100).toInt()}%',
                onChanged: (value) {
                  animationProvider.setAnimationSpeed(value);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadChildData() async {
    if (widget.childId != null) {
      final child = await _auth.getChildById(widget.childId!);
      setState(() {
        _childData = child;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
    HapticFeedback.lightImpact();
  }

  // ==================== MÉTHODES DE NOTIFICATIONS ====================
  
  // ==================== MÉTHODES DE NOTIFICATIONS ====================

Future<void> _testNotification() async {
  await _playClickSound();
  // CORRECTION: Appel statique sans ()
  await NotificationService.showSimpleNotification(
    title: '🧪 Test de notification',
    body: 'Les notifications fonctionnent ! 🎉',
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('📱 Notification de test envoyée !'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}

Future<void> _testSuccessNotification() async {
  await _playClickSound();
  // CORRECTION: Appel statique sans ()
  await NotificationService.showSuccessNotification(
    'Tu as gagné 50 points ! 🎉',
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('✨ Notification de succès envoyée !'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}

Future<void> _testScheduledNotification() async {
  await _playClickSound();
  final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
  // CORRECTION: Appel statique sans ()
  await NotificationService.scheduleReminderNotification(
    title: '⏰ Rappel EduLearn',
    body: 'C\'est le moment de jouer et d\'apprendre !',
    scheduledTime: scheduledTime,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⏰ Notification planifiée dans 10 secondes'),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ),
  );
}

  // ==================== FIN MÉTHODES NOTIFICATIONS ====================

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
          appBar: _buildAppBar(isDarkMode, isTablet),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildProfileHeader(isDarkMode, isTablet),
                          const SizedBox(height: 20),
                          _buildStatsCards(settingsProvider, isDarkMode, isTablet),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader('🎨 Apparence', Icons.palette_outlined, isDarkMode),
                        _buildThemeCard(isDarkMode, settingsProvider, themeProvider),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('🌐 Langue', Icons.language_outlined, isDarkMode),
                        _buildLanguageCard(isDarkMode, settingsProvider),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('🔊 Sons', Icons.volume_up_outlined, isDarkMode),
                        _buildSoundCard(isDarkMode, settingsProvider),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('🔔 Notifications', Icons.notifications_outlined, isDarkMode),
                        _buildNotificationCard(isDarkMode, settingsProvider),
                        const SizedBox(height: 16),
                        
                        // SECTION TEST NOTIFICATIONS (NOUVEAU)
                        _buildSectionHeader('🧪 Test Notifications', Icons.science_outlined, isDarkMode),
                        _buildTestNotificationCard(isDarkMode),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('📱 Affichage', Icons.display_settings_outlined, isDarkMode),
                        _buildDisplayCard(isDarkMode, settingsProvider, textSizeProvider),
                        const SizedBox(height: 16),

                        _buildSectionHeader('🎬 Animations', Icons.animation, isDarkMode),
                        _buildAnimationCard(isDarkMode, settingsProvider),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('ℹ️ À propos', Icons.info_outline, isDarkMode),
                        _buildAboutCard(isDarkMode),
                        const SizedBox(height: 30),
                        
                        Center(
                          child: Text(
                            'Version 1.0.0',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, bool isTablet) {
    return AppBar(
      title: Text(
        '⚙️ Mes paramètres',
        style: GoogleFonts.poppins(
          fontSize: isTablet ? 22 : 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Retour',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            _playClickSound();
            setState(() {});
          },
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            const Color(0xFF4A3AFF),
            const Color(0xFF8B85FF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 80 : 65,
            height: isTablet ? 80 : 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getAvatarEmoji(),
                style: TextStyle(fontSize: isTablet ? 45 : 35),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.childName ?? _childData?['name'] ?? 'Mon profil',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildProfileChip('🎓 Niveau ${_childData?['level'] ?? 1}', Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 8),
                    _buildProfileChip('⭐ ${_childData?['points'] ?? 0} pts', Colors.amber.withOpacity(0.3)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Série: ${_childData?['streak'] ?? 0} jours',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAvatarEmoji() {
    final avatarIndex = _childData?['avatarIndex'] ?? 0;
    final avatars = ['👶', '🎓', '✨', '🚀', '🌳', '🎵'];
    return avatars[avatarIndex.clamp(0, avatars.length - 1)];
  }

  Widget _buildProfileChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsCards(SettingsProvider settingsProvider, bool isDarkMode, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.volume_up,
              title: 'Son',
              value: settingsProvider.soundEnabled ? 'Activé' : 'Désactivé',
              color: Colors.blue,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.notifications,
              title: 'Notifications',
              value: settingsProvider.notifications ? 'Activées' : 'Désactivées',
              color: Colors.purple,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.language,
              title: 'Langue',
              value: _getLanguageName(settingsProvider.currentLanguage),
              color: Colors.green,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      case 'ar': return 'العربية';
      default: return 'Français';
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(bool isDarkMode, SettingsProvider settingsProvider, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRadioTileTheme(
            title: 'Mode clair',
            icon: Icons.light_mode,
            iconColor: Colors.amber,
            isSelected: !themeProvider.isDarkMode,
            onTap: () {
              _playClickSound();
              themeProvider.setTheme(false);
            },
            isDarkMode: isDarkMode,
          ),
          const Divider(height: 1),
          _buildRadioTileTheme(
            title: 'Mode sombre',
            icon: Icons.dark_mode,
            iconColor: Colors.indigo,
            isSelected: themeProvider.isDarkMode,
            onTap: () {
              _playClickSound();
              themeProvider.setTheme(true);
            },
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTileTheme({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppTheme.text,
        ),
      ),
      trailing: Radio<bool>(
        value: true,
        groupValue: isSelected,
        onChanged: (_) => onTap(),
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }

  Widget _buildLanguageCard(bool isDarkMode, SettingsProvider settingsProvider) {
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'native': 'Français'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'native': 'English'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'native': 'العربية'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: languages.map((lang) {
          final isSelected = settingsProvider.currentLanguage == lang['code'];
          return ListTile(
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
            title: Text(
              lang['name']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              lang['native']!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: isSelected
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
            onTap: () {
              _playClickSound();
              settingsProvider.setLanguage(lang['code']!);
            },
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.audiotrack, size: 20, color: AppTheme.primaryColor),
            ),
            title: Text(
              'Effets sonores',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Activer les sons lors des interactions',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            value: settingsProvider.soundEnabled,
            onChanged: (value) {
              _playClickSound();
              settingsProvider.setSoundEnabled(value);
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.vibration, size: 20, color: AppTheme.primaryColor),
            ),
            title: Text(
              'Vibrations',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Activer les retours haptiques',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            value: settingsProvider.vibrationEnabled,
            onChanged: (value) => settingsProvider.setVibrationEnabled(value),
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_active, size: 20, color: AppTheme.primaryColor),
        ),
        title: Text(
          'Notifications push',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : AppTheme.text,
          ),
        ),
        subtitle: Text(
          'Recevoir des rappels quotidiens',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
        ),
        value: settingsProvider.notifications,
        onChanged: (value) {
          _playClickSound();
          settingsProvider.setNotifications(value);
        },
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // NOUVEAU : Carte de test des notifications
  Widget _buildTestNotificationCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active, size: 20, color: Colors.blue),
            ),
            title: Text(
              'Tester notification immédiate',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Affiche une notification instantanée',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _testNotification,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, size: 20, color: Colors.green),
            ),
            title: Text(
              'Tester notification de succès',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Affiche une notification de récompense',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _testSuccessNotification,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer, size: 20, color: Colors.orange),
            ),
            title: Text(
              'Tester notification planifiée',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              'Notification dans 10 secondes',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _testScheduledNotification,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayCard(bool isDarkMode, SettingsProvider settingsProvider, TextSizeProvider textSizeProvider) {
    final currentSize = (textSizeProvider.textScaleFactor * 100).toInt();
    String sizeLabel = 'Normal';
    if (currentSize < 90) sizeLabel = 'Petit';
    else if (currentSize > 110) sizeLabel = 'Grand';
    if (currentSize > 120) sizeLabel = 'Très grand';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.text_fields, size: 20, color: Colors.blue),
            ),
            title: Text(
              'Taille du texte',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            subtitle: Text(
              '$sizeLabel · $currentSize%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showTextSizeDialog(isDarkMode),
          ),
        ],
      ),
    );
  }

  void _showTextSizeDialog(bool isDarkMode) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const TextSizeCustomizer(
        showPreview: true,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, size: 20, color: Colors.blue),
            ),
            title: Text(
              'À propos d\'EduLearn',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showAboutDialog(isDarkMode),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_outline, size: 20, color: Colors.amber),
            ),
            title: Text(
              'Noter l\'application',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showComingSoon('Noter'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_outlined, size: 20, color: Colors.teal),
            ),
            title: Text(
              'Partager',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showComingSoon('Partager'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.privacy_tip_outlined, size: 20, color: Colors.red),
            ),
            title: Text(
              'Confidentialité',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppTheme.text,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showComingSoon('Confidentialité'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'EduLearn',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Application éducative pour enfants',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildInfoRow('📖', 'Version', '1.0.0', isDarkMode),
              _buildInfoRow('👨‍💻', 'Développeurs', 'EduLearn Team', isDarkMode),
              _buildInfoRow('🤖', 'ML Kit', '6 services', isDarkMode),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Services intégrés',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.text,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildServiceChip('OCR', Colors.blue),
                  _buildServiceChip('Vision', Colors.green),
                  _buildServiceChip('Traduction', Colors.orange),
                  _buildServiceChip('Langues', Colors.purple),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛠️ $feature - Bientôt disponible'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}