// lib/screens/parent/parent_home_screen.dart
import 'dart:io';
import 'package:edulearn_final/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_auth_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'add_child_screen.dart';
import 'child_dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../games/games_menu_screen.dart';
//import '../history/history_screen.dart';


// Modèles de données
class ChildStatistic {
  final int gamesPlayed;
  final int gamesWon;
  final int averageScore;
  final String favoriteGame;
  
  ChildStatistic({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageScore = 0,
    this.favoriteGame = '',
  });
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthService _auth = LocalAuthService();
  final SoundService _soundService = SoundService();
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _loadThemePreference();

     // ✅ Appeler ici pour voir les logs au démarrage
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _logAllChildrenIds();
  });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundService().startBackgroundMusic();
    });
  }

  Future<void> _logAllKeys() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  
  print('\n========== TOUTES LES CLÉS ==========');
  for (var key in keys) {
    print('🔑 $key = ${prefs.get(key)}');
  }
  print('=====================================\n');
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
    _animationController.forward();
  }

  // Ajoutez ce code temporairement dans n'importe quel écran (ex: dans initState de HomeScreen)
Future<void> _printAllChildrenIds() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  
  print('=== TOUS LES ENFANTS ===');
  for (var key in keys) {
    if (key.startsWith('child_name_')) {
      final childId = key.replaceFirst('child_name_', '');
      final childName = prefs.getString(key);
      print('ID: $childId, Nom: $childName');
    }
  }
  print('========================');
}

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
    HapticFeedback.lightImpact();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _auth.forceRefreshUser();
      _currentUser = await _auth.getCurrentUser();
      
      if (_currentUser != null) {
        _children = await _auth.getChildren(_currentUser!['id']);
        _children.sort((a, b) => (b['lastActive'] ?? '').compareTo(a['lastActive'] ?? ''));
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToHistory() async {
    await _playClickSound();
    
    if (_currentUser == null) {
      _showSnackBar('Unable to load history. Please try again.', Colors.red);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          childId: _currentUser!['id'],
          childName: _currentUser!['name'],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _playClickSound();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );
    
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildDebugButton() {
  return ElevatedButton(
    onPressed: () async {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      String result = "=== ENFANTS ===\n";
      for (var key in keys) {
        if (key.startsWith('child_name_')) {
          final childId = key.replaceFirst('child_name_', '');
          final childName = prefs.getString(key);
          result += "Nom: $childName\nID: $childId\n---\n";
        }
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Liste des enfants'),
          content: SingleChildScrollView(
            child: Text(result),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    },
    child: const Text('Afficher tous les IDs enfants'),
  );
}

  Widget _buildLogoutDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChildSelectionDialog() async {
    await _playClickSound();
    
    if (_children.isEmpty) {
      _showSnackBar('No children registered. Please add a child first.', Colors.orange);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildChildSelectionSheet(),
    );
  }

  Widget _buildChildSelectionSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.child_care,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Child',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : AppTheme.text,
                        ),
                      ),
                      Text(
                        '${_children.length} child(ren) available',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  return _buildChildSelectionItem(child);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelectionItem(Map<String, dynamic> child) {
    return InkWell(
      onTap: () async {
        await _playClickSound();
        Navigator.pop(context);
        _selectChild(child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              AppTheme.primaryColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            _buildChildAvatar(child, 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMiniChip(Icons.cake, '${child['age']} ans', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMiniChip(Icons.star, '${child['points'] ?? 0} pts', Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  void _selectChild(Map<String, dynamic> child) async {
    await _auth.setCurrentChild(child['id']);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildDashboardScreen(child: child),
        ),
      ).then((_) => _loadData());
    }
  }

  void _navigateToGames() async {
    await _playClickSound();
    
    if (_children.isEmpty) {
      _showSnackBar('Please add a child first to access games.', Colors.orange);
      return;
    }
    
    final selectedChildId = _children.isNotEmpty ? _children.first['id'] : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamesMenuScreen(childId: selectedChildId),
      ),
    );
  }

  Future<void> _logAllChildrenIds() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  
  print('\n========== LISTE COMPLÈTE DES ENFANTS ==========');
  
  int count = 0;
  for (var key in keys) {
    if (key.startsWith('child_name_')) {
      count++;
      final childId = key.replaceFirst('child_name_', '');
      final childName = prefs.getString(key);
      final childAge = prefs.getString('child_age_$childId') ?? '?';
      final childPoints = prefs.getInt('points_$childId') ?? 0;
      
      print('👤 ENFANT N°$count');
      print('   📛 Nom: $childName');
      print('   🆔 ID: $childId');
      print('   📅 Âge: $childAge ans');
      print('   ⭐ Points: $childPoints');
      print('   ─────────────────────────');
    }
  }
  
  print('📊 Total: $count enfant(s) trouvé(s)');
  print('==========================================\n');
}

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildChildAvatar(Map<String, dynamic> child, double size) {
    final hasCustomImage = child['customImagePath'] != null && 
        child['customImagePath'].toString().isNotEmpty &&
        File(child['customImagePath']).existsSync();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: !hasCustomImage ? AppTheme.primaryGradient : null,
        image: hasCustomImage
            ? DecorationImage(
                image: FileImage(File(child['customImagePath'])),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasCustomImage
          ? null
          : Center(
              child: Text(
                child['name'][0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _isDarkMode ? const Color(0xFF121212) : Colors.white,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: _isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(),
          ),
          floatingActionButton: _buildFloatingButton(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildPremiumAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ✅ AJOUTER LE BOUTON DE DÉBOGAGE ICI
            _buildDebugButton(),
            const SizedBox(height: 16),
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildHeaderSection(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_children.isEmpty)
                _buildEmptyState()
              else
                _buildChildrenList(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _currentUser?['name'] ?? 'Parent',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icône du mode sombre/clair (remplace l'icône des jeux)
                  _buildActionButton(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode, 
                    _toggleTheme
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.child_care, _showChildSelectionDialog),
                  const SizedBox(width: 8),
                  _buildPopupMenu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        tooltip: '',
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      offset: const Offset(0, 50),
      color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      onSelected: (value) async {
        await _playClickSound();
        switch (value) {
          case 'settings':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            break;
          case 'games':
            _navigateToGames();
            break;
          case 'history':
            _navigateToHistory();
            break;
          case 'about':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            break;
          case 'logout':
            _logout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'games',
          child: Row(
            children: [
              Icon(Icons.sports_esports, size: 20, color: Colors.orange),
              SizedBox(width: 12),
              Text('Games'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.blue),
              SizedBox(width: 12),
              Text('History'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue),
              SizedBox(width: 12),
              Text('About'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Sign Out', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final totalPoints = _getTotalPoints();
    final totalChildren = _children.length;
    final activeChildren = _children.where((c) => c['isActive'] != false).length;
    
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
        children: [
          _buildStatItem('Total Points', totalPoints.toString(), Icons.star, Colors.amber),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStatItem('Children', totalChildren.toString(), Icons.family_restroom, Colors.white),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStatItem('Active', activeChildren.toString(), Icons.check_circle, const Color.fromARGB(255, 163, 215, 179)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Children',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        TextButton.icon(
          onPressed: _refresh,
          icon: Icon(Icons.refresh, size: 18, color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
          label: Text(
            '${_children.length} child(ren)',
            style: TextStyle(color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenList() {
    return Column(
      children: _children.asMap().entries.map((entry) {
        return _buildModernChildCard(entry.value);
      }).toList(),
    );
  }

  Widget _buildModernChildCard(Map<String, dynamic> child) {
    final hasCustomImage = child['customImagePath'] != null && 
        child['customImagePath'].toString().isNotEmpty &&
        File(child['customImagePath']).existsSync();
    final level = child['level'] ?? 1;
    final points = child['points'] ?? 0;
    final progressToNextLevel = (points % 100) / 100;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: () => _selectChild(child),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildChildAvatar(child, 65),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                child['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lvl $level',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(Icons.cake, '${child['age']} years', Colors.blue),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.star, '$points pts', Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress to Level ${level + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10, 
                                    color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500
                                  ),
                                ),
                                Text(
                                  '${(progressToNextLevel * 100).toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w600, 
                                    color: AppTheme.primaryColor
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressToNextLevel,
                                backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionChip(Icons.edit, 'Edit', Colors.blue, () => _editChild(child)),
                  _buildActionChip(Icons.delete, 'Delete', Colors.red, () => _deleteChild(child)),
                  _buildActionChip(Icons.arrow_forward, 'Dashboard', AppTheme.primaryColor, () => _selectChild(child)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11, 
              color: color, 
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12, 
                color: color, 
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.family_restroom, size: 50, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'No Children Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first child',
            style: GoogleFonts.poppins(
              fontSize: 14, 
              color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await _playClickSound();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddChildScreen()),
        );
        if (result == true && mounted) {
          await _loadData();
          _showSnackBar('Child added successfully!', Colors.green);
        }
      },
      backgroundColor: AppTheme.primaryColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Add Child',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      elevation: 4,
    );
  }

  int _getTotalPoints() {
    int total = 0;
    for (var child in _children) {
      final pointsValue = child['points'];
      if (pointsValue != null) {
        if (pointsValue is int) {
          total += pointsValue;
        } else if (pointsValue is String) {
          total += int.tryParse(pointsValue) ?? 0;
        } else if (pointsValue is double) {
          total += pointsValue.toInt();
        }
      }
    }
    return total;
  }

  Future<void> _refresh() async {
    await _playClickSound();
    await _loadData();
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    await _playClickSound();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Delete ${child['name']}',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E)),
        ),
        content: Text(
          'Are you sure? This action cannot be undone.',
          style: TextStyle(color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _auth.deleteChild(child['id']);
      if (success && mounted) {
        await _loadData();
        _showSnackBar('Child deleted successfully', const Color.fromARGB(255, 94, 170, 102));
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editChild(Map<String, dynamic> child) async {
    await _playClickSound();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddChildScreen(childToEdit: child),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }
}