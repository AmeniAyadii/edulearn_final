import 'dart:convert';

import 'package:edulearn_final/services/local_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../services/activity_history_service.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class WordHistoryScreen extends StatefulWidget {
  final String? childId;
  const WordHistoryScreen({super.key, this.childId});

  @override
  State<WordHistoryScreen> createState() => _WordHistoryScreenState();
}

class _WordHistoryScreenState extends State<WordHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ActivityHistoryService _historyService = ActivityHistoryService();
  final SoundService _soundService = SoundService();
  final LocalAuthService _auth = LocalAuthService(); // ✅ AJOUTER CETTE LIGNE
  
  List<ActivityModel> _activities = [];
  List<Map<String, dynamic>> _childrenStats = [];
  List<Map<String, dynamic>> _groupedActivitiesList = []; // ✅ AJOUTER CETTE LIGNE
  bool _isLoading = true;
  String _filterType = 'all';
  String _selectedChildId = 'all'; // Nouveau: filtre par enfant
  String _searchQuery = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _activityTypes = [
    {'value': 'all', 'label': 'Tous', 'icon': Icons.list, 'color': Colors.grey},
    {'value': 'scan_word', 'label': 'Mots scannés', 'icon': Icons.text_fields, 'color': Colors.blue},
    {'value': 'recognition', 'label': 'Reconnaissance', 'icon': Icons.image, 'color': Colors.purple},
    {'value': 'document_scan', 'label': 'Documents', 'icon': Icons.document_scanner, 'color': Colors.teal},
    {'value': 'dictation', 'label': 'Dictées', 'icon': Icons.mic, 'color': Colors.orange},
    {'value': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz, 'color': Colors.green},
    {'value': 'translation', 'label': 'Traductions', 'icon': Icons.translate, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeHistory();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _playClickSound() async {
    await _soundService.playClick();
  }

  Future<void> _initializeHistory() async {
    setState(() => _isLoading = true);
    
    if (widget.childId != null) {
      final activities = await _historyService.getActivitiesByChild(widget.childId!);
      if (activities.isEmpty) {
        await _addTestActivitiesForChild(widget.childId!);
      }
    } else {
      // Vérifier si des activités existent pour tous les enfants
      final allActivities = await _historyService.getAllActivities();
      if (allActivities.isEmpty) {
        await _addTestActivitiesForMultipleChildren();
      }
    }
    
    await _loadHistory();
    await _loadChildrenStats();
  }

  Future<void> _addTestActivitiesForChild(String childId) async {
    print('📝 Ajout des activités de test pour l\'enfant $childId...');
    
    final testActivities = [
      {'type': 'scan_word', 'title': 'Mot scanné: Pomme', 'desc': 'Vous avez scanné le mot "Pomme" avec succès.', 'points': 10},
      {'type': 'scan_word', 'title': 'Mot scanné: Chat', 'desc': 'Vous avez scanné le mot "Chat" avec succès.', 'points': 15},
      {'type': 'recognition', 'title': 'Reconnaissance d\'image', 'desc': 'Vous avez reconnu un chat dans l\'image.', 'points': 20},
      {'type': 'document_scan', 'title': 'Document scanné', 'desc': 'Vous avez scanné un document sur les animaux.', 'points': 25},
      {'type': 'dictation', 'title': 'Dictée: Maison', 'desc': 'Vous avez écrit correctement le mot "Maison".', 'points': 12},
      {'type': 'quiz', 'title': 'Quiz: Les animaux', 'desc': 'Score: 8/10. Bon travail!', 'points': 30},
      {'type': 'translation', 'title': 'Traduction: Hello', 'desc': 'Vous avez traduit "Hello" en "Bonjour".', 'points': 8},
    ];

    for (var i = 0; i < testActivities.length; i++) {
      final activity = testActivities[i];
      await _historyService.addActivitySimple(
        childId: childId,
        activityType: activity['type'] as String,
        title: activity['title'] as String,
        description: activity['desc'] as String,
        points: activity['points'] as int,
        duration: 3,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('✅ ${testActivities.length} activités ajoutées pour l\'enfant');
  }

  Future<void> _addTestActivitiesForMultipleChildren() async {
    print('📝 Ajout des activités de test pour plusieurs enfants...');
    
    final children = [
      {'id': 'child_1', 'name': 'Sarah', 'age': 5},
      {'id': 'child_2', 'name': 'Omar', 'age': 6},
      {'id': 'child_3', 'name': 'Lina', 'age': 4},
    ];
    
    final testActivities = [
      {'type': 'scan_word', 'title': 'Mot scanné: Pomme', 'desc': 'a scanné le mot "Pomme"', 'points': 10},
      {'type': 'scan_word', 'title': 'Mot scanné: Chat', 'desc': 'a scanné le mot "Chat"', 'points': 15},
      {'type': 'recognition', 'title': 'Reconnaissance', 'desc': 'a reconnu un animal', 'points': 20},
      {'type': 'document_scan', 'title': 'Document scanné', 'desc': 'a scanné un document', 'points': 25},
      {'type': 'dictation', 'title': 'Dictée', 'desc': 'a fait une dictée', 'points': 12},
      {'type': 'quiz', 'title': 'Quiz', 'desc': 'a complété un quiz', 'points': 30},
    ];
    
    for (var child in children) {
      for (var i = 0; i < testActivities.length; i++) {
        final activity = testActivities[i];
        await _historyService.addActivitySimple(
          childId: child['id'] as String,
          activityType: activity['type'] as String,
          title: activity['title'] as String,
          description: '${child['name']} ${activity['desc']} +${activity['points']} points',
          points: activity['points'] as int,
          duration: 3,
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    // Ajouter des activités pour l'enfant actuel si spécifié
    if (widget.childId != null) {
      await _addTestActivitiesForChild(widget.childId!);
    }
    
    print('✅ Activités de test ajoutées pour ${children.length} enfants');
  }

  Future<void> _loadChildrenStats() async {
  final allActivities = await _historyService.getAllActivities();
  final Map<String, Map<String, dynamic>> childrenMap = {};
  
  print('📊 Chargement des statistiques enfants...');
  print('Nombre d\'activités: ${allActivities.length}');
  
  for (var activity in allActivities) {
    print('Activité: childId=${activity.childId}, childName=${activity.childName}');
    
    if (!childrenMap.containsKey(activity.childId)) {
      childrenMap[activity.childId] = {
        'childId': activity.childId,
        'childName': activity.childName,
        'totalPoints': 0,
        'totalActivities': 0,
      };
    }
    childrenMap[activity.childId]!['totalPoints'] = 
        (childrenMap[activity.childId]!['totalPoints'] as int) + activity.points;
    childrenMap[activity.childId]!['totalActivities'] = 
        (childrenMap[activity.childId]!['totalActivities'] as int) + 1;
  }
  
  _childrenStats = childrenMap.values.toList()
    ..sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
  
  print('👥 Enfants trouvés: ${_childrenStats.length}');
  for (var child in _childrenStats) {
    print('   - ${child['childName']}: ${child['totalPoints']} points');
  }
  
  setState(() {});
}

  // lib/screens/word_history_screen.dart

// Ajoutez cette méthode pour charger les enfants et leurs activités
Future<void> _loadActivitiesByChild() async {
  setState(() => _isLoading = true);
  
  try {
    // Récupérer toutes les activités
    List<ActivityModel> allActivities;
    
    if (_selectedChildId != 'all') {
      allActivities = await _historyService.getActivitiesByChild(_selectedChildId);
    } else {
      allActivities = await _historyService.getAllActivities();
    }
    
    // Appliquer le filtre par type
    if (_filterType != 'all') {
      allActivities = allActivities.where((a) => a.activityType == _filterType).toList();
    }
    
    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      allActivities = allActivities.where((a) =>
        a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Trier par date (plus récent d'abord)
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Grouper par enfant
    final Map<String, List<ActivityModel>> groupedActivities = {};
    for (var activity in allActivities) {
      final childKey = activity.childId;
      if (!groupedActivities.containsKey(childKey)) {
        groupedActivities[childKey] = [];
      }
      groupedActivities[childKey]!.add(activity);
    }
    
    // Convertir en liste pour l'affichage
    _groupedActivitiesList = groupedActivities.entries.map((entry) {
      return {
        'childId': entry.key,
        'childName': entry.value.first.childName,
        'activities': entry.value,
        'totalPoints': entry.value.fold(0, (sum, a) => sum + a.points),
        'totalCount': entry.value.length,
      };
    }).toList();
    
    // Trier par points totaux décroissants
    _groupedActivitiesList.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
    
    setState(() => _isLoading = false);
  } catch (e) {
    print('❌ Erreur: $e');
    setState(() => _isLoading = false);
  }
}

// Ajoutez cette variable dans l'état
//List<Map<String, dynamic>> _groupedActivitiesList = [];


// Ajoutez cette méthode temporaire pour déboguer
Future<void> _debugPrintActivities() async {
  final allActivities = await _historyService.getAllActivities();
  print('=== DÉBOGAGE HISTORIQUE ===');
  print('Nombre total d\'activités: ${allActivities.length}');
  for (var activity in allActivities) {
    print('ID: ${activity.childId}, Nom: ${activity.childName}, Titre: ${activity.title}');
  }
  print('===========================');
}


// Dans activity_history_service.dart, vérifiez que cette méthode existe
Future<void> addActivitySimpleWithName({
  required String childId,
  required String childName,
  required String activityType,
  required String title,
  required String description,
  int points = 10,
  int duration = 0,
  Map<String, dynamic>? metadata,
}) async {
  final activity = ActivityModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    childId: childId,
    childName: childName,
    activityType: activityType,
    title: title,
    description: description,
    points: points,
    duration: duration,
    timestamp: DateTime.now(),
    metadata: metadata,
  );
  //await addActivity(activity);
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
// Ajoutez cette méthode pour récupérer les vrais enfants
Future<List<Map<String, dynamic>>> _getRealChildren() async {
  // Méthode 1: Depuis SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final childrenJson = prefs.getString('children_list');
  
  List<Map<String, dynamic>> children = [];
  
  if (childrenJson != null) {
    try {
      children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      print('📚 Enfants chargés depuis SharedPreferences: ${children.length}');
    } catch (e) {
      print('Erreur chargement enfants: $e');
    }
  }
  
  // Méthode 2: Depuis LocalAuthService
  if (children.isEmpty) {
    final currentUser = await _auth.getCurrentUser();
    if (currentUser != null && currentUser.containsKey('children')) {
      children = List<Map<String, dynamic>>.from(currentUser['children']);
      print('📚 Enfants chargés depuis AuthService: ${children.length}');
    }
  }
  
  // Si toujours vide, utiliser des données de test
  if (children.isEmpty) {
    print('⚠️ Aucun enfant trouvé, utilisation de données de test');
    children = [
      {'id': 'child_1', 'name': 'Sarah'},
      {'id': 'child_2', 'name': 'Omar'},
      {'id': 'child_3', 'name': 'Lina'},
    ];
  }
  
  return children;
}

// Appelez cette méthode dans _initializeHistory après le chargement
//await _debugPrintActivities();
// Modifiez _loadHistory pour utiliser la nouvelle méthode
Future<void> _loadHistory() async {
  setState(() => _isLoading = true);
  
  try {
    // Récupérer toutes les activités
    List<ActivityModel> allActivities;
    
    if (_selectedChildId != 'all') {
      allActivities = await _historyService.getActivitiesByChild(_selectedChildId);
    } else {
      allActivities = await _historyService.getAllActivities();
    }
    
    // Appliquer le filtre par type
    if (_filterType != 'all') {
      allActivities = allActivities.where((a) => a.activityType == _filterType).toList();
    }
    
    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      allActivities = allActivities.where((a) =>
        a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Trier par date (plus récent d'abord)
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Sauvegarder dans _activities pour les statistiques globales
    _activities = allActivities;
    
    // Grouper par enfant
    final Map<String, List<ActivityModel>> groupedActivities = {};
    for (var activity in allActivities) {
      final childKey = activity.childId;
      if (!groupedActivities.containsKey(childKey)) {
        groupedActivities[childKey] = [];
      }
      groupedActivities[childKey]!.add(activity);
    }
    
    // Convertir en liste pour l'affichage
    _groupedActivitiesList = groupedActivities.entries.map((entry) {
      final activities = entry.value;
      return {
        'childId': entry.key,
        'childName': activities.isNotEmpty ? activities.first.childName : 'Enfant',
        'activities': activities,
        'totalPoints': activities.fold(0, (sum, a) => sum + a.points),
        'totalCount': activities.length,
      };
    }).toList();
    
    // Trier par points totaux décroissants
    _groupedActivitiesList.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
    
    print('📊 Activités chargées: ${allActivities.length}');
    print('👥 Enfants: ${_groupedActivitiesList.length}');
    
    setState(() => _isLoading = false);
  } catch (e) {
    print('❌ Erreur: $e');
    setState(() => _isLoading = false);
  }
}
  

  Future<void> _deleteActivity(ActivityModel activity) async {
    await _playClickSound();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer'),
        content: Text('Supprimer cette activité de ${activity.childName} du ${_formatDate(activity.timestamp)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _playClickSound();
              await _historyService.deleteActivity(activity.id);
              await _loadHistory();
              await _loadChildrenStats();
              Navigator.pop(context);
              _showSnackBar('🗑️ Activité supprimée');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    if (_activities.isEmpty) return;
    
    await _playClickSound();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Effacer tout'),
        content: const Text('Supprimer tout l\'historique pour tous les enfants ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _playClickSound();
              await _historyService.clearAllHistory();
              await _loadHistory();
              await _loadChildrenStats();
              Navigator.pop(context);
              _showSnackBar('🧹 Historique effacé');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(ActivityModel activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getActivityIcon(activity.activityType),
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              activity.title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    activity.childName,
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getActivityColor(activity.activityType).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                activity.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(activity.timestamp),
                ),
                _buildDetailChip(
                  icon: Icons.star,
                  label: '+${activity.points} pts',
                  color: Colors.amber,
                ),
                if (activity.duration > 0)
                  _buildDetailChip(
                    icon: Icons.timer,
                    label: '${activity.duration} sec',
                    color: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: activity.description));
                      Navigator.pop(context);
                      _showSnackBar('📋 Texte copié !');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Fermer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.isAfter(today)) {
      return "Aujourd'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (date.isAfter(yesterday)) {
      return "Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'scan_word': return Icons.text_fields;
      case 'recognition': return Icons.image;
      case 'document_scan': return Icons.document_scanner;
      case 'dictation': return Icons.mic;
      case 'quiz': return Icons.quiz;
      case 'translation': return Icons.translate;
      default: return Icons.star;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'scan_word': return Colors.blue;
      case 'recognition': return Colors.purple;
      case 'document_scan': return Colors.teal;
      case 'dictation': return Colors.orange;
      case 'quiz': return Colors.green;
      case 'translation': return Colors.indigo;
      default: return AppTheme.primaryColor;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  // Calculer les statistiques totales
  final totalPoints = _activities.fold(0, (sum, a) => sum + a.points);
  final totalActivities = _activities.length;
  final averagePoints = totalActivities > 0 ? (totalPoints / totalActivities).round() : 0;
  
  // Statistiques par enfant
  final childrenStats = _getChildrenStats();

  return Scaffold(
    backgroundColor: AppTheme.lightBackground,
    appBar: AppBar(
      title: Text(
        '📜 Historique des enfants',
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await _loadHistory();
            await _loadChildrenStats();
          },
          tooltip: 'Actualiser',
        ),
        if (_activities.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllHistory,
            tooltip: 'Tout effacer',
          ),
      ],
    ),
    body: Column(
      children: [
        // Barre des enfants (scores)
        if (childrenStats.isNotEmpty && widget.childId == null)
          _buildChildrenStatsBar(childrenStats),
        
        _buildSearchBar(),
        _buildFilters(),
        
        if (_selectedChildId == 'all' && widget.childId == null)
          _buildChildSelector(childrenStats),
        
        _buildStatsCard(totalPoints, totalActivities, averagePoints),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groupedActivitiesList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groupedActivitiesList.length,
                      itemBuilder: (context, index) {
                        final childData = _groupedActivitiesList[index];
                        return _buildChildSection(childData);
                      },
                    ),
        ),
      ],
    ),
  );
}

// Nouvelle méthode pour construire une section par enfant
Widget _buildChildSection(Map<String, dynamic> childData) {
  final childName = childData['childName'] as String;
  final activities = childData['activities'] as List<ActivityModel>;
  final totalPoints = childData['totalPoints'] as int;
  final totalCount = childData['totalCount'] as int;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de l'enfant
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.1)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.child_care, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount activités • $totalPoints points',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      totalPoints.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Liste des activités de l'enfant
        ...activities.map((activity) => _buildActivityCard(activity)).toList(),
      ],
    ),
  );
}

// Barre des enfants (scores)
Widget _buildChildrenStatsBar(List<Map<String, dynamic>> childrenStats) {
  return Container(
    height: 80,
    margin: const EdgeInsets.all(8),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: childrenStats.length,
      itemBuilder: (context, index) {
        final child = childrenStats[index];
        final isSelected = _selectedChildId == child['childId'];
        return GestureDetector(
          onTap: () async {
            await _playClickSound();
            setState(() {
              _selectedChildId = isSelected ? 'all' : child['childId'];
            });
            await _loadHistory();
          },
          child: Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.child_care,
                    size: 20,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  child['childName'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${child['totalPoints']} pts',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Sélecteur d'enfant (dropdown)
Widget _buildChildSelector(List<Map<String, dynamic>> childrenStats) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedChildId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Sélectionner un enfant'),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('📊 Tous les enfants'),
              ),
              ...childrenStats.map((child) => DropdownMenuItem(
                value: child['childId'],
                child: Row(
                  children: [
                    Icon(Icons.child_care, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(child['childName']),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${child['totalPoints']} pts',
                        style: const TextStyle(fontSize: 10, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: (value) async {
              await _playClickSound();
              setState(() {
                _selectedChildId = value!;
              });
              await _loadHistory();
            },
          ),
        ),
      ],
    ),
  );
}

// Méthode pour obtenir les statistiques des enfants
List<Map<String, dynamic>> _getChildrenStats() {
  final Map<String, Map<String, dynamic>> childrenMap = {};
  
  for (var activity in _activities) {
    if (!childrenMap.containsKey(activity.childId)) {
      childrenMap[activity.childId] = {
        'childId': activity.childId,
        'childName': activity.childName,
        'totalPoints': 0,
        'totalActivities': 0,
      };
    }
    childrenMap[activity.childId]!['totalPoints'] = 
        (childrenMap[activity.childId]!['totalPoints'] as int) + activity.points;
    childrenMap[activity.childId]!['totalActivities'] = 
        (childrenMap[activity.childId]!['totalActivities'] as int) + 1;
  }
  
  return childrenMap.values.toList()
    ..sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
}

 

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _loadHistory();
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une activité...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _loadHistory();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activityTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = _activityTypes[index];
          final isSelected = _filterType == type['value'];
          
          return FilterChip(
            label: Text(type['label']),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _filterType = type['value'];
                _loadHistory();
              });
            },
            avatar: Icon(type['icon'], size: 18),
            backgroundColor: Colors.white,
            selectedColor: (type['color'] as Color).withOpacity(0.1),
            checkmarkColor: type['color'],
            labelStyle: TextStyle(
              color: isSelected ? type['color'] : Colors.grey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(int totalPoints, int totalActivities, int averagePoints) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.star, '$totalPoints', 'Points'),
          _buildStatItem(Icons.history, '$totalActivities', 'Activités'),
          _buildStatItem(Icons.trending_up, '$averagePoints', 'Moyenne'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _filterType != 'all' ? Icons.filter_alt_off : Icons.history,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filterType != 'all' ? 'Aucune activité dans cette catégorie' : 'Aucune activité',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterType != 'all'
                ? 'Essayez un autre filtre'
                : 'Scannez des mots ou faites des activités',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await _loadHistory();
              await _loadChildrenStats();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final color = _getActivityColor(activity.activityType);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          onTap: () => _showActivityDetails(activity),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icône
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getActivityIcon(activity.activityType),
                        size: 28,
                        color: color,
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
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person, size: 10, color: Colors.blue),
                                    const SizedBox(width: 2),
                                    Text(
                                      activity.childName,
                                      style: TextStyle(fontSize: 10, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 10, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(activity.timestamp),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(height: 2),
                          Text(
                            '+${activity.points}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _deleteActivity(activity);
                        } else if (value == 'copy') {
                          await Clipboard.setData(ClipboardData(text: activity.description));
                          _showSnackBar('📋 Texte copié !');
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 12),
                              Text('Copier le texte'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}