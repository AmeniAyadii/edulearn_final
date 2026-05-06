// lib/screens/activities/activities_menu_screen.dart

import 'package:edulearn_final/screens/lecture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';

class ActivityItem {
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
  final String ageRange;

  ActivityItem({
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
    this.ageRange = '3+',
  });
}

class ActivitiesMenuScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  const ActivitiesMenuScreen({super.key, this.childId, this.childName});

  @override
  State<ActivitiesMenuScreen> createState() => _ActivitiesMenuScreenState();
}

class _ActivitiesMenuScreenState extends State<ActivitiesMenuScreen>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  int _totalPoints = 0;
  int _activitiesCompleted = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ✅ NOUVELLE LISTE DES ACTIVITÉS (basée sur votre demande)
  final List<ActivityItem> _activities = [
    //ActivityItem(
      //id: 'lecture',
      //title: 'Lecture',
      //subtitle: 'Scanner des mots et apprends à lire',
      //icon: Icons.book,
      //emoji: '📖',
      //color: Colors.blue,
      //gradientColors: [Colors.blue.shade400, Colors.blue.shade800],
      //route: '/lecture',
      //difficulty: 2,
      //category: '📖 Lecture',
      //points: 120,
      //ageRange: '5-12',
    //),
    ActivityItem(
    id: 'landmarks',
    title: 'Monuments du Monde',
    subtitle: 'Voyage à travers les monuments célèbres',
    icon: Icons.map,
    emoji: '🗺️',
    color: const Color.fromARGB(255, 33, 243, 40),
    gradientColors: [Colors.green.shade400, Colors.green.shade800],
    
    route: '/landmark',  // ← C'est la route
    difficulty: 2,
    category: '🔍 Observation',
    points: 120,
    ageRange: '5-12',
),
    ActivityItem(
      id: 'flashcard',
      title: 'Objet',
      subtitle: 'Reconnaître les objets avec l\'IA',
      icon: Icons.camera_alt,
      emoji: '🎯',
      color: Colors.orange,
      gradientColors: [Colors.orange.shade400, Colors.orange.shade800],
      route: '/flashcard',
      difficulty: 2,
      category: '🔍 Observation',
      points: 130,
      ageRange: '4-10',
    ),
    ActivityItem(
      id: 'scanner',
      title: 'Scanner',
      subtitle: 'Scanne des documents intelligemment',
      icon: Icons.document_scanner,
      emoji: '📄',
      color: Colors.teal,
      gradientColors: [Colors.teal.shade400, Colors.teal.shade800],
      route: '/document_scanner',
      difficulty: 2,
      category: '📖 Lecture',
      points: 130,
      ageRange: '6-14',
    ),
    ActivityItem(
      id: 'dictee',
      title: 'Dictée',
      subtitle: 'Parle et améliore ton orthographe',
      icon: Icons.mic,
      emoji: '🎙️',
      color: Colors.purple,
      gradientColors: [Colors.purple.shade400, Colors.purple.shade800],
      route: '/lecture',  // Route vers lecture (comme demandé)
      difficulty: 2,
      category: '📖 Lecture',
      points: 130,
      ageRange: '6-14',
    ),
    ActivityItem(
      id: 'translation',
      title: 'Traduction',
      subtitle: 'Apprends en plusieurs langues',
      icon: Icons.translate,
      emoji: '🌐',
      color: Colors.green,
      gradientColors: [Colors.green.shade400, Colors.green.shade800],
      route: '/translation',
      difficulty: 2,
      category: '🌍 Langues',
      points: 120,
      ageRange: '6-14',
    ),
    ActivityItem(
      id: 'entities',
      title: 'Entités',
      subtitle: 'Extraction d\'entités dans les textes',
      icon: Icons.analytics,
      emoji: '🔍',
      color: const Color(0xFF6C63FF),
      gradientColors: [const Color(0xFF6C63FF), const Color(0xFF4A3AFF)],
      route: '/entity_extraction',
      difficulty: 3,
      category: '🧠 Logique',
      points: 160,
      ageRange: '8-15',
    ),
    ActivityItem(
      id: 'text_analysis',
      title: 'Analyse',
      subtitle: 'Analyse de texte intelligente',
      icon: Icons.text_fields,
      emoji: '📝',
      color: const Color(0xFF4A90E2),
      gradientColors: [const Color(0xFF4A90E2), const Color(0xFF2C5F8A)],
      route: '/text_analysis',
      difficulty: 3,
      category: '🧠 Logique',
      points: 150,
      ageRange: '8-15',
    ),
    ActivityItem(
      id: 'grammar',
      title: 'Grammaire',
      subtitle: 'Analyse grammaticale interactive',
      icon: Icons.analytics,
      emoji: '📝',
      color: const Color(0xFFFF9800),
      gradientColors: [const Color(0xFFFF9800), const Color(0xFFE65100)],
      route: '/grammar_analysis',
      difficulty: 3,
      category: '🧠 Logique',
      points: 150,
      ageRange: '8-15',
    ),
  ];

  // Catégories disponibles (mises à jour)
  final List<String> _categories = [
    'Tous',
    '📖 Lecture',
    '🔍 Observation',
    '🌍 Langues',
    '🧠 Logique',
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

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalPoints = prefs.getInt('total_activity_points') ?? 0;
      _activitiesCompleted = prefs.getInt('activities_completed') ?? 0;
    });
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
  }

  List<ActivityItem> get _filteredActivities {
    return _activities.where((activity) {
      final matchesCategory = _selectedCategory == 'Tous' || 
          activity.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Map<String, List<ActivityItem>> get _groupedActivities {
    final Map<String, List<ActivityItem>> groups = {};
    for (var activity in _filteredActivities) {
      if (!groups.containsKey(activity.category)) {
        groups[activity.category] = [];
      }
      groups[activity.category]!.add(activity);
    }
    return groups;
  }

 void _navigateToActivity(ActivityItem activity) async {
  await _playClickSound();
  
  print('🎯 Navigation vers: ${activity.id}');
  print('📝 childId disponible: ${widget.childId}');
  
  // Récupérer childId
  String? effectiveChildId = widget.childId;
  String? effectiveChildName = widget.childName;
  
  if (effectiveChildId == null || effectiveChildId.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    effectiveChildId = prefs.getString('current_child_id');
    effectiveChildName = prefs.getString('current_child_name');
  }
  
  if (effectiveChildId == null || effectiveChildId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Veuillez sélectionner un enfant.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Cas spécial pour LectureScreen
  if (activity.id == 'lecture' || activity.id == 'speech' || activity.id == 'dictee') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectureScreen(
          childId: effectiveChildId,
          childName: effectiveChildName,
        ),
      ),
    );
    return;
  }
  
  // Pour TOUTES les autres activités - PASSER UN STRING, PAS UN MAP
  // ⚠️ IMPORTANT: La plupart des routes attendent un String (childId), pas un Map
  try {
    final result = await Navigator.pushNamed(
      context,
      activity.route,
      arguments: effectiveChildId,  // ← Passer directement le String, pas un Map!
    );
    
    if (result == true) {
      await _loadStats();
    }
  } catch (e) {
    print('❌ Erreur navigation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${activity.title} n\'est pas encore disponible'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '📚 Apprentissage',
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
                        value: '$_activitiesCompleted',
                        label: 'Activités terminées',
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
                        emoji: '🎯',
                        value: '${_activities.length}',
                        label: 'Activités disponibles',
                        icon: Icons.school,
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

              // Catégories et activités
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
                      ..._groupedActivities.entries.map((entry) {
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
                                        _buildActivityCard(entry.value[index], isDarkMode),
                                  )
                                : Column(
                                    children: entry.value.map((activity) => 
                                        _buildActivityCard(activity, isDarkMode)).toList(),
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
                hintText: 'Rechercher une activité...',
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
            '${_groupedActivities[category]?.length ?? 0} activités',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity, bool isDarkMode) {
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
          onTap: () => _navigateToActivity(activity),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône/Emoji
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: activity.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: activity.color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      activity.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildDifficultyChip(activity.difficulty),
                          _buildPointsChip(activity.points),
                          _buildAgeChip(activity.ageRange),
                        ],
                      ),
                    ],
                  ),
                ),
                // Flèche
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: activity.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dans activities_menu_screen.dart
Future<void> _saveActivityStats(int pointsEarned) async {
  final prefs = await SharedPreferences.getInstance();
  
  int currentActivities = prefs.getInt('total_activities_${widget.childId}') ?? 0;
  int currentPoints = prefs.getInt('points_${widget.childId}') ?? 0;
  
  await prefs.setInt('total_activities_${widget.childId}', currentActivities + 1);
  await prefs.setInt('points_${widget.childId}', currentPoints + pointsEarned);
  
  print('✅ Statistiques activité sauvegardées: +1 activité, +$pointsEarned points');
}

  Widget _buildSearchResults(bool isDarkMode, bool isTablet) {
    final results = _filteredActivities;
    
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucune activité trouvée',
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
                itemBuilder: (context, index) => _buildActivityCard(results[index], isDarkMode),
              )
            : Column(
                children: results.map((activity) => _buildActivityCard(activity, isDarkMode)).toList(),
              ),
      ],
    );
  }

  Widget _buildDifficultyChip(int difficulty) {
    String text;
    Color color;
    
    switch (difficulty) {
      case 1:
        text = '⭐ Débutant';
        color = Colors.green;
        break;
      case 2:
        text = '⭐⭐ Intermédiaire';
        color = Colors.orange;
        break;
      case 3:
        text = '⭐⭐⭐ Avancé';
        color = Colors.red;
        break;
      default:
        text = '⭐ Débutant';
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

  Widget _buildAgeChip(String ageRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.child_care, size: 10, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$ageRange ans',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rechercher', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Nom de l\'activité...',
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
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}