// lib/screens/parent/child_dashboard_screen.dart

import 'package:edulearn_final/providers/child_provider.dart';
import 'package:edulearn_final/screens/child/child_profile_screen.dart';
import 'package:edulearn_final/screens/settings/settings_screen_enfant.dart';
import 'package:edulearn_final/screens/settings_screen.dart';
import 'package:edulearn_final/widgets/animations/animated_card.dart';
import 'package:edulearn_final/widgets/animations/fade_animation.dart';
import 'package:edulearn_final/widgets/animations/slide_animation.dart';
import 'package:edulearn_final/widgets/animations/scale_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_auth_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../auth/child_login_screen.dart';
import '../games/games_menu_screen.dart';
import '../activities/activities_menu_screen.dart';
import '../about/about_screen.dart';
import '../history/history_screen.dart';

class ChildDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  const ChildDashboardScreen({super.key, required this.child});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen>
    with TickerProviderStateMixin {
  final LocalAuthService _auth = LocalAuthService();
  final SoundService _soundService = SoundService();
  late Map<String, dynamic> _child;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Section visibility
  bool _showActivities = true;
  bool _showGames = true;
  bool _isDarkMode = false;
  String _greeting = '';
  String _greetingEmoji = '';

  // Avatars
  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '👶', 'icon': Icons.child_care, 'color': Colors.blue, 'gradient': [Colors.blue.shade400, Colors.blue.shade700], 'name': 'Bébé'},
    {'emoji': '🎓', 'icon': Icons.school, 'color': Colors.green, 'gradient': [Colors.green.shade400, Colors.green.shade700], 'name': 'Écolier'},
    {'emoji': '✨', 'icon': Icons.auto_awesome, 'color': Colors.purple, 'gradient': [Colors.purple.shade400, Colors.purple.shade700], 'name': 'Magique'},
    {'emoji': '🚀', 'icon': Icons.rocket, 'color': Colors.orange, 'gradient': [Colors.orange.shade400, Colors.orange.shade700], 'name': 'Astronaute'},
    {'emoji': '🌳', 'icon': Icons.forest, 'color': Colors.teal, 'gradient': [Colors.teal.shade400, Colors.teal.shade700], 'name': 'Nature'},
    {'emoji': '🎵', 'icon': Icons.music_note, 'color': Colors.pink, 'gradient': [Colors.pink.shade400, Colors.pink.shade700], 'name': 'Artiste'},
  ];

  // Menu items
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.person, 'title': 'Mon Profil', 'color': Colors.green, 'route': 'profile'}, // ← AJOUTER CETTE LIGNE
    {'icon': Icons.school, 'title': 'Apprendre', 'color': Colors.blue, 'route': 'activities'},
    {'icon': Icons.sports_esports, 'title': 'Jeux', 'color': Colors.purple, 'route': 'games'},
    {'icon': Icons.history, 'title': 'Historique', 'color': Colors.teal, 'route': 'history'},
    {'icon': Icons.settings, 'title': 'Paramètres', 'color': Colors.grey, 'route': 'settings'},
    {'icon': Icons.info_outline, 'title': 'À propos', 'color': Colors.orange, 'route': 'about'},
    {'icon': Icons.logout, 'title': 'Déconnexion', 'color': Colors.red, 'route': 'logout'},
  ];

  // Activités
  final List<Map<String, dynamic>> _activities = [
    //{'icon': Icons.book, 'title': 'Lecture', 'subtitle': 'Scanner des mots', 'color': Colors.blue, 'route': '/lecture'},
    {'icon': Icons.camera_alt, 'title': 'Objet', 'subtitle': 'Reconnaître', 'color': Colors.orange, 'route': '/flashcard'},
    {'icon': Icons.document_scanner, 'title': 'Scanner', 'subtitle': 'Documents', 'color': Colors.teal, 'route': '/document_scanner'},
    //{'icon': Icons.mic, 'title': 'Dictée', 'subtitle': 'Parler', 'color': Colors.purple, 'route': '/speech'},
    {'icon': Icons.mic, 'title': 'Dictée', 'subtitle': 'Parler', 'color': Colors.purple, 'route': '/lecture'},
    {'icon': Icons.translate, 'title': 'Traduction', 'subtitle': 'Multilingue', 'color': Colors.green, 'route': '/translation'},
    {'icon': Icons.analytics, 'title': 'Entités', 'subtitle': 'Extraction', 'color': const Color(0xFF6C63FF), 'route': '/entity_extraction'},
    {'icon': Icons.text_fields, 'title': 'Analyse', 'subtitle': 'de texte', 'color': const Color(0xFF4A90E2), 'route': '/text_analysis'},
    {'icon': Icons.analytics, 'title': 'Grammaire', 'subtitle': 'Analyse grammaticale', 'color': Color(0xFFFF9800), 'route': '/grammar_analysis'},
    {'icon': Icons.map, 'title': 'Monuments du Monde', 'subtitle': 'Découvrir les monuments', 'color': Color.fromARGB(255, 77, 146, 79), 'route': '/landmark'},
  ];

  // Jeux
  final List<Map<String, dynamic>> _games = [
    
    {'icon': Icons.emoji_emotions, 'title': 'Émotions', 'subtitle': 'Détection', 'color': const Color(0xFFFF6B6B), 'route': '/emotion_game'},
    {'icon': Icons.visibility, 'title': 'Show Object', 'subtitle': 'Reconnaître', 'color': const Color(0xFF4ECDC4), 'route': '/show_object_game'},
    {'icon': Icons.translate, 'title': 'Translation', 'subtitle': 'Flash', 'color': const Color(0xFF45B7D1), 'route': '/translation_flash'},
    {'icon': Icons.category, 'title': 'Catégories', 'subtitle': 'Classer', 'color': const Color(0xFF96CEB4), 'route': '/category_game'},
    {'icon': Icons.brush, 'title': 'Drawing', 'subtitle': 'Dessiner', 'color': const Color(0xFFFF9F4A), 'route': '/drawing_game'},
    {'icon': Icons.language, 'title': 'Langue', 'subtitle': 'Mystère', 'color': const Color(0xFF6C5CE7), 'route': '/language_mystery'},
    {'icon': Icons.fitness_center, 'title': 'Rhythm', 'subtitle': 'Mouvement', 'color': const Color(0xFF00B894), 'route': '/rhythm_game'},
    {'icon': Icons.apple, 'title': 'Fruits & Légumes', 'subtitle': 'Apprends les fruits', 'color': const Color(0xFF4CAF50), 'route': '/food_learning'},

{'icon': Icons.color_lens, 'title': 'Polyglot Colors', 'subtitle': 'Apprends les couleurs', 'color': const Color(0xFF9C27B0), 'route': '/color_learning'},

{'icon': Icons.camera_alt, 'title': 'Animal Explorer AI', 'subtitle': 'Découvrir les annimaux🤖', 'color': const Color.fromARGB(255, 71, 223, 223), 'route': '/animal_game_mlkit'},
    //{'icon': Icons.auto_awesome, 'title': 'Devine', 'subtitle': 'Objet mystère', 'color': const Color(0xFFE84393), 'route': '/guess_game'},
    //{'icon': Icons.auto_awesome, 'title': 'Devine', 'subtitle': 'Assistant IA', 'color': const Color(0xFFE84393), 'route': '/smart_reply'},
  ];

  @override
  void initState() {
    super.initState();
    _child = widget.child;
    _updateGreeting();
    _initAnimations();
    _initScrollController();
    _updateStreak();
    _loadData();
    _loadThemePreference();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _soundService.startBackgroundMusic();
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Bonjour';
      _greetingEmoji = '☀️';
    } else if (hour < 18) {
      _greeting = 'Bon après-midi';
      _greetingEmoji = '🌤️';
    } else {
      _greeting = 'Bonsoir';
      _greetingEmoji = '🌙';
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _slideController.forward();
  }

  void _initScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('child_dark_mode') ?? false;
    });
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('child_dark_mode', _isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference();
    _soundService.playClick();
    HapticFeedback.lightImpact();
  }

  Future<void> _loadData() async {
    final updatedChild = await _auth.getChildById(_child['id']);
    if (updatedChild != null && mounted) {
      setState(() {
        _child = updatedChild;
      });
    }
  }

  Future<void> _updateStreak() async {
    final lastActive = _child['lastActive'] != null
        ? DateTime.tryParse(_child['lastActive'])
        : null;

    if (lastActive != null) {
      final today = DateTime.now();
      final difference = today.difference(lastActive).inDays;

      if (difference == 1) {
        final newStreak = (_child['streak'] ?? 0) + 1;
        await _auth.updateChildStats(_child['id'], streak: newStreak);
        _child['streak'] = newStreak;
        if (mounted) setState(() {});
      } else if (difference > 1) {
        await _auth.updateChildStats(_child['id'], streak: 0);
        _child['streak'] = 0;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _logout() async {
    await _soundService.playClick();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );
    
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChildLoginScreen(parentId: '')),
          (route) => false,
        );
      }
    }
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'Se déconnecter',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      side: BorderSide(color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Déconnecter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String route) {
    _soundService.playClick();
    Navigator.pushNamed(context, route).then((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    final updatedChild = await _auth.getChildById(_child['id']);
    if (updatedChild != null && mounted) {
      setState(() {
        _child = updatedChild;
      });
    }
  }

  void _handleMenuTap(Map<String, dynamic> item) {
    Navigator.pop(context);
    switch (item['route']) {
      case 'profile': // ← AJOUTER CE CAS
      _navigateToProfile();
      break;
      case 'activities':
        _navigateToActivities();
        break;
      case 'games':
        _navigateToGames();
        break;
      case 'history':
        _navigateToHistory();
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'about':
        _navigateToAbout();
        break;
      case 'logout':
        _logout();
        break;
    }
  }
  // Dans child_dashboard_screen.dart, modifiez _navigateToProfile :

void _navigateToProfile() async {
  await _soundService.playClick();
  
  // Sauvegarder dans le provider si nécessaire
  final childProvider = Provider.of<ChildProvider>(context, listen: false);
  await childProvider.setCurrentChild(_child['id'], _child['name']);
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChildProfileScreen(
        childId: _child['id'],
        childName: _child['name'],
      ),
    ),
  ).then((_) => _refreshData());
}

  void _navigateToActivities() async {
    await _soundService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesMenuScreen(
          childId: _child['id'],
          childName: _child['name'],
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToGames() async {
    await _soundService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamesMenuScreen(childId: _child['id']),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToHistory() async {
    await _soundService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          childId: _child['id'],
          childName: _child['name'],
        ),
      ),
    );
  }

  void _navigateToSettings() async {
    await _soundService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreenEnfant(
          childId: _child['id'],
          childName: _child['name'],
        ),
      ),
    );
  }

  void _navigateToAbout() async {
    await _soundService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  Widget _getAvatarWidget({double size = 60}) {
    final avatarIndex = _child['avatarIndex'] ?? 0;
    final avatar = _avatars[avatarIndex.clamp(0, _avatars.length - 1)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: avatar['gradient'],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (avatar['color'] as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          avatar['emoji'],
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: _isDarkMode ? const Color(0xFF121212) : Colors.white,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _isDarkMode ? const Color(0xFF0A0A1E) : const Color(0xFFF5F7FA),
          drawer: _buildNavigationDrawer(),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(isTablet),
                  SliverPadding(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Header avec animation
                        SlideAnimation(
                          beginOffset: const Offset(0, 0.2),
                          child: _buildWelcomeHeader(),
                        ),
                        const SizedBox(height: 20),
                        
                        // Stats Card avec animation d'échelle
                        ScaleAnimation(
                          beginScale: 0.9,
                          child: _buildStatsCard(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Quick Filters avec animation
                        SlideAnimation(
                          beginOffset: const Offset(-0.2, 0),
                          child: _buildQuickFilters(),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_showActivities) ...[
                          SlideAnimation(
                            beginOffset: const Offset(0, 0.1),
                            delay: const Duration(milliseconds: 100),
                            child: _buildSectionHeader('📚 Activités d\'apprentissage', Icons.school, Colors.blue),
                          ),
                          const SizedBox(height: 16),
                          _buildActivitiesGridWithAnimation(isTablet),
                          const SizedBox(height: 32),
                        ],
                        
                        if (_showGames) ...[
                          SlideAnimation(
                            beginOffset: const Offset(0, 0.1),
                            delay: const Duration(milliseconds: 200),
                            child: _buildSectionHeader('🎮 Mes jeux', Icons.games, Colors.purple),
                          ),
                          const SizedBox(height: 16),
                          _buildGamesGridWithAnimation(isTablet),
                          const SizedBox(height: 32),
                        ],
                        
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Version animée de la grille d'activités
  Widget _buildActivitiesGridWithAnimation(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return ScaleAnimation(
          beginScale: 0.8,
          delay: Duration(milliseconds: 50 * index),
          child: _buildCard(activity),
        );
      },
    );
  }

  // Version animée de la grille de jeux
  Widget _buildGamesGridWithAnimation(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return ScaleAnimation(
          beginScale: 0.8,
          delay: Duration(milliseconds: 50 * index),
          child: _buildCard(game),
        );
      },
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  const Color(0xFF4A3AFF),
                ],
              ),
            ),
            child: Column(
              children: [
                ScaleAnimation(
                  beginScale: 0.5,
                  child: _getAvatarWidget(size: 70),
                ),
                const SizedBox(height: 12),
                FadeAnimation(
                  child: Text(
                    _child['name'] ?? 'Enfant',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Niveau ${_child['level'] ?? 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return SlideAnimation(
                  beginOffset: const Offset(-0.3, 0),
                  delay: Duration(milliseconds: 50 * index),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'], color: item['color'], size: 22),
                    ),
                    title: Text(
                      item['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    onTap: () => _handleMenuTap(item),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.amber : Colors.indigo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isDarkMode ? 'Mode Clair' : 'Mode Sombre',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) => _toggleTheme(),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 180,
      pinned: true,
      elevation: _scrollOffset > 50 ? 4 : 0,
      backgroundColor: _isDarkMode 
          ? const Color(0xFF1A1A2E).withOpacity(0.95) 
          : Colors.white.withOpacity(0.95),
      foregroundColor: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: Icon(Icons.menu, color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                const Color(0xFF4A3AFF),
                const Color(0xFF6C63FF),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleAnimation(
                    beginScale: 0.5,
                    child: _getAvatarWidget(size: isTablet ? 90 : 70),
                  ),
                  const SizedBox(height: 12),
                  FadeAnimation(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_avatars[_child['avatarIndex']?.clamp(0, _avatars.length - 1) ?? 0]['name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        title: const Text(''),
        centerTitle: true,
      ),
      actions: [
        ScaleAnimation(
          beginScale: 0.8,
          child: IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: _toggleTheme,
            tooltip: _isDarkMode ? 'Mode Clair' : 'Mode Sombre',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _greetingEmoji,
              style: TextStyle(fontSize: isTablet ? 32 : 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 12,
                    color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _child['name'] ?? 'Enfant',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (_isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, 
                  size: 14, 
                  color: Colors.orange,
                ),
                const SizedBox(width: 3),
                Text(
                  '${_child['streak'] ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final level = _child['level'] ?? 1;
    final points = _child['points'] ?? 0;
    final nextLevelPoints = level * 100;
    final progress = ((points % 100) / 100).clamp(0.0, 1.0);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.auto_awesome, 'Niveau', '$level', Colors.white, isTablet),
              _buildStatItem(Icons.star, 'Points', '$points', Colors.amber, isTablet),
              _buildStatItem(Icons.emoji_events, 'Restants', '${nextLevelPoints - (points % 100)}', Colors.white, isTablet),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression Niveau ${level + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Niveau $level', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text('${points % 100}/$nextLevelPoints XP', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text('Niveau ${level + 1}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: isTablet ? 24 : 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'Apprentissage',
              icon: Icons.school,
              isSelected: _showActivities,
              onTap: () => setState(() => _showActivities = !_showActivities),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterChip(
              label: 'Jeux',
              icon: Icons.games,
              isSelected: _showGames,
              onTap: () => setState(() => _showGames = !_showGames),
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : (_isDarkMode ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : (_isDarkMode ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? color 
                      : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (_isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              title.contains('Activités') ? '${_activities.length}' : '${_games.length}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      child: InkWell(
        onTap: () => _navigateTo(item['route']),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item['icon'], size: 32, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                item['title'],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'],
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}