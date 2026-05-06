// lib/screens/history/history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// MODÈLE DE DONNÉES
// ============================================================================

class HistoryItem {
  final String id;
  final String type;
  final String category; // 'activity' ou 'game'
  final String title;
  final String subtitle;
  final String? imageUrl;
  final DateTime timestamp;
  final int points;
  final Map<String, dynamic> details;
  final String childId;
  final String childName;

  HistoryItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.timestamp,
    required this.points,
    required this.details,
    required this.childId,
    required this.childName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'category': category,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'timestamp': Timestamp.fromDate(timestamp),
    'points': points,
    'details': details,
    'childId': childId,
    'childName': childName,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json, String id) => HistoryItem(
    id: id,
    type: json['type'] as String,
    category: json['category'] as String? ?? _getCategoryFromType(json['type'] as String),
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    imageUrl: json['imageUrl'] as String?,
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    points: json['points'] as int,
    details: json['details'] as Map<String, dynamic>? ?? {},
    childId: json['childId'] as String,
    childName: json['childName'] as String,
  );
  
  static String _getCategoryFromType(String type) {
    final gameTypes = [
      'emotion_game', 'show_object_game', 'guess_game', 'category_game',
      'drawing_game', 'rhythm_game', 'translation_flash', 'language_mystery',
      'food_learning', 'color_learning', 'polyglot_animal_mlkit', 'spy_game'
    ];
    return gameTypes.contains(type) ? 'game' : 'activity';
  }
}

class HistoryStats {
  final int totalActions;
  final int totalPoints;
  final Map<String, int> byType;
  final int last7Days;
  final int thisMonth;
  final int bestDay;
  final Map<int, int> pointsPerDay;
  final int totalActivities;
  final int totalGames;
  final int activityPoints;
  final int gamePoints;
  
  HistoryStats({
    required this.totalActions,
    required this.totalPoints,
    required this.byType,
    required this.last7Days,
    required this.thisMonth,
    required this.bestDay,
    required this.pointsPerDay,
    required this.totalActivities,
    required this.totalGames,
    required this.activityPoints,
    required this.gamePoints,
  });
  
  double get averagePointsPerDay => totalPoints / 30;
}

// ============================================================================
// SERVICE D'HISTORIQUE FIREBASE
// ============================================================================

class HistoryFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userId => _auth.currentUser?.uid ?? 'anonymous';
  
  Future<void> saveHistoryItem(HistoryItem item) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(item.id)
          .set(item.toJson());
      print('✅ Historique sauvegardé: ${item.title} (${item.category})');
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
    }
  }
  
  Future<List<HistoryItem>> getHistory({String? type, String? category, int limit = 100}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (type != null && type != 'all') {
        query = query.where('type', isEqualTo: type);
      }
      
      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }
      
      final snapshot = await query.get();
      final List<HistoryItem> items = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          items.add(HistoryItem.fromJson(data, doc.id));
        }
      }
      
      return items;
    } catch (e) {
      print('Erreur récupération: $e');
      return [];
    }
  }
  
  Future<void> deleteHistoryItem(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(id)
          .delete();
    } catch (e) {
      print('Erreur suppression: $e');
    }
  }
  
  Future<void> clearHistory() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Erreur vidage: $e');
    }
  }
  
  Future<HistoryStats> getStats() async {
    final items = await getHistory(limit: 1000);
    final now = DateTime.now();
    final last7DaysStart = now.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    
    final Map<int, int> pointsPerDay = {};
    
    int totalActivities = 0;
    int totalGames = 0;
    int activityPoints = 0;
    int gamePoints = 0;
    
    for (var item in items) {
      final day = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
      pointsPerDay[day.millisecondsSinceEpoch] = (pointsPerDay[day.millisecondsSinceEpoch] ?? 0) + item.points;
      
      if (item.category == 'activity') {
        totalActivities++;
        activityPoints += item.points;
      } else {
        totalGames++;
        gamePoints += item.points;
      }
    }
    
    final bestDay = pointsPerDay.isNotEmpty ? pointsPerDay.values.reduce((a, b) => a > b ? a : b) : 0;
    
    return HistoryStats(
      totalActions: items.length,
      totalPoints: items.fold(0, (sum, item) => sum + item.points),
      byType: _groupByType(items),
      last7Days: items.where((item) => item.timestamp.isAfter(last7DaysStart)).length,
      thisMonth: items.where((item) => item.timestamp.isAfter(thisMonthStart)).length,
      bestDay: bestDay,
      pointsPerDay: pointsPerDay,
      totalActivities: totalActivities,
      totalGames: totalGames,
      activityPoints: activityPoints,
      gamePoints: gamePoints,
    );
  }
  
  Map<String, int> _groupByType(List<HistoryItem> items) {
    final map = <String, int>{};
    for (var item in items) {
      map[item.type] = (map[item.type] ?? 0) + 1;
    }
    return map;
  }
  
  // Ajouter des données de test
  Future<void> addSampleData({String? childId, String? childName}) async {
    final now = DateTime.now();
    final samples = [
      // ==================== ACTIVITÉS D'APPRENTISSAGE ====================
      HistoryItem(
        id: 'sample_alphabet_${DateTime.now().millisecondsSinceEpoch}',
        type: 'alphabet',
        category: 'activity',
        title: 'Alphabet Magique',
        subtitle: 'Apprentissage des lettres A à Z',
        timestamp: now.subtract(const Duration(days: 1)),
        points: 100,
        details: {'Lettres apprises': '26', 'Niveau': 'Débutant'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_numbers_${DateTime.now().millisecondsSinceEpoch}',
        type: 'numbers',
        category: 'activity',
        title: 'Chiffres et Nombres',
        subtitle: 'Comptage de 1 à 100',
        timestamp: now.subtract(const Duration(days: 2)),
        points: 100,
        details: {'Nombres maîtrisés': '50', 'Score': '95%'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_colors_${DateTime.now().millisecondsSinceEpoch}',
        type: 'colors',
        category: 'activity',
        title: 'Couleurs du Monde',
        subtitle: 'Découverte des couleurs en plusieurs langues',
        timestamp: now.subtract(const Duration(days: 3)),
        points: 100,
        details: {'Couleurs apprises': '12', 'Langues': 'Français, Anglais, Espagnol'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_shapes_${DateTime.now().millisecondsSinceEpoch}',
        type: 'shapes',
        category: 'activity',
        title: 'Formes Géométriques',
        subtitle: 'Reconnaissance des formes',
        timestamp: now.subtract(const Duration(days: 4)),
        points: 100,
        details: {'Formes reconnues': '8', 'Niveau': 'Intermédiaire'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_lecture_${DateTime.now().millisecondsSinceEpoch}',
        type: 'lecture',
        category: 'activity',
        title: 'Lecture Interactive',
        subtitle: 'Mots scannés: "Bonjour le monde"',
        timestamp: now.subtract(const Duration(days: 5)),
        points: 120,
        details: {'Mots détectés': '3', 'Temps': '30s'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_dictation_${DateTime.now().millisecondsSinceEpoch}',
        type: 'speech',
        category: 'activity',
        title: 'Dictée Magique',
        subtitle: 'Texte dicté avec succès',
        timestamp: now.subtract(const Duration(days: 6)),
        points: 130,
        details: {'Précision': '88%', 'Mots corrects': '12/15'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_writing_${DateTime.now().millisecondsSinceEpoch}',
        type: 'animal_writing',
        category: 'activity',
        title: 'Écriture Créative',
        subtitle: 'Phrase écrite: "Le chat mange une pomme"',
        timestamp: now.subtract(const Duration(days: 7)),
        points: 140,
        details: {'Longueur': '5 mots', 'Grammaire': 'Correcte'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_grammar_${DateTime.now().millisecondsSinceEpoch}',
        type: 'grammar_analysis',
        category: 'activity',
        title: 'Grammaire en Folie',
        subtitle: 'Analyse grammaticale complète',
        timestamp: now.subtract(const Duration(days: 8)),
        points: 150,
        details: {'Phrases analysées': '10', 'Précision': '90%'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_entities_${DateTime.now().millisecondsSinceEpoch}',
        type: 'entity_extraction',
        category: 'activity',
        title: 'Extraction d\'Entités',
        subtitle: 'Entités identifiées: Personnes, Lieux, Dates',
        timestamp: now.subtract(const Duration(days: 9)),
        points: 160,
        details: {'Entités trouvées': '15', 'Types': '4'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_flashcard_${DateTime.now().millisecondsSinceEpoch}',
        type: 'flashcard',
        category: 'activity',
        title: 'Cartes Mémoire',
        subtitle: '20 flashcards maîtrisées',
        timestamp: now.subtract(const Duration(days: 10)),
        points: 100,
        details: {'Cartes apprises': '20', 'Temps': '10min'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_scanner_${DateTime.now().millisecondsSinceEpoch}',
        type: 'document_scanner',
        category: 'activity',
        title: 'Scanner Intelligent',
        subtitle: 'Document scanné: "Leçons de mathématiques"',
        timestamp: now.subtract(const Duration(days: 11)),
        points: 130,
        details: {'Pages': '5', 'Qualité': 'Haute'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_landmark_${DateTime.now().millisecondsSinceEpoch}',
        type: 'landmark',
        category: 'activity',
        title: 'Tour Eiffel',
        subtitle: 'Paris, France - Monument reconnu',
        timestamp: now.subtract(const Duration(days: 12)),
        points: 150,
        details: {'Confiance': '95%', 'Hauteur': '330m'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      
      // ==================== JEUX ÉDUCATIFS ====================
      HistoryItem(
        id: 'sample_emotion_${DateTime.now().millisecondsSinceEpoch}',
        type: 'emotion_game',
        category: 'game',
        title: 'Devine l\'Émotion',
        subtitle: 'Reconnaissance des émotions - Score: 85%',
        timestamp: now.subtract(const Duration(days: 13)),
        points: 100,
        details: {'Score': '85%', 'Émotions reconnues': '6/8'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_guess_object_${DateTime.now().millisecondsSinceEpoch}',
        type: 'guess_game',
        category: 'game',
        title: 'Devine ce que je vois',
        subtitle: 'Objet mystère trouvé avec 2 indices',
        timestamp: now.subtract(const Duration(days: 14)),
        points: 150,
        details: {'Objet': 'Tour Eiffel', 'Indices utilisés': '2', 'Essais': '1'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_object_${DateTime.now().millisecondsSinceEpoch}',
        type: 'show_object_game',
        category: 'game',
        title: 'Montre-moi l\'objet',
        subtitle: 'Objet trouvé: Livre en 5 secondes',
        timestamp: now.subtract(const Duration(days: 15)),
        points: 150,
        details: {'Objet': 'Livre', 'Temps': '5s'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_category_${DateTime.now().millisecondsSinceEpoch}',
        type: 'category_game',
        category: 'game',
        title: 'Jeu des Catégories',
        subtitle: '10 mots classés correctement',
        timestamp: now.subtract(const Duration(days: 16)),
        points: 130,
        details: {'Score': '10/10', 'Catégories': 'Animaux, Fruits, Couleurs'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_drawing_${DateTime.now().millisecondsSinceEpoch}',
        type: 'drawing_game',
        category: 'game',
        title: 'Dessine et Détecte',
        subtitle: 'Dessin reconnu par l\'IA avec 92% précision',
        timestamp: now.subtract(const Duration(days: 17)),
        points: 160,
        details: {'Dessin': 'Chat', 'Précision': '92%'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_rhythm_${DateTime.now().millisecondsSinceEpoch}',
        type: 'rhythm_game',
        category: 'game',
        title: 'Le Bon Rythme',
        subtitle: 'Combo x5 - Score: 250 points',
        timestamp: now.subtract(const Duration(days: 18)),
        points: 180,
        details: {'Combo': 'x5', 'Score': '250'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_translation_${DateTime.now().millisecondsSinceEpoch}',
        type: 'translation_flash',
        category: 'game',
        title: 'Traduction Flash',
        subtitle: '10 mots traduits en 45 secondes',
        timestamp: now.subtract(const Duration(days: 19)),
        points: 120,
        details: {'Score': '10/10', 'Temps': '45s'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_language_${DateTime.now().millisecondsSinceEpoch}',
        type: 'language_mystery',
        category: 'game',
        title: 'Langue Mystère',
        subtitle: 'Langue découverte: Espagnol avec 3 indices',
        timestamp: now.subtract(const Duration(days: 20)),
        points: 170,
        details: {'Langue devinée': 'Espagnol', 'Indices': '3'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_food_${DateTime.now().millisecondsSinceEpoch}',
        type: 'food_learning',
        category: 'game',
        title: 'Fruits & Légumes',
        subtitle: '15 fruits et légumes appris en 3 langues',
        timestamp: now.subtract(const Duration(days: 21)),
        points: 150,
        details: {'Fruits': '8', 'Légumes': '7', 'Langues': 'FR, EN, ES'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_polyglot_colors_${DateTime.now().millisecondsSinceEpoch}',
        type: 'color_learning',
        category: 'game',
        title: 'Polyglot Colors',
        subtitle: '12 couleurs apprises en 5 langues',
        timestamp: now.subtract(const Duration(days: 22)),
        points: 150,
        details: {'Couleurs': '12', 'Langues maîtrisées': '5'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
      HistoryItem(
        id: 'sample_animal_ai_${DateTime.now().millisecondsSinceEpoch}',
        type: 'polyglot_animal_mlkit',
        category: 'game',
        title: 'Animal Explorer AI',
        subtitle: 'Chat détecté - Appris en 12 langues',
        timestamp: now.subtract(const Duration(days: 23)),
        points: 250,
        details: {'Animal': 'Chat', 'Confiance': '98%', 'Langues': '12'},
        childId: childId ?? 'test_child',
        childName: childName ?? 'Test Enfant',
      ),
    ];
    
    for (var item in samples) {
      await saveHistoryItem(item);
    }
    print('✅ Données de test ajoutées: ${samples.length} éléments (Activités: ${samples.where((i) => i.category == 'activity').length}, Jeux: ${samples.where((i) => i.category == 'game').length})');
  }
  
  // Test rapide pour vérifier Firestore
  Future<void> testFirestore() async {
    try {
      print('1️⃣ Création d\'un élément test...');
      
      await saveHistoryItem(
        HistoryItem(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          type: 'test',
          category: 'activity',
          title: 'Test Connection',
          subtitle: 'Ceci est un test',
          timestamp: DateTime.now(),
          points: 10,
          details: {'test': 'ok'},
          childId: 'test',
          childName: 'Test',
        ),
      );
      print('2️⃣ Élément sauvegardé avec succès!');
      
      final items = await getHistory();
      print('3️⃣ Nombre total d\'éléments: ${items.length}');
      
      if (items.isNotEmpty) {
        print('4️⃣ Premier élément: ${items.first.title}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
}

// ============================================================================
// WIDGET PRINCIPAL
// ============================================================================

class HistoryScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const HistoryScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late HistoryFirebaseService _historyService;
  late TabController _tabController;
  late AnimationController _animationController;
  
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedCategory = 'all'; // 'all', 'activity', 'game'
  HistoryStats? _stats;
  String? _error;
  
  // Variable pour le mode sombre
  bool _isDarkMode = false;
  
  // Filtres par catégorie principale
  final List<Map<String, dynamic>> _categoryFilters = [
    {'id': 'all', 'label': '📊 Tout', 'icon': Icons.dashboard, 'color': Colors.grey},
    {'id': 'activity', 'label': '📚 Activités', 'icon': Icons.school, 'color': Colors.green},
    {'id': 'game', 'label': '🎮 Jeux', 'icon': Icons.sports_esports, 'color': Color(0xFF6C63FF)},
  ];
  
  // Filtres par type d'activité (pour les activités)
  final List<Map<String, dynamic>> _activityFilters = [
    {'id': 'all_activities', 'label': '📚 Toutes les activités', 'color': Colors.green},
    {'id': 'alphabet', 'label': '🔤 Alphabet', 'color': Color(0xFFE91E63)},
    {'id': 'numbers', 'label': '🔢 Nombres', 'color': Color(0xFF2196F3)},
    {'id': 'colors', 'label': '🎨 Couleurs', 'color': Color(0xFF9C27B0)},
    {'id': 'shapes', 'label': '📐 Formes', 'color': Color(0xFF4CAF50)},
    {'id': 'lecture', 'label': '📖 Lecture', 'color': Colors.blue},
    {'id': 'speech', 'label': '🎙️ Dictée', 'color': Color(0xFF9C27B0)},
    {'id': 'animal_writing', 'label': '✏️ Écriture', 'color': Color(0xFFFF6B35)},
    {'id': 'grammar_analysis', 'label': '📝 Grammaire', 'color': Color(0xFFFF9800)},
    {'id': 'entity_extraction', 'label': '🔍 Entités', 'color': Color(0xFF6C63FF)},
    {'id': 'flashcard', 'label': '🃏 Flashcards', 'color:': Color(0xFF4CAF50)},
    {'id': 'document_scanner', 'label': '📄 Scanner', 'color': Color(0xFF607D8B)},
    {'id': 'landmark', 'label': '🏛️ Monuments', 'color': Colors.green},
  ];
  
  // Filtres par type de jeu (pour les jeux)
  final List<Map<String, dynamic>> _gameFilters = [
    {'id': 'all_games', 'label': '🎮 Tous les jeux', 'color': Color(0xFF6C63FF)},
    {'id': 'emotion_game', 'label': '😊 Émotions', 'color': Colors.orange},
    {'id': 'show_object_game', 'label': '🎯 Montre l\'objet', 'color': Colors.green},
    {'id': 'guess_game', 'label': '🎭 Devine l\'objet', 'color': Color(0xFF6C63FF)},
    {'id': 'category_game', 'label': '📦 Catégories', 'color': Colors.purple},
    {'id': 'drawing_game', 'label': '🎨 Dessin', 'color': Color(0xFFE91E63)},
    {'id': 'rhythm_game', 'label': '🕺 Rythme', 'color': Color(0xFF3F51B5)},
    {'id': 'translation_flash', 'label': '🌍 Traduction Flash', 'color': Colors.blue},
    {'id': 'language_mystery', 'label': '🔮 Langue Mystère', 'color': Colors.teal},
    {'id': 'food_learning', 'label': '🍎 Fruits/Légumes', 'color': Color(0xFFFF9800)},
    {'id': 'color_learning', 'label': '🎨 Polyglot Colors', 'color': Color(0xFF9C27B0)},
    {'id': 'polyglot_animal_mlkit', 'label': '🤖 Animal AI', 'color': Colors.cyanAccent},
  ];
  
  // Labels par type
  final Map<String, String> _typeLabels = {
    'alphabet': '🔤 Alphabet Magique',
    'numbers': '🔢 Chiffres et Nombres',
    'colors': '🎨 Couleurs du Monde',
    'shapes': '📐 Formes Géométriques',
    'lecture': '📖 Lecture Interactive',
    'speech': '🎙️ Dictée Magique',
    'animal_writing': '✏️ Écriture Créative',
    'emotion_game': '😊 Devine l\'Émotion',
    'show_object_game': '🎯 Montre-moi l\'objet',
    'guess_game': '🎭 Devine ce que je vois',
    'category_game': '📦 Jeu des Catégories',
    'drawing_game': '🎨 Dessine et Détecte',
    'rhythm_game': '🕺 Le Bon Rythme',
    'translation_flash': '🌍 Traduction Flash',
    'language_mystery': '🔮 Langue Mystère',
    'food_learning': '🍎 Fruits & Légumes',
    'color_learning': '🎨 Polyglot Colors',
    'polyglot_animal_mlkit': '🤖 Animal Explorer AI',
    'landmark': '🏛️ Monument',
    'flashcard': '🃏 Cartes Mémoire',
    'document_scanner': '📄 Scanner Intelligent',
    'grammar_analysis': '📝 Grammaire en Folie',
    'entity_extraction': '🔍 Extraction d\'Entités',
  };
  
  // Icônes par type
  final Map<String, IconData> _typeIcons = {
    'alphabet': Icons.abc,
    'numbers': Icons.numbers,
    'colors': Icons.color_lens,
    'shapes': Icons.crop_square,
    'lecture': Icons.book,
    'speech': Icons.mic,
    'animal_writing': Icons.edit,
    'emotion_game': Icons.emoji_emotions,
    'show_object_game': Icons.search,
    'guess_game': Icons.quiz,
    'category_game': Icons.category,
    'drawing_game': Icons.brush,
    'rhythm_game': Icons.fitness_center,
    'translation_flash': Icons.translate,
    'language_mystery': Icons.language,
    'food_learning': Icons.apple,
    'color_learning': Icons.color_lens,
    'polyglot_animal_mlkit': Icons.camera_alt,
    'landmark': Icons.landscape,
    'flashcard': Icons.camera_alt,
    'document_scanner': Icons.document_scanner,
    'grammar_analysis': Icons.analytics,
    'entity_extraction': Icons.analytics,
  };
  
  // Couleurs par type
  final Map<String, Color> _typeColors = {
    'alphabet': const Color(0xFFE91E63),
    'numbers': const Color(0xFF2196F3),
    'colors': const Color(0xFF9C27B0),
    'shapes': const Color(0xFF4CAF50),
    'lecture': Colors.blue,
    'speech': const Color(0xFF9C27B0),
    'animal_writing': const Color(0xFFFF6B35),
    'emotion_game': Colors.orange,
    'show_object_game': Colors.green,
    'guess_game': const Color(0xFF6C63FF),
    'category_game': Colors.purple,
    'drawing_game': const Color(0xFFE91E63),
    'rhythm_game': const Color(0xFF3F51B5),
    'translation_flash': Colors.blue,
    'language_mystery': Colors.teal,
    'food_learning': const Color(0xFFFF9800),
    'color_learning': const Color(0xFF9C27B0),
    'polyglot_animal_mlkit': Colors.cyanAccent,
    'landmark': Colors.green,
    'flashcard': const Color(0xFF4CAF50),
    'document_scanner': const Color(0xFF607D8B),
    'grammar_analysis': const Color(0xFFFF9800),
    'entity_extraction': const Color(0xFF6C63FF),
  };
  
  @override
  void initState() {
    super.initState();
    _historyService = HistoryFirebaseService();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadThemePreference();
    _loadData();
    _animationController.forward();
  }
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }
  
  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      String? filterType;
      String? filterCategory;
      
      if (_selectedCategory != 'all') {
        filterCategory = _selectedCategory;
      }
      
      if (_selectedFilter != 'all' && _selectedFilter != 'all_activities' && _selectedFilter != 'all_games') {
        filterType = _selectedFilter;
      }
      
      _historyItems = await _historyService.getHistory(
        type: filterType, 
        category: filterCategory,
        limit: 100
      );
      _stats = await _historyService.getStats();
      print('📊 Historique chargé: ${_historyItems.length} éléments');
    } catch (e) {
      setState(() => _error = 'Erreur de chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _shareHistory() async {
    if (_stats == null) return;
    final stats = _stats!;
    
    final shareText = '''
📊 Mon historique EduLearn 📊

📅 Période: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}

🎯 Total actions: ${stats.totalActions}
⭐ Points gagnés: ${stats.totalPoints}
📅 Cette semaine: ${stats.last7Days} actions
📆 Ce mois: ${stats.thisMonth} actions
🏆 Meilleur jour: ${stats.bestDay} points

📚 ACTIVITÉS D'APPRENTISSAGE
   • Nombre: ${stats.totalActivities}
   • Points: ${stats.activityPoints} pts
   • Détail: Alphabet, Nombres, Couleurs, Formes, Lecture, Dictée, Écriture, Grammaire, etc.

🎮 JEUX ÉDUCATIFS
   • Nombre: ${stats.totalGames}
   • Points: ${stats.gamePoints} pts
   • Détail: Émotions, Devine l'objet, Dessin, Rythme, Traduction, Langues, etc.

Continue à apprendre en t'amusant avec EduLearn ! 🎉
    ''';
    
    await Share.share(shareText);
  }
  
  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vider l\'historique'),
        content: const Text('Cette action est irréversible. Voulez-vous vraiment vider tout votre historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _historyService.clearHistory();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Historique vidé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_stats != null) _buildStatsOverview(),
          _buildCategoryTabs(),
          _buildSubFilters(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _historyItems.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallDevice = screenWidth < 400;
  
  return AppBar(
    titleSpacing: 0,
    toolbarHeight: 56,
    title: LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isSmallDevice ? 'Historique' : 'Mon Historique',
                style: GoogleFonts.poppins(
                  fontSize: isSmallDevice ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        );
      },
    ),
    backgroundColor: const Color(0xFF6C63FF),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Navigator.pop(context),
      padding: const EdgeInsets.all(8),
    ),
    actions: [
      // Réduire le nombre d'actions sur petits écrans
      if (!isSmallDevice)
        IconButton(
          icon: const Icon(Icons.share, size: 20),
          onPressed: _shareHistory,
          tooltip: 'Partager',
          padding: const EdgeInsets.all(8),
        ),
      IconButton(
        icon: const Icon(Icons.delete_sweep, size: 20),
        onPressed: _clearHistory,
        tooltip: 'Vider',
        padding: const EdgeInsets.all(8),
      ),
      IconButton(
        icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 20),
        onPressed: _toggleTheme,
        tooltip: _isDarkMode ? 'Mode clair' : 'Mode sombre',
        padding: const EdgeInsets.all(8),
      ),
      const SizedBox(width: 4),
    ],
  );
}
  
  Widget _buildStatsOverview() {
    final stats = _stats!;
    
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats.totalActions.toString(), Icons.toc),
              _buildStatItem('Points', stats.totalPoints.toString(), Icons.stars),
              _buildStatItem('Série', stats.last7Days.toString(), Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('📚 Activités', stats.totalActivities.toString(), Icons.school, small: true),
              _buildStatItem('🎮 Jeux', stats.totalGames.toString(), Icons.sports_esports, small: true),
              _buildStatItem('⭐ Points Act.', stats.activityPoints.toString(), Icons.star, small: true),
              _buildStatItem('🎯 Points Jeux', stats.gamePoints.toString(), Icons.emoji_events, small: true),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, {bool small = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: small ? 18 : 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: small ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: small ? 9 : 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _categoryFilters.map((filter) {
          final isSelected = _selectedCategory == filter['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = filter['id'] as String;
                  _selectedFilter = 'all';
                });
                _loadData();
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? (filter['color'] as Color).withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 18,
                      color: isSelected ? filter['color'] as Color : (_isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? filter['color'] as Color : (_isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildSubFilters() {
    final filters = _selectedCategory == 'activity' ? _activityFilters : 
                    (_selectedCategory == 'game' ? _gameFilters : 
                    [{'id': 'all', 'label': '📊 Tous', 'color': Colors.grey}]);
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['id'] as String);
                  _loadData();
                  HapticFeedback.lightImpact();
                }
              },
              backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              selectedColor: (filter['color'] as Color).withOpacity(0.2),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? filter['color'] as Color : (_isDarkMode ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF6C63FF),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyItems.length,
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDetailDialog(item),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Badge de catégorie
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_getTypeColor(item.type), _getTypeColor(item.type).withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(_getTypeIcon(item.type), color: Colors.white, size: 28),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: item.category == 'activity' ? Colors.green : const Color(0xFF6C63FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.category == 'activity' ? Icons.school : Icons.sports_esports,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.category == 'activity' ? Colors.green.withOpacity(0.2) : const Color(0xFF6C63FF).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.category == 'activity' ? '📚 Activité' : '🎮 Jeu',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: item.category == 'activity' ? Colors.green : const Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(item.timestamp),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '+${item.points} pts',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showDetailDialog(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.category == 'activity' ? Colors.green.withOpacity(0.2) : const Color(0xFF6C63FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.category == 'activity' ? Icons.school : Icons.sports_esports,
                          size: 16,
                          color: item.category == 'activity' ? Colors.green : const Color(0xFF6C63FF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.category == 'activity' ? 'Activité d\'apprentissage' : 'Jeu éducatif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.category == 'activity' ? Colors.green : const Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.timestamp, withTime: true),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareItem(item),
                          icon: const Icon(Icons.share),
                          label: const Text('Partager'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteItem(item),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
    );
  }
  
  Future<void> _shareItem(HistoryItem item) async {
    final shareText = '''
🎉 Découverte EduLearn ! 🎉

📌 ${item.title}
📍 ${item.subtitle}
📅 ${_formatDate(item.timestamp, withTime: true)}
⭐ Points: +${item.points}
🏷️ ${item.category == 'activity' ? 'Activité d\'apprentissage' : 'Jeu éducatif'}

Continue à explorer avec EduLearn ! 🌟
    ''';
    
    await Share.share(shareText);
  }
  
  Future<void> _deleteItem(HistoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${item.title}" de l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _historyService.deleteHistoryItem(item.id);
        await _loadData();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Élément supprimé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 16),
          Text('Chargement de l\'historique...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Une erreur est survenue',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: _isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun historique',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à jouer pour voir\nvos activités et jeux ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getTypeColor(String type) {
    return _typeColors[type] ?? Colors.grey;
  }
  
  IconData _getTypeIcon(String type) {
    return _typeIcons[type] ?? Icons.history;
  }
  
  String _formatDate(DateTime date, {bool withTime = false}) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return withTime
          ? DateFormat('dd/MM/yyyy à HH:mm').format(date)
          : DateFormat('dd/MM/yyyy').format(date);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}