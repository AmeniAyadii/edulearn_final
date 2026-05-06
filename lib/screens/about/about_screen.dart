// lib/screens/about/about_screen.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

// ✅ CORRECTION: Utiliser TickerProviderStateMixin au lieu de SingleTickerProviderStateMixin
class _AboutScreenState extends State<AboutScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  
  String _version = '1.0.0';
  String _buildNumber = '1';
  String _buildDate = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPackageInfo();
    _loadBuildDate();
  }

  void _initAnimations() {
    // ✅ Maintenant plusieurs contrôleurs sont autorisés
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement package info: $e');
    }
  }

  Future<void> _loadBuildDate() async {
    final now = DateTime.now();
    final months = {
      1: 'janvier', 2: 'février', 3: 'mars', 4: 'avril',
      5: 'mai', 6: 'juin', 7: 'juillet', 8: 'août',
      9: 'septembre', 10: 'octobre', 11: 'novembre', 12: 'décembre'
    };
    
    if (mounted) {
      setState(() {
        _buildDate = '${now.day} ${months[now.month]} ${now.year}';
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _shareApp() {
    Share.share(
      '📚 **Découvrez EduLearn** - L\'application éducative pour enfants !\n\n'
      '✨ **Fonctionnalités :**\n'
      '• Jeux interactifs éducatifs\n'
      '• Intelligence artificielle intégrée\n'
      '• Reconnaissance vocale\n'
      '• Scanner de documents\n'
      '• Plus de 10 000 leçons\n\n'
      '⭐ **Note :** 4.8/5 - Plus de 50k utilisateurs !\n\n'
      '📥 **Téléchargez maintenant :** https://edulearn.app',
      subject: 'EduLearn - L\'apprentissage intelligent pour enfants',
    );
  }

  void _rateApp() {
    final url = Platform.isAndroid 
        ? 'https://play.google.com/store/apps/details?id=com.edulearn.app'
        : 'https://apps.apple.com/app/id123456789';
    _launchURL(url);
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.privacy_tip, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Confidentialité',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'EduLearn ne collecte aucune donnée personnelle sans consentement. '
                'Toutes les données sont cryptées et stockées localement.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar moderne avec effet de verre
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    'À propos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Particules animées
                    ...List.generate(15, (index) => Positioned(
                      left: math.Random().nextDouble() * MediaQuery.of(context).size.width,
                      top: math.Random().nextDouble() * 140,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Opacity(
                          opacity: (_pulseAnimation.value * 0.3).clamp(0.0, 0.3),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    )),
                    // Logo flottant
                    Center(
                      child: AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) => Transform.rotate(
                          angle: _rotateAnimation.value * 0.3,
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(
                              Icons.school,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareApp,
                tooltip: 'Partager',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'rate') _rateApp();
                  if (value == 'privacy') _showPrivacyDialog();
                  if (value == 'terms') _launchURL('https://edulearn.app/terms');
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rate', child: Row(
                    children: [Icon(Icons.star, size: 18), SizedBox(width: 8), Text('Noter l\'application')],
                  )),
                  const PopupMenuItem(value: 'privacy', child: Row(
                    children: [Icon(Icons.privacy_tip, size: 18), SizedBox(width: 8), Text('Confidentialité')],
                  )),
                  const PopupMenuItem(value: 'terms', child: Row(
                    children: [Icon(Icons.description, size: 18), SizedBox(width: 8), Text('Conditions')],
                  )),
                ],
              ),
            ],
          ),
          
          // Contenu principal
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Logo section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity((0.3 * _pulseAnimation.value).clamp(0.0, 0.3)),
                              blurRadius: (30 * _pulseAnimation.value).clamp(0.0, 30.0),
                              spreadRadius: (5 * _pulseAnimation.value).clamp(0.0, 5.0),
                            ),
                          ],
                        ),
                        child: _buildLogoSection(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInfoCard(isDarkMode),
                ),
                const SizedBox(height: 24),
                
                // Features section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFeaturesSection(),
                ),
                const SizedBox(height: 24),
                
                // Stats section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStatsSection(),
                ),
                const SizedBox(height: 32),
                
                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildFooter(isDarkMode),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.school,
              size: 65,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ).createShader(bounds),
          child: Text(
            'EduLearn',
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            'v$_version ($_buildNumber) • $_buildDate',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '✨ Application éducative intelligente ✨',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode ? Colors.grey.shade800 : Colors.white,
            isDarkMode ? Colors.grey.shade900 : AppTheme.primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Notre mission',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'EduLearn révolutionne l\'apprentissage des enfants en combinant pédagogie traditionnelle '
            'et intelligence artificielle. Notre objectif est de rendre l\'éducation accessible, '
            'ludique et personnalisée pour chaque enfant de 3 à 12 ans.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.verified_user,
                  'Sécurisé',
                  'Données protégées',
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.auto_awesome,
                  'IA intégrée',
                  'Apprentissage adaptatif',
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  Icons.offline_bolt,
                  'Hors ligne',
                  'Accès sans internet',
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'icon': Icons.book, 'title': 'Lecture', 'subtitle': 'Interactive', 'color': Colors.blue},
      {'icon': Icons.camera_alt, 'title': 'Scanner', 'subtitle': 'Document', 'color': Colors.green},
      {'icon': Icons.mic, 'title': 'Dictée', 'subtitle': 'Vocale', 'color': Colors.purple},
      {'icon': Icons.quiz, 'title': 'Quiz', 'subtitle': 'Éducatifs', 'color': Colors.orange},
      {'icon': Icons.translate, 'title': 'Traduction', 'subtitle': 'Multilingue', 'color': Colors.teal},
      {'icon': Icons.auto_awesome, 'title': 'IA Smart', 'subtitle': 'Réponses', 'color': Colors.pink},
      {'icon': Icons.gamepad, 'title': 'Jeux', 'subtitle': 'Ludiques', 'color': Colors.red},
      {'icon': Icons.analytics, 'title': 'Suivi', 'subtitle': 'Progrès', 'color': Colors.indigo},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Fonctionnalités phares',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features.map((feature) => 
            _buildFeatureCard(
              feature['icon'] as IconData, 
              feature['title'] as String, 
              feature['subtitle'] as String,
              feature['color'] as Color,
            )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {'value': '50k+', 'label': 'Utilisateurs', 'icon': Icons.people, 'color': Colors.blue},
      {'value': '10k+', 'label': 'Leçons', 'icon': Icons.book, 'color': Colors.green},
      {'value': '4.8', 'label': 'Note moyenne', 'icon': Icons.star, 'color': Colors.amber},
      {'value': '98%', 'label': 'Satisfaction', 'icon': Icons.thumb_up, 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => 
          _buildStatItem(
            stat['value'] as String, 
            stat['label'] as String, 
            stat['icon'] as IconData,
            stat['color'] as Color,
          )
        ).toList(),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Column(
      children: [
        Divider(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          thickness: 1,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(Icons.web, 'https://edulearn.app', 'Site web'),
            _buildSocialButton(Icons.facebook, 'https://facebook.com/edulearn', 'Facebook'),
            _buildSocialButton(Icons.link, 'https://linkedin.com/company/edulearn', 'LinkedIn'),
            _buildSocialButton(Icons.email, 'mailto:contact@edulearn.app', 'Email'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '© 2026 EduLearn. Tous droits réservés.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchURL('mailto:contact@edulearn.app'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'contact@edulearn.app',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String url, String tooltip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(url),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }
}