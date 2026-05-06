// lib/games/guess_game/screens/guess_home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/guess_game_provider.dart';
import '../models/game_session.dart';
import '../widgets/difficulty_selector.dart';
import 'create_clue_screen.dart';
import 'multiplayer_lobby_screen.dart';
import 'solo_game_screen.dart';
import 'guess_screen.dart';

class GuessGameHomeScreen extends StatefulWidget {
  final String childId;
  final String childName;
  
  const GuessGameHomeScreen({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);
  
  @override
  State<GuessGameHomeScreen> createState() => _GuessGameHomeScreenState();
}

class _GuessGameHomeScreenState extends State<GuessGameHomeScreen> with SingleTickerProviderStateMixin {
  bool _isCreatingGame = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Statistiques joueur
  int _totalGamesPlayed = 0;
  int _totalWins = 0;
  int _totalPoints = 0;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPlayerStats();
  }
  
  void _initAnimations() {
    // ⭐ INITIALISER L'ANIMATION CONTROLLER D'ABORD
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // ⭐ PUIS INITIALISER LES ANIMATIONS
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // ⭐ DÉMARRER L'ANIMATION
    _animationController.forward();
  }
  
  Future<void> _loadPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _totalGamesPlayed = prefs.getInt('total_games_played_${widget.childId}') ?? 0;
        _totalWins = prefs.getInt('total_wins_${widget.childId}') ?? 0;
        _totalPoints = prefs.getInt('total_points_${widget.childId}') ?? 0;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Contenu principal
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStatsHeader(isDarkMode),
                  ),
                  
                  SliverPadding(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildWelcomeSection(isDarkMode),
                        const SizedBox(height: 24),
                        _buildGameModesSection(isDarkMode),
                        const SizedBox(height: 24),
                        _buildTipsSection(isDarkMode),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isCreatingGame) _buildLoadingOverlay(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz, size: 20, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 12),
          const Text(
            'Devine ce que je vois',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: const Color(0xFF6C63FF),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people, size: 20),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiplayerLobbyScreen(childId: widget.childId),
              ),
            );
          },
          tooltip: 'Parties disponibles',
        ),
      ],
    );
  }
  
  Widget _buildStatsHeader(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A3AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🎮', 'Parties', _totalGamesPlayed.toString()),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('🏆', 'Victoires', _totalWins.toString()),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('⭐', 'Points', _totalPoints.toString()),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
  
  Widget _buildWelcomeSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎭', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text(
            'Bonjour ${widget.childName} !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prêt à relever un nouveau défi ?',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameModesSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.games, size: 20, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 12),
              Text(
                '🎮 Choisis ton mode de jeu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        
        
        // Mode Solo
        _buildGameModeCard(
          title: 'Mode Solo',
          subtitle: 'Joue contre l\'IA',
          description: 'L\'ordinateur choisit un objet mystère à deviner',
          color: Colors.blue,
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
          icon: Icons.smart_toy,
          emoji: '🎮',
          onTap: _showDifficultySelector,
        ),
        
        const SizedBox(height: 16),
        
        // Mode Multijoueur - Créer
        _buildGameModeCard(
          title: 'Mode Multijoueur',
          subtitle: 'Crée une partie',
          description: 'Prends une photo et laisse un ami deviner',
          color: Colors.orange,
          gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
          icon: Icons.camera_alt,
          emoji: '👥',
          onTap: _showImageSourceDialog,
        ),
        
        const SizedBox(height: 16),
        
        // Mode Multijoueur - Rejoindre
        _buildGameModeCard(
          title: 'Rejoindre une partie',
          subtitle: 'Entre un code',
          description: 'Rejoins une partie existante avec un code',
          color: Colors.green,
          gradientColors: [Colors.green.shade400, Colors.green.shade700],
          icon: Icons.qr_code_scanner,
          emoji: '🔍',
          onTap: _showJoinGameDialog,
        ),
      ],
    );
  }
  
  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required List<Color> gradientColors,
    required IconData icon,
    required String emoji,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
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
                child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipsSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDarkMode ? Colors.amber.shade900 : Colors.amber.shade50).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Astuce du jour',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Utilise les indices intelligemment pour gagner plus de points !',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Analyse de l\'objet...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDifficultySelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DifficultySelector(
          onDifficultySelected: (Difficulty difficulty) {
            Navigator.pop(dialogContext);
            _startSoloGame(difficulty);
          },
        );
      },
    );
  }
  
  Future<void> _startSoloGame(Difficulty difficulty) async {
    setState(() => _isCreatingGame = true);
    
    try {
      final provider = Provider.of<GuessGameProvider>(context, listen: false);
      await provider.createSoloGame(widget.childId, difficulty);
      
      if (!mounted) return;
      setState(() => _isCreatingGame = false);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SoloGameScreen(
            session: provider.currentSession!,
            childId: widget.childId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isCreatingGame = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choisir une image',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Appareil photo',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Galerie',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 35, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() => _isCreatingGame = true);
      
      try {
        final provider = Provider.of<GuessGameProvider>(context, listen: false);
        await provider.createGameSessionFromImage(
          File(pickedFile.path),
          widget.childId,
          widget.childName,
          mode: GameMode.multiplayer,
          difficulty: Difficulty.medium,
        );
        
        if (!mounted) return;
        setState(() => _isCreatingGame = false);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateClueScreen(
              session: provider.currentSession!,
              childId: widget.childId,
            ),
          ),
        );
      } catch (e) {
        setState(() => _isCreatingGame = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _showJoinGameDialog() {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Color(0xFF6C63FF)),
              const SizedBox(width: 10),
              const Text('Rejoindre une partie'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entre le code de la partie :'),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: 'Ex: ABC123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.code, color: Color(0xFF6C63FF)),
                ),
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isEmpty) return;
                
                Navigator.pop(dialogContext);
                
                try {
                  final provider = Provider.of<GuessGameProvider>(context, listen: false);
                  await provider.joinGameByCode(code, widget.childId);
                  
                  if (!mounted) return;
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuessScreen(
                        sessionId: provider.currentSession!.sessionId,
                        childId: widget.childId,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rejoindre'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}