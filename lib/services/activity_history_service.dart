import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity_model.dart';

class ActivityHistoryService {
  static final ActivityHistoryService _instance = ActivityHistoryService._internal();
  static Database? _database;

  ActivityHistoryService._internal();

  factory ActivityHistoryService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'activity_history.db');
    return await openDatabase(
      path,
      version: 2, // Incrémenter la version pour ajouter childName
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities(
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        childName TEXT NOT NULL,
        activityType TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        points INTEGER DEFAULT 0,
        duration INTEGER DEFAULT 0,
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN childName TEXT DEFAULT "Enfant"');
        print('✅ Colonne childName ajoutée');
      } catch (e) {
        print('⚠️ Erreur lors de l\'ajout de childName: $e');
      }
    }
  }

  // Ajouter une activité
  Future<void> addActivity(ActivityModel activity) async {
    final db = await database;
    await db.insert('activities', activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Ajouter une activité simple (VERSION ORIGINALE CONSERVÉE)
  Future<void> addActivitySimple({
    required String childId,
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
      childName: 'Enfant', // Valeur par défaut
      activityType: activityType,
      title: title,
      description: description,
      points: points,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    await addActivity(activity);
  }

  // NOUVELLE MÉTHODE: Ajouter une activité simple avec childName
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
    await addActivity(activity);
  }

  // Récupérer toutes les activités
  Future<List<ActivityModel>> getAllActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  // Récupérer les activités par enfant
  Future<List<ActivityModel>> getActivitiesByChild(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'childId = ?',
      whereArgs: [childId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  // Récupérer les activités par type
  Future<List<ActivityModel>> getActivitiesByType(String activityType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'activityType = ?',
      whereArgs: [activityType],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  // Récupérer les activités par date
  Future<List<ActivityModel>> getActivitiesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ActivityModel.fromMap(maps[i]));
  }

  // Supprimer une activité
  Future<void> deleteActivity(String id) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  // Supprimer les activités d'un enfant
  Future<void> deleteActivitiesByChild(String childId) async {
    final db = await database;
    await db.delete('activities', where: 'childId = ?', whereArgs: [childId]);
  }

  // Effacer tout l'historique
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('activities');
  }

  // Récupérer le total des points
  Future<int> getTotalPoints(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(points) as total FROM activities WHERE childId = ?',
      [childId],
    );
    final sum = result.first['total'];
    return sum != null ? sum as int : 0;
  }

  // Récupérer le nombre total d'activités
  Future<int> getTotalActivitiesCount(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM activities WHERE childId = ?',
      [childId],
    );
    return result.first['count'] as int? ?? 0;
  }

  // Récupérer les statistiques par type d'activité
  Future<Map<String, int>> getStatsByType(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT activityType, COUNT(*) as count FROM activities WHERE childId = ? GROUP BY activityType',
      [childId],
    );
    
    final stats = <String, int>{};
    for (var row in result) {
      final activityType = row['activityType'] as String;
      final count = row['count'] as int;
      stats[activityType] = count;
    }
    return stats;
  }

  // Récupérer les statistiques par enfant
  Future<List<Map<String, dynamic>>> getStatsByChild() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        childId, 
        childName, 
        COUNT(*) as totalActivities, 
        SUM(points) as totalPoints 
      FROM activities 
      GROUP BY childId, childName 
      ORDER BY totalPoints DESC
    ''');
    
    return result.map((row) => {
      'childId': row['childId'],
      'childName': row['childName'] ?? 'Enfant',
      'totalActivities': row['totalActivities'] as int,
      'totalPoints': row['totalPoints'] as int? ?? 0,
    }).toList();
  }

  // Vérifier si la base de données est vide
  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM activities');
    final count = result.first['count'] as int? ?? 0;
    return count == 0;
  }

  // Ajouter des activités de test (VERSION ORIGINALE CONSERVÉE)
  Future<void> addTestActivities(String childId) async {
    await clearAllHistory();
    
    final testActivities = [
      {
        'type': 'scan_word',
        'title': 'Mot scanné: Pomme',
        'description': 'Vous avez scanné le mot "Pomme" avec succès.',
        'points': 10,
      },
      {
        'type': 'scan_word',
        'title': 'Mot scanné: Chat',
        'description': 'Vous avez scanné le mot "Chat" avec succès.',
        'points': 15,
      },
      {
        'type': 'recognition',
        'title': 'Reconnaissance d\'image',
        'description': 'Vous avez reconnu un chat dans l\'image.',
        'points': 20,
      },
      {
        'type': 'document_scan',
        'title': 'Document scanné',
        'description': 'Vous avez scanné un document éducatif.',
        'points': 25,
      },
      {
        'type': 'dictation',
        'title': 'Dictée: Maison',
        'description': 'Vous avez écrit correctement le mot "Maison".',
        'points': 12,
      },
      {
        'type': 'quiz',
        'title': 'Quiz: Les animaux',
        'description': 'Vous avez répondu correctement à 8/10 questions.',
        'points': 30,
      },
      {
        'type': 'translation',
        'title': 'Traduction: Hello',
        'description': 'Vous avez traduit "Hello" en "Bonjour".',
        'points': 8,
      },
    ];
    
    for (var i = 0; i < testActivities.length; i++) {
      final activity = testActivities[i];
      await addActivitySimple(
        childId: childId,
        activityType: activity['type'] as String,
        title: activity['title'] as String,
        description: activity['description'] as String,
        points: activity['points'] as int,
        duration: 5 + i,
      );
    }
  }

  // NOUVELLE MÉTHODE: Ajouter des activités de test avec nom d'enfant
  Future<void> addTestActivitiesWithName(String childId, String childName) async {
    final testActivities = [
      {
        'type': 'scan_word',
        'title': 'Mot scanné: Pomme',
        'description': '$childName a scanné le mot "Pomme" avec succès.',
        'points': 10,
      },
      {
        'type': 'scan_word',
        'title': 'Mot scanné: Chat',
        'description': '$childName a scanné le mot "Chat" avec succès.',
        'points': 15,
      },
      {
        'type': 'recognition',
        'title': 'Reconnaissance d\'image',
        'description': '$childName a reconnu un chat dans l\'image.',
        'points': 20,
      },
      {
        'type': 'document_scan',
        'title': 'Document scanné',
        'description': '$childName a scanné un document éducatif.',
        'points': 25,
      },
      {
        'type': 'dictation',
        'title': 'Dictée: Maison',
        'description': '$childName a écrit correctement le mot "Maison".',
        'points': 12,
      },
      {
        'type': 'quiz',
        'title': 'Quiz: Les animaux',
        'description': '$childName a répondu correctement à 8/10 questions.',
        'points': 30,
      },
      {
        'type': 'translation',
        'title': 'Traduction: Hello',
        'description': '$childName a traduit "Hello" en "Bonjour".',
        'points': 8,
      },
    ];
    
    for (var i = 0; i < testActivities.length; i++) {
      final activity = testActivities[i];
      await addActivitySimpleWithName(
        childId: childId,
        childName: childName,
        activityType: activity['type'] as String,
        title: activity['title'] as String,
        description: activity['description'] as String,
        points: activity['points'] as int,
        duration: 5 + i,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('✅ ${testActivities.length} activités de test ajoutées pour $childName');
  }
}