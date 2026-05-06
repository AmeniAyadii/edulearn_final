// lib/screens/games/game_zoo_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game/animal_card_widget.dart';
import '../games/animal_writing_game.dart';
import '../games/category_game_screen.dart';
import '../../theme/app_theme.dart';

class GameZooScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const GameZooScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<GameZooScreen> createState() => _GameZooScreenState();
}

class _GameZooScreenState extends State<GameZooScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadGameData();
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
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }
  
  void _loadGameData() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.loadDiscoveredAnimals();
  }
  
  Future<void> _startAnimalDiscovery() async {
    // ✅ Navigation correcte vers le jeu d'écriture d'animaux
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalWritingGame(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
    
    // Rafraîchir les données après le retour
    if (result == true) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.loadDiscoveredAnimals();
      setState(() {});
    }
  }
  
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLanguageSelectorSheet(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header avec stats
                  _buildHeader(gameProvider, isDarkMode),
                  const SizedBox(height: 16),
                  // Contenu principal
                  Expanded(
                    child: gameProvider.discoveredAnimals.isEmpty
                        ? _buildEmptyState(isDarkMode)
                        : _buildAnimalGrid(gameProvider, isTablet, isDarkMode),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(GameProvider gameProvider, bool isDarkMode) {
    final totalAnimals = 24;
    final progress = (gameProvider.discoveredCount / totalAnimals).clamp(0.0, 1.0);
    final nextBadgeAt = ((gameProvider.discoveredCount ~/ 5) + 1) * 5;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              _buildStatCard(
                icon: Icons.pets,
                label: 'Animaux',
                value: '${gameProvider.discoveredCount}/$totalAnimals',
                color: const Color(0xFF6C63FF),
              ),
              _buildStatCard(
                icon: Icons.language,
                label: 'Langues',
                value: '12',
                color: const Color(0xFF4CAF50),
              ),
              _buildStatCard(
                icon: Icons.emoji_events,
                label: 'Badges',
                value: '${gameProvider.discoveredCount ~/ 5}',
                color: const Color(0xFFFFB74D),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barre de progression
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              if (nextBadgeAt <= totalAnimals && gameProvider.discoveredCount < totalAnimals)
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Encore ${nextBadgeAt - gameProvider.discoveredCount} animaux pour le prochain badge !',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation container
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.orange.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🐘',
                    style: TextStyle(fontSize: 70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bienvenue au Zoo Polyglotte !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Découvre des animaux du monde entier\net apprends leurs noms en plusieurs langues !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Scanner',
                    color: const Color(0xFF6C63FF),
                    onPressed: _startAnimalDiscovery,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.quiz,
                    label: 'Quiz',
                    color: const Color(0xFFFF6B35),
                    onPressed: () {
                      // ✅ Version corrigée :
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AnimalWritingGame(
      childId: widget.childId,
      // childName n'existe pas dans AnimalWritingGame
    ),
  ),
);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
    );
  }
  
  Widget _buildAnimalGrid(GameProvider gameProvider, bool isTablet, bool isDarkMode) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: gameProvider.discoveredAnimals.length,
        itemBuilder: (context, index) {
          final animal = gameProvider.discoveredAnimals[index];
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: isTablet ? 3 : 2,
            child: SlideAnimation(
              horizontalOffset: 50,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () => _showAnimalDetails(context, animal),
                  child: AnimalCardWidget(
                    animal: animal,
                    small: false,
                    onTap: () => _showAnimalDetails(context, animal),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showAnimalDetails(BuildContext context, dynamic animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _buildAnimalDetailSheet(animal),
    );
  }
  
  Widget _buildAnimalDetailSheet(dynamic animal) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    //final masteredLanguages = animal.translations.values.where((t) => t.isComplete).length;
    // ✅ Version plus robuste
final masteredLanguages = animal.translations.values
    .where((t) => t != null && t.isComplete == true)
    .length;
    final totalLanguages = 12;
    final progressPercent = (masteredLanguages / totalLanguages * 100).toInt();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Emoji et nom
                  Hero(
                    tag: 'animal_${animal.id}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.orange.shade100],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getAnimalEmoji(animal.id),
                          style: const TextStyle(fontSize: 70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    animal.getNameInLanguage('fr'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    animal.scientificName,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Statistiques
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailStat(
                          icon: Icons.star,
                          label: 'Points',
                          value: '${animal.basePoints}',
                          color: Colors.amber,
                        ),
                        _buildDetailStat(
                          icon: Icons.language,
                          label: 'Maîtrise',
                          value: '$progressPercent%',
                          color: const Color(0xFF4CAF50),
                        ),
                        _buildDetailStat(
                          icon: Icons.emoji_events,
                          label: 'Langues',
                          value: '$masteredLanguages/$totalLanguages',
                          color: const Color(0xFF6C63FF),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Fun fact
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            animal.getFunFact('fr'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Langues apprises
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🌍 Progression linguistique',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildLanguageChip('fr', 'Français', masteredLanguages >= 1),
                            _buildLanguageChip('en', 'English', masteredLanguages >= 2),
                            _buildLanguageChip('es', 'Español', masteredLanguages >= 3),
                            _buildLanguageChip('de', 'Deutsch', masteredLanguages >= 4),
                            _buildLanguageChip('it', 'Italiano', masteredLanguages >= 5),
                            _buildLanguageChip('pt', 'Português', masteredLanguages >= 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Bouton d'action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startAnimalDiscovery();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Apprendre ce mot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLanguageChip(String code, String name, bool isLearned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLearned
            ? Colors.green.withOpacity(0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLearned
              ? Colors.green
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLearned)
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
          if (isLearned) const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isLearned ? FontWeight.w500 : FontWeight.normal,
              color: isLearned ? Colors.green : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getAnimalEmoji(String animalId) {
    const emojis = {
      'lion': '🦁', 'elephant': '🐘', 'giraffe': '🦒', 'panda': '🐼',
      'tiger': '🐯', 'zebra': '🦓', 'monkey': '🐒', 'dolphin': '🐬',
      'kangaroo': '🦘', 'koala': '🐨', 'penguin': '🐧', 'owl': '🦉',
    };
    return emojis[animalId] ?? '🐾';
  }
  
  Widget _buildLanguageSelectorSheet() {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choisis ta langue',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                final languages = ['Français', 'English', 'Español', 'Deutsch', 'Italiano', 'Português'];
                final flags = ['🇫🇷', '🇬🇧', '🇪🇸', '🇩🇪', '🇮🇹', '🇵🇹'];
                return ListTile(
                  leading: Text(flags[index % flags.length], style: const TextStyle(fontSize: 28)),
                  title: Text(languages[index % languages.length]),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}