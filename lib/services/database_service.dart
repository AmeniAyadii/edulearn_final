import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'edulearn.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> debugPrintWords() async {
  final words = await getAllWords();
  print('=== MOTS DANS LA BASE ===');
  print('Nombre de mots: ${words.length}');
  for (var word in words) {
    print('- ${word.text} (+${word.points} pts)');
  }
  print('==========================');
}

// Supprimer et recréer la base de données
Future<void> resetDatabase() async {
  final dbPath = join(await getDatabasesPath(), 'edulearn.db');
  await deleteDatabase(dbPath);
  _database = null;
  await database; // Recréer la base
}

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        points INTEGER DEFAULT 10
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // Migrations futures
    }
  }

  // Ajouter un mot
  Future<int> addWord(WordModel word) async {
    Database db = await database;
    return await db.insert('words', word.toMap());
  }

  // Ajouter un mot directement avec texte et points
  Future<int> addWordSimple(String text, int points) async {
    Database db = await database;
    final word = WordModel(
      text: text,
      points: points,
      timestamp: DateTime.now().toIso8601String(),
    );
    return await db.insert('words', word.toMap());
  }

  // Récupérer tous les mots
  Future<List<WordModel>> getAllWords() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'words',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WordModel.fromMap(maps[i]));
  }

  // Récupérer les mots par date (aujourd'hui)
  Future<List<WordModel>> getTodayWords() async {
    Database db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WordModel.fromMap(maps[i]));
  }

  // Récupérer les mots par date spécifique
  Future<List<WordModel>> getWordsByDate(DateTime date) async {
    Database db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WordModel.fromMap(maps[i]));
  }

  // Récupérer le total des points
  Future<int> getTotalPoints() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT SUM(points) as total FROM words');
    final total = result.first['total'];
    return total != null ? total as int : 0;
  }

  // Récupérer les points d'aujourd'hui
  Future<int> getTodayPoints() async {
    Database db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(points) as total FROM words WHERE timestamp BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()]
    );
    final total = result.first['total'];
    return total != null ? total as int : 0;
  }

  // Récupérer le nombre total de mots scannés
  Future<int> getTotalWordsCount() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int? ?? 0;
  }

  // Récupérer les statistiques par jour
  Future<Map<String, int>> getStatsByDay(int days) async {
    Database db = await database;
    final result = <String, int>{};
    
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final List<Map<String, dynamic>> queryResult = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(points) as points FROM words WHERE timestamp BETWEEN ? AND ?',
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()]
      );
      
      final dayKey = '${date.day}/${date.month}';
      final count = queryResult.first['count'];
      result[dayKey] = count != null ? count as int : 0;
    }
    
    return result;
  }

  // Supprimer un mot spécifique
  Future<int> deleteWord(int id) async {
    Database db = await database;
    return await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  // Supprimer les mots d'une date spécifique
  Future<int> deleteWordsByDate(DateTime date) async {
    Database db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return await db.delete(
      'words',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()]
    );
  }

  // Effacer tout l'historique
  Future<void> clearHistory() async {
    Database db = await database;
    await db.delete('words');
  }

  // Ajouter des mots de test (pour le développement)
  Future<void> addTestWords() async {
    await clearHistory();
    
    final testWords = [
      {'text': 'Pomme', 'points': 10},
      {'text': 'Chat', 'points': 15},
      {'text': 'Maison', 'points': 12},
      {'text': 'École', 'points': 18},
      {'text': 'Livre', 'points': 8},
      {'text': 'Voiture', 'points': 20},
      {'text': 'Jardin', 'points': 14},
      {'text': 'Famille', 'points': 16},
    ];
    
    for (var word in testWords) {
      await addWordSimple(word['text'] as String, word['points'] as int);
    }
  }

  // Vérifier si la base de données existe
  Future<bool> isDatabaseEmpty() async {
    final count = await getTotalWordsCount();
    return count == 0;
  }

  // Obtenir les statistiques détaillées
  Future<Map<String, dynamic>> getDetailedStats() async {
    Database db = await database;
    
    final totalPoints = await getTotalPoints();
    final totalWords = await getTotalWordsCount();
    final todayPoints = await getTodayPoints();
    final todayWords = await getTodayWords();
    
    // Meilleur mot (celui avec le plus de points)
    final List<Map<String, dynamic>> bestWordResult = await db.query(
      'words',
      orderBy: 'points DESC',
      limit: 1,
    );
    
    String? bestWord;
    int? bestWordPoints;
    if (bestWordResult.isNotEmpty) {
      final firstRow = bestWordResult.first;
      bestWord = firstRow['text'] as String?;
      bestWordPoints = firstRow['points'] as int?;
    }
    
    return {
      'totalPoints': totalPoints,
      'totalWords': totalWords,
      'todayPoints': todayPoints,
      'todayWords': todayWords.length,
      'bestWord': bestWord ?? 'Aucun',
      'bestWordPoints': bestWordPoints ?? 0,
      'averagePoints': totalWords > 0 ? (totalPoints / totalWords).round() : 0,
    };
  }
}