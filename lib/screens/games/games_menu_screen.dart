// lib/screens/games/games_menu_screen.dart

import 'package:edulearn_final/providers/guess_game_provider.dart';
import 'package:edulearn_final/screens/games/animal_writing_game.dart';
import 'package:edulearn_final/screens/games/animal_writing_game_mlkit.dart';
import 'package:edulearn_final/screens/games/game_zoo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import 'emotion_game_screen.dart';
import 'show_object_game_screen.dart';
import 'translation_flash_game.dart';
import 'category_game_screen.dart';
import 'spy_game_screen.dart';
import 'drawing_game_screen.dart';
import 'language_mystery_game.dart';
import 'rhythm_game_screen.dart';
import 'food_learning_game.dart';
import 'color_learning_game.dart';

// Import du Guess Game
import 'package:edulearn_final/screens/guess_screen.dart';

class GamesMenuScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  const GamesMenuScreen({super.key, this.childId, this.childName});

  @override
  State<GamesMenuScreen> createState() => _GamesMenuScreenState();
}

class _GamesMenuScreenState extends State<GamesMenuScreen>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  int _totalPoints = 0;
  int _gamesCompleted = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ✅ LISTE UNIQUE DES JEUX (sans doublons)
  final List<GameItem> _games = [
    // 🎭 Émotions
    GameItem(
      id: 'emotion',
      title: 'Devine l\'Émotion',
      subtitle: 'Reconnais et reproduis les émotions',
      icon: Icons.emoji_emotions,
      emoji: '😊',
      color: Colors.orange,
      gradientColors: [Color(0xFFFF9800), Color(0xFFF57C00)],
      route: '/emotion_game',
      difficulty: 1,
      category: '🎭 Émotions',
      points: 100,
    ),
    
    // 🔍 Observation & Détective
    GameItem(
      id: 'object',
      title: 'Montre-moi l\'objet',
      subtitle: 'Trouve et montre l\'objet demandé',
      icon: Icons.search,
      emoji: '🎯',
      color: Colors.green,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
      route: '/show_object_game',
      difficulty: 2,
      category: '🔍 Observation',
      points: 150,
    ),
    // GameItem(
    // id: 'spy',
    //  title: 'Cherche et Trouve',
    //  subtitle: 'Trouve les objets cachés',
    //  icon: Icons.visibility,
    //   emoji: '🔍',
    //   color: Colors.orange,
      //gradientColors: [Color(0xFFFF9800), Color(0xFFE65100)],
      //route: '/spy_game',
      //difficulty: 2,
      //category: '🔍 Observation',
      //points: 140,
    //),
    //GameItem(
      //id: 'guess_object',
      //title: 'Devine ce que je vois',
      //subtitle: 'Trouve l\'objet mystère avec des indices',
      //icon: Icons.quiz,
      //emoji: '🎭',
      //color: const Color(0xFF6C63FF),
      //gradientColors: [const Color(0xFF6C63FF), const Color(0xFF4A3AFF)],
      //route: '/guess_game',
      //difficulty: 2,
      //category: '🔍 Observation',
      //points: 150,
    //),
    
    // 🧠 Logique & Réflexion
    GameItem(
      id: 'category',
      title: 'Jeu des Catégories',
      subtitle: 'Classe les mots dans la bonne catégorie',
      icon: Icons.category,
      emoji: '📦',
      color: Colors.purple,
      gradientColors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      route: '/category_game',
      difficulty: 2,
      category: '🧠 Logique',
      points: 130,
    ),
    
    // 🎨 Créativité & Art
    GameItem(
      id: 'drawing',
      title: 'Dessine et Détecte',
      subtitle: 'Dessine et l\'IA reconnaît ton dessin',
      icon: Icons.brush,
      emoji: '🎨',
      color: Colors.pink,
      gradientColors: [Color(0xFFE91E63), Color(0xFFC2185B)],
      route: '/drawing_game',
      difficulty: 3,
      category: '🎨 Créativité',
      points: 160,
    ),
    
    // 🏃 Sport & Mouvement
    GameItem(
      id: 'rhythm',
      title: 'Le Bon Rythme',
      subtitle: 'Reproduis les mouvements',
      icon: Icons.fitness_center,
      emoji: '🕺',
      color: Colors.indigo,
      gradientColors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
      route: '/rhythm_game',
      difficulty: 3,
      category: '🏃 Sport',
      points: 180,
    ),
    
    // 🌐 Langues & Découverte (TOUS LES JEUX DE LANGUES ICI)
    // Translation Flash
    GameItem(
      id: 'translation',
      title: 'Traduction Flash',
      subtitle: 'Traduis les mots rapidement',
      icon: Icons.translate,
      emoji: '🌍',
      color: Colors.blue,
      gradientColors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      route: '/translation_flash',
      difficulty: 2,
      category: '🌐 Langues & Découverte',
      points: 120,
    ),
    
    // Langue Mystère
    GameItem(
      id: 'language',
      title: 'Langue Mystère',
      subtitle: 'Devine la langue mystère',
      icon: Icons.language,
      emoji: '🌍',
      color: Colors.teal,
      gradientColors: [Color(0xFF009688), Color(0xFF00796B)],
      route: '/language_mystery',
      difficulty: 3,
      category: '🌐 Langues & Découverte',
      points: 170,
    ),
    
    // Fruits & Légumes
    GameItem(
      id: 'food_learning',
      title: 'Fruits & Légumes',
      subtitle: 'Apprends les fruits et légumes en plusieurs langues',
      icon: Icons.apple,
      emoji: '🍎',
      color: const Color(0xFF4CAF50),
      gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
      route: '/food_learning',
      difficulty: 1,
      category: '🌐 Langues & Découverte',
      points: 150,
    ),
    
    // Polyglot Colors
    GameItem(
      id: 'color_learning',
      title: 'Polyglot Colors',
      subtitle: 'Apprends les couleurs en plusieurs langues',
      icon: Icons.color_lens,
      emoji: '🎨',
      color: const Color(0xFF9C27B0),
      gradientColors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      route: '/color_learning',
      difficulty: 1,
      category: '🌐 Langues & Découverte',
      points: 150,
    ),
    
    // Animal Explorer AI (avec 4 services ML Kit)
    GameItem(
      id: 'polyglot_animal_mlkit',
      title: 'Animal Explorer AI',
      subtitle: 'Scanne des animaux, apprends 12 langues avec IA 🤖',
      icon: Icons.camera_alt,
      emoji: '🤖',
      color: Colors.cyanAccent,
      gradientColors: [Colors.cyanAccent, Colors.cyan],
      route: '/animal_game_mlkit',
      difficulty: 2,
      category: '🌐 Langues & Découverte',
      points: 250,
    ),
  ];

  // Catégories disponibles
  final List<String> _categories = [
    'Tous',
    '🎭 Émotions',
    '🔍 Observation',
    '🧠 Logique',
    '🎨 Créativité',
    '🏃 Sport',
    '🌐 Langues & Découverte',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStats();
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
    _animationController.forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  // Après avoir terminé un jeu, sauvegardez les points
Future<void> _saveGameStats(int pointsEarned) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Récupérer les valeurs actuelles
  int currentGames = prefs.getInt('total_games_${widget.childId}') ?? 0;
  int currentPoints = prefs.getInt('points_${widget.childId}') ?? 0;
  
  // Mettre à jour
  await prefs.setInt('total_games_${widget.childId}', currentGames + 1);
  await prefs.setInt('points_${widget.childId}', currentPoints + pointsEarned);
  
  print('✅ Statistiques sauvegardées: +1 jeu, +$pointsEarned points');
}



  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalPoints = prefs.getInt('total_game_points') ?? 0;
      _gamesCompleted = prefs.getInt('games_completed') ?? 0;
    });
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
  }

  List<GameItem> get _filteredGames {
    return _games.where((game) {
      final matchesCategory = _selectedCategory == 'Tous' || 
          game.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          game.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Map<String, List<GameItem>> get _groupedGames {
    final Map<String, List<GameItem>> groups = {};
    for (var game in _filteredGames) {
      if (!groups.containsKey(game.category)) {
        groups[game.category] = [];
      }
      groups[game.category]!.add(game);
    }
    return groups;
  }

  void _navigateToGame(GameItem game) async {
    await _playClickSound();
    
    // ⭐ GESTION SPÉCIALE POUR LE JEU GUESS GAME
    if (game.id == 'guess_object') {
      // Vérifier que le provider existe dans le contexte
      final guessProvider = Provider.of<GuessGameProvider>(context, listen: false);
      
      // Vérifier que childId est valide
      if (widget.childId == null || widget.childId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Veuillez sélectionner un enfant avant de jouer.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Afficher un dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
      );
      
      try {
        // Créer une nouvelle session
        final sessionId = await guessProvider.createNewSession(
          childId: widget.childId,
        );
        
        // Fermer le dialog de chargement
        if (mounted) Navigator.pop(context);
        
        // Si la session a été créée avec succès, naviguer vers l'écran de jeu
        if (sessionId.isNotEmpty) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: guessProvider,
                  child: GuessScreen(
                    sessionId: sessionId,
                    childId: widget.childId!,
                  ),
                ),
              ),
            );
          }
        } else {
          // Erreur : session non créée
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Impossible de créer la partie. Réessaie plus tard.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // Gestion des erreurs
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }
    
    // ⭐ GESTION SPÉCIALE POUR LE JEU POLYGLOT ANIMAL EXPLORER (caméra)
    if (game.id == 'polyglot_animal') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameZooScreen(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ),
      );
      return;
    }
    
    // ⭐ GESTION SPÉCIALE POUR LE JEU ANIMAL WRITING GAME
    if (game.id == 'animal_writing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWritingGame(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ),
      );
      return;
    }
    
    // ⭐ GESTION SPÉCIALE POUR LE JEU ANIMAL WRITING GAME ML KIT
    if (game.id == 'polyglot_animal_mlkit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWritingGameMLKit(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ),
      );
      return;
    }
    
    // Pour les autres jeux
    final result = await Navigator.pushNamed(
      context,
      game.route,
      arguments: widget.childId,
    );
    
    if (result == true) {
      await _loadStats();
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rechercher un jeu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Nom du jeu...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '🎮 Jeux Éducatifs',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Header statistiques
              SliverToBoxAdapter(
                child: Container(
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
                      _buildStatCard(
                        emoji: '🏆',
                        value: '$_gamesCompleted',
                        label: 'Jeux terminés',
                        icon: Icons.emoji_events,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatCard(
                        emoji: '⭐',
                        value: '$_totalPoints',
                        label: 'Points gagnés',
                        icon: Icons.stars,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatCard(
                        emoji: '🎮',
                        value: '${_games.length}',
                        label: 'Jeux disponibles',
                        icon: Icons.sports_esports,
                      ),
                    ],
                  ),
                ),
              ),

              // Barre de recherche
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildSearchBar(isDarkMode),
                ),
              ),

              // Filtres par catégorie (défilement horizontal)
              SliverToBoxAdapter(
                child: _buildCategoryFilters(isDarkMode),
              ),

              // Catégories et jeux
              if (_searchQuery.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSearchResults(isDarkMode, isTablet),
                    ]),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ..._groupedGames.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryHeader(entry.key, isDarkMode),
                            const SizedBox(height: 12),
                            isTablet
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.6,
                                    ),
                                    itemCount: entry.value.length,
                                    itemBuilder: (context, index) => 
                                        _buildGameCard(entry.value[index], isDarkMode),
                                  )
                                : Column(
                                    children: entry.value.map((game) => 
                                        _buildGameCard(game, isDarkMode)).toList(),
                                  ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
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

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un jeu...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Icon(Icons.clear, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDarkMode) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
                HapticFeedback.lightImpact();
              },
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(
                color: isSelected 
                    ? const Color(0xFF6C63FF)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected 
                      ? const Color(0xFF6C63FF)
                      : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String category, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.split(' ')[0],
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          Text(
            '${_groupedGames[category]?.length ?? 0} jeux',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDarkMode, bool isTablet) {
    final results = _filteredGames;
    
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucun jeu trouvé',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essaie une autre recherche',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Résultats de recherche (${results.length})',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 8),
        isTablet
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) => _buildGameCard(results[index], isDarkMode),
              )
            : Column(
                children: results.map((game) => _buildGameCard(game, isDarkMode)).toList(),
              ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required List<GameItem> games,
    required bool isDarkMode,
    required bool isTablet,
  }) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        isTablet
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) => _buildGameCard(games[index], isDarkMode),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                itemBuilder: (context, index) => _buildGameCard(games[index], isDarkMode),
              ),
      ],
    );
  }

  Widget _buildGameCard(GameItem game, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToGame(game),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: game.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: game.color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      game.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDifficultyChip(game.difficulty),
                          const SizedBox(width: 8),
                          _buildPointsChip(game.points),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: game.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: game.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(int difficulty) {
    String text;
    Color color;
    
    switch (difficulty) {
      case 1:
        text = '⭐ Facile';
        color = Colors.green;
        break;
      case 2:
        text = '⭐⭐ Moyen';
        color = Colors.orange;
        break;
      case 3:
        text = '⭐⭐⭐ Difficile';
        color = Colors.red;
        break;
      default:
        text = '⭐ Facile';
        color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsChip(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '+$points pts',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

class GameItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final Color color;
  final List<Color> gradientColors;
  final String route;
  final int difficulty;
  final String category;
  final int points;

  GameItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.color,
    required this.gradientColors,
    required this.route,
    required this.difficulty,
    required this.category,
    required this.points,
  });
}