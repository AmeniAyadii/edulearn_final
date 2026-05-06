import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_history.dart';

class WordHistoryService {
  static final WordHistoryService _instance = WordHistoryService._internal();
  static Database? _database;

  WordHistoryService._internal();

  factory WordHistoryService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'word_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        points INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        definition TEXT,
        translation TEXT,
        isFavorite INTEGER DEFAULT 0
      )
    ''');
  }

  // Ajouter un mot
  Future<int> addWord(WordHistory word) async {
    final db = await database;
    return await db.insert('words', word.toMap());
  }

  // Ajouter un mot simple
  Future<int> addWordSimple(String word, int points) async {
    final db = await database;
    final wordHistory = WordHistory(
      id: 0,
      word: word,
      points: points,
      timestamp: DateTime.now(),
    );
    return await db.insert('words', wordHistory.toMap());
  }

  // Récupérer tous les mots
  Future<List<WordHistory>> getAllWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WordHistory.fromMap(maps[i]));
  }

  // Récupérer les favoris
  Future<List<WordHistory>> getFavoriteWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WordHistory.fromMap(maps[i]));
  }

  // Basculer favori
  Future<void> toggleFavorite(int id) async {
    final db = await database;
    final word = await getWordById(id);
    if (word != null) {
      await db.update(
        'words',
        {'isFavorite': word.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Récupérer un mot par ID
  Future<WordHistory?> getWordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return WordHistory.fromMap(maps.first);
    }
    return null;
  }

  // Supprimer un mot
  Future<int> deleteWord(int id) async {
    final db = await database;
    return await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  // Effacer tout l'historique
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('words');
  }

  // Récupérer le total des points
  Future<int> getTotalPoints() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(points) as total FROM words');
    final sum = result.first['total'];
    return sum != null ? sum as int : 0;
  }

  // Récupérer le nombre total de mots
  Future<int> getTotalWordsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int? ?? 0;
  }

  // Ajouter des mots de test
  Future<void> addTestWords() async {
    await clearAllHistory();

    final testWords = [
      {'word': 'Pomme', 'points': 10, 'definition': 'Fruit comestible', 'translation': 'Apple'},
      {'word': 'Chat', 'points': 15, 'definition': 'Animal domestique', 'translation': 'Cat'},
      {'word': 'Maison', 'points': 12, 'definition': 'Lieu d\'habitation', 'translation': 'House'},
      {'word': 'École', 'points': 18, 'definition': 'Lieu d\'apprentissage', 'translation': 'School'},
      {'word': 'Livre', 'points': 8, 'definition': 'Ensemble de pages reliées', 'translation': 'Book'},
    ];

    for (var word in testWords) {
      final wordHistory = WordHistory(
        id: 0,
        word: word['word'] as String,
        points: word['points'] as int,
        timestamp: DateTime.now().subtract(Duration(days: testWords.indexOf(word))),
        definition: word['definition'] as String,
        translation: word['translation'] as String,
      );
      await addWord(wordHistory);
    }
  }
}