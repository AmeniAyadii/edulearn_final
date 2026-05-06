import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalWords = 0;
  int _totalPhotos = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _totalWords = 0;
      _totalPhotos = 0;
      _totalPoints = 0;
    });
  }

  void _navigateTo(BuildContext context, String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page en cours de développement'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
              child: const Icon(Icons.school, size: 40, color: Colors.white),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              
              _buildAboutRow('📱', 'Version', '1.0.0', isDarkMode),
              _buildAboutRow('👨‍💻', 'Développeurs', 'EduLearn Team', isDarkMode),
              _buildAboutRow('🤖', 'ML Kit', '6 services intégrés', isDarkMode),
              
              const SizedBox(height: 12),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildServiceChip('OCR', Colors.blue),
                  _buildServiceChip('Image Labeling', Colors.green),
                  _buildServiceChip('Translation', Colors.orange),
                  _buildServiceChip('Language ID', Colors.purple),
                  _buildServiceChip('Smart Reply', Colors.teal),
                  _buildServiceChip('Face Detection', Colors.pink),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              Text(
                'Technologies utilisées :',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTechChip('Flutter', Colors.blue),
                  _buildTechChip('Firebase ML Kit', Colors.orange),
                  _buildTechChip('Google ML Kit', Colors.green),
                  _buildTechChip('SQLite', Colors.purple),
                  _buildTechChip('Shared Preferences', Colors.teal),
                ],
              ),
              
              const SizedBox(height: 16),
              Text(
                '© 2024 EduLearn',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildTechChip(String tech, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tech,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'app_title'.tr(),
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showAboutDialog(context),
                tooltip: 'À propos',
              ),
              IconButton(
                icon: const Icon(Icons.history_outlined),
                onPressed: () => _navigateTo(context, '/history'),
                tooltip: 'history'.tr(),
              ),
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => settingsProvider.toggleTheme(),
                tooltip: isDarkMode ? 'light_mode'.tr() : 'dark_mode'.tr(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _navigateTo(context, '/settings'),
                tooltip: 'settings'.tr(),
              ),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPresentationCard(isDarkMode),
                const SizedBox(height: 20),
                _buildStatsRow(isDarkMode),
                const SizedBox(height: 28),
                _buildSectionTitle('main_features'.tr(), isDarkMode),
                const SizedBox(height: 16),
                _buildFeaturesGrid(),
                const SizedBox(height: 28),
                _buildSectionTitle('additional_tools'.tr(), isDarkMode),
                const SizedBox(height: 12),
                _buildToolsList(isDarkMode),
                const SizedBox(height: 24),
                _buildTipCard(isDarkMode),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.school, size: 30, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hello'.tr(),
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'ready_to_learn'.tr(),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('$_totalPoints', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EduLearn - L\'application qui fait apprendre en s\'amusant !',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : AppTheme.text,
      ),
    );
  }

  Widget _buildStatsRow(bool isDarkMode) {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.menu_book_outlined, '$_totalWords', 'words_read'.tr(), Colors.blue, isDarkMode),
          Container(width: 1, height: 35, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildStatItem(Icons.camera_alt_outlined, '$_totalPhotos', 'photos'.tr(), Colors.orange, isDarkMode),
          Container(width: 1, height: 35, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildStatItem(Icons.emoji_events_outlined, '$_totalPoints', 'points'.tr(), Colors.amber, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, bool isDarkMode) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppTheme.text),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _buildFeatureCard(
          icon: Icons.document_scanner,
          title: 'scan_document'.tr(),
          subtitle: 'scan_document_desc'.tr(),
          color: const Color(0xFF2E7D32),
          route: '/document_scanner',
        ),
        _buildFeatureCard(
          icon: Icons.mic,
          title: 'magic_dictation'.tr(),
          subtitle: 'magic_dictation_desc'.tr(),
          color: const Color(0xFF455A64),
          route: '/speech',
        ),
        _buildFeatureCard(
          icon: Icons.book,
          title: 'read_word'.tr(),
          subtitle: 'read_word_desc'.tr(),
          color: Colors.white,
          textColor: AppTheme.primaryColor,
          iconColor: AppTheme.primaryColor,
          route: '/lecture',
        ),
        _buildFeatureCard(
          icon: Icons.camera_alt,
          title: 'take_photo'.tr(),
          subtitle: 'take_photo_desc'.tr(),
          color: const Color(0xFFE65100),
          route: '/flashcard',
        ),
        _buildFeatureCard(
          icon: Icons.auto_awesome,
          title: 'smart_reply'.tr(),
          subtitle: 'smart_reply_desc'.tr(),
          color: const Color(0xFF00897B),
          route: '/smart_reply',
        ),
        _buildFeatureCard(
          icon: Icons.translate,
          title: 'translation'.tr(),
          subtitle: 'translation_desc'.tr(),
          color: const Color(0xFF6A1B9A),
          route: '/translation',
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color? textColor,
    Color? iconColor,
    required String route,
  }) {
    final buttonTextColor = textColor ?? Colors.white;
    final iconColorFinal = iconColor ?? Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateTo(context, route),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 30, color: iconColorFinal),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: buttonTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 10, color: buttonTextColor.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsList(bool isDarkMode) {
    return Container(
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
          _buildToolTile(
            icon: Icons.translate,
            title: 'identify_language'.tr(),
            subtitle: 'identify_language_desc'.tr(),
            color: Colors.purple,
            route: '/languages',
            isDarkMode: isDarkMode,
          ),
          const Divider(height: 1),
          _buildToolTile(
            icon: Icons.language,
            title: 'translation'.tr(),
            subtitle: 'translation_desc'.tr(),
            color: const Color(0xFF059669),
            route: '/translation',
            isDarkMode: isDarkMode,
          ),
          const Divider(height: 1),
          _buildToolTile(
            icon: Icons.face,
            title: 'face_detection'.tr(),
            subtitle: 'face_detection_desc'.tr(),
            color: Colors.pink,
            route: '/face_detection',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : AppTheme.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDarkMode ? Colors.grey.shade400 : AppTheme.textLight,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: color, size: 20),
      onTap: () => _navigateTo(context, route),
    );
  }

  Widget _buildTipCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.12),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'tip_text'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.4,
                color: isDarkMode ? Colors.grey.shade300 : AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}