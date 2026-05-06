// lib/models/translation_word.dart
class TranslationWord {
  final String id;
  final String word;
  final String translation;
  final String languageFrom;
  final String languageTo;
  final String emoji;
  final int difficulty;
  final int basePoints;
  final String series;      // Nouveau : série (ex: "Série 1", "Série 2")
  final String category;    // Nouveau : catégorie (ex: "Animaux", "Nourriture")
  final List<String> tags;  // Tags pour recherche

  TranslationWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.languageFrom,
    required this.languageTo,
    required this.emoji,
    required this.difficulty,
    required this.basePoints,
    required this.series,
    required this.category,
    this.tags = const [],
  });

  // Toutes les catégories disponibles
  static List<String> getCategories() {
    return [
      'Animaux', 'Nourriture', 'Famille', 'École', 'Maison', 
      'Vêtements', 'Couleurs', 'Sports', 'Voyages', 'Nature',
      'Métiers', 'Transports', 'Corps humain', 'Temps', 'Émotions',
      'Nombres', 'Formes', 'Musique', 'Technologie', 'Météo'
    ];
  }

  // Toutes les séries disponibles
  static List<String> getSeriesList() {
    return ['Série 1', 'Série 2', 'Série 3', 'Série 4', 'Série 5'];
  }

  // ==================== SÉRIE 1 - ANIMAUX ====================
  static List<TranslationWord> getSerie1Animals() {
    return [
      TranslationWord(
        id: 'cat', word: 'Chat', translation: 'Cat', emoji: '🐱',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Animaux', tags: ['animal', 'félin', 'domestique'],
      ),
      TranslationWord(
        id: 'dog', word: 'Chien', translation: 'Dog', emoji: '🐶',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Animaux', tags: ['animal', 'canin'],
      ),
      TranslationWord(
        id: 'bird', word: 'Oiseau', translation: 'Bird', emoji: '🐦',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Animaux', tags: ['animal', 'vol'],
      ),
      TranslationWord(
        id: 'fish', word: 'Poisson', translation: 'Fish', emoji: '🐟',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Animaux', tags: ['animal', 'aquatique'],
      ),
      TranslationWord(
        id: 'rabbit', word: 'Lapin', translation: 'Rabbit', emoji: '🐰',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Animaux', tags: ['animal', 'poilu'],
      ),
    ];
  }

  // ==================== SÉRIE 1 - NOURRITURE ====================
  static List<TranslationWord> getSerie1Food() {
    return [
      TranslationWord(
        id: 'apple', word: 'Pomme', translation: 'Apple', emoji: '🍎',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Nourriture', tags: ['fruit', 'rouge'],
      ),
      TranslationWord(
        id: 'banana', word: 'Banane', translation: 'Banana', emoji: '🍌',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Nourriture', tags: ['fruit', 'jaune'],
      ),
      TranslationWord(
        id: 'orange', word: 'Orange', translation: 'Orange', emoji: '🍊',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Nourriture', tags: ['fruit', 'agrume'],
      ),
      TranslationWord(
        id: 'strawberry', word: 'Fraise', translation: 'Strawberry', emoji: '🍓',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Nourriture', tags: ['fruit', 'rouge'],
      ),
      TranslationWord(
        id: 'grapes', word: 'Raisin', translation: 'Grapes', emoji: '🍇',
        languageFrom: 'fr', languageTo: 'en', difficulty: 1, basePoints: 10,
        series: 'Série 1', category: 'Nourriture', tags: ['fruit', 'violet'],
      ),
    ];
  }

  // ==================== SÉRIE 2 - FAMILLE ====================
  static List<TranslationWord> getSerie2Family() {
    return [
      TranslationWord(
        id: 'mother', word: 'Mère', translation: 'Mother', emoji: '👩',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['parent', 'femme'],
      ),
      TranslationWord(
        id: 'father', word: 'Père', translation: 'Father', emoji: '👨',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['parent', 'homme'],
      ),
      TranslationWord(
        id: 'brother', word: 'Frère', translation: 'Brother', emoji: '👦',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['frère'],
      ),
      TranslationWord(
        id: 'sister', word: 'Sœur', translation: 'Sister', emoji: '👧',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['sœur'],
      ),
      TranslationWord(
        id: 'grandfather', word: 'Grand-père', translation: 'Grandfather', emoji: '👴',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['grand-parent'],
      ),
      TranslationWord(
        id: 'grandmother', word: 'Grand-mère', translation: 'Grandmother', emoji: '👵',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'Famille', tags: ['grand-parent'],
      ),
    ];
  }

  // ==================== SÉRIE 2 - ÉCOLE ====================
  static List<TranslationWord> getSerie2School() {
    return [
      TranslationWord(
        id: 'school', word: 'École', translation: 'School', emoji: '🏫',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'École', tags: ['éducation'],
      ),
      TranslationWord(
        id: 'teacher', word: 'Professeur', translation: 'Teacher', emoji: '👩‍🏫',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'École', tags: ['professeur'],
      ),
      TranslationWord(
        id: 'student', word: 'Élève', translation: 'Student', emoji: '🧑‍🎓',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'École', tags: ['étudiant'],
      ),
      TranslationWord(
        id: 'book', word: 'Livre', translation: 'Book', emoji: '📚',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'École', tags: ['lecture'],
      ),
      TranslationWord(
        id: 'pen', word: 'Stylo', translation: 'Pen', emoji: '✒️',
        languageFrom: 'fr', languageTo: 'en', difficulty: 2, basePoints: 15,
        series: 'Série 2', category: 'École', tags: ['écriture'],
      ),
    ];
  }

  // ==================== SÉRIE 3 - COULEURS ====================
  static List<TranslationWord> getSerie3Colors() {
    return [
      TranslationWord(
        id: 'red', word: 'Rouge', translation: 'Red', emoji: '🔴',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Couleurs', tags: ['couleur'],
      ),
      TranslationWord(
        id: 'blue', word: 'Bleu', translation: 'Blue', emoji: '🔵',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Couleurs', tags: ['couleur'],
      ),
      TranslationWord(
        id: 'green', word: 'Vert', translation: 'Green', emoji: '🟢',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Couleurs', tags: ['couleur'],
      ),
      TranslationWord(
        id: 'yellow', word: 'Jaune', translation: 'Yellow', emoji: '🟡',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Couleurs', tags: ['couleur'],
      ),
      TranslationWord(
        id: 'pink', word: 'Rose', translation: 'Pink', emoji: '💗',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Couleurs', tags: ['couleur'],
      ),
    ];
  }

  // ==================== SÉRIE 3 - MAISON ====================
  static List<TranslationWord> getSerie3Home() {
    return [
      TranslationWord(
        id: 'house', word: 'Maison', translation: 'House', emoji: '🏠',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Maison', tags: ['habitation'],
      ),
      TranslationWord(
        id: 'room', word: 'Chambre', translation: 'Room', emoji: '🛏️',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Maison', tags: ['pièce'],
      ),
      TranslationWord(
        id: 'kitchen', word: 'Cuisine', translation: 'Kitchen', emoji: '🍳',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Maison', tags: ['pièce'],
      ),
      TranslationWord(
        id: 'bathroom', word: 'Salle de bain', translation: 'Bathroom', emoji: '🛁',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Maison', tags: ['pièce'],
      ),
      TranslationWord(
        id: 'garden', word: 'Jardin', translation: 'Garden', emoji: '🌻',
        languageFrom: 'fr', languageTo: 'en', difficulty: 3, basePoints: 20,
        series: 'Série 3', category: 'Maison', tags: ['extérieur'],
      ),
    ];
  }

  // ==================== SÉRIE 4 - VÊTEMENTS ====================
  static List<TranslationWord> getSerie4Clothes() {
    return [
      TranslationWord(
        id: 'shirt', word: 'Chemise', translation: 'Shirt', emoji: '👔',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Vêtements', tags: ['haut'],
      ),
      TranslationWord(
        id: 'pants', word: 'Pantalon', translation: 'Pants', emoji: '👖',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Vêtements', tags: ['bas'],
      ),
      TranslationWord(
        id: 'shoes', word: 'Chaussures', translation: 'Shoes', emoji: '👟',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Vêtements', tags: ['pieds'],
      ),
      TranslationWord(
        id: 'hat', word: 'Chapeau', translation: 'Hat', emoji: '🧢',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Vêtements', tags: ['tête'],
      ),
      TranslationWord(
        id: 'dress', word: 'Robe', translation: 'Dress', emoji: '👗',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Vêtements', tags: ['femme'],
      ),
    ];
  }

  // ==================== SÉRIE 4 - SPORTS ====================
  static List<TranslationWord> getSerie4Sports() {
    return [
      TranslationWord(
        id: 'football', word: 'Football', translation: 'Football/Soccer', emoji: '⚽',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Sports', tags: ['sport', 'ballon'],
      ),
      TranslationWord(
        id: 'basketball', word: 'Basketball', translation: 'Basketball', emoji: '🏀',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Sports', tags: ['sport', 'ballon'],
      ),
      TranslationWord(
        id: 'tennis', word: 'Tennis', translation: 'Tennis', emoji: '🎾',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Sports', tags: ['sport', 'raquette'],
      ),
      TranslationWord(
        id: 'swimming', word: 'Natation', translation: 'Swimming', emoji: '🏊',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Sports', tags: ['sport', 'eau'],
      ),
      TranslationWord(
        id: 'running', word: 'Course', translation: 'Running', emoji: '🏃',
        languageFrom: 'fr', languageTo: 'en', difficulty: 4, basePoints: 25,
        series: 'Série 4', category: 'Sports', tags: ['sport', 'course'],
      ),
    ];
  }

  // ==================== SÉRIE 5 - EXPRESSIONS ====================
  static List<TranslationWord> getSerie5Expressions() {
    return [
      TranslationWord(
        id: 'hello', word: 'Bonjour', translation: 'Hello', emoji: '👋',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Expressions', tags: ['salutation'],
      ),
      TranslationWord(
        id: 'goodbye', word: 'Au revoir', translation: 'Goodbye', emoji: '👋',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Expressions', tags: ['au revoir'],
      ),
      TranslationWord(
        id: 'thank_you', word: 'Merci', translation: 'Thank you', emoji: '🙏',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Expressions', tags: ['remerciement'],
      ),
      TranslationWord(
        id: 'sorry', word: 'Désolé', translation: 'Sorry', emoji: '😔',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Expressions', tags: ['excuse'],
      ),
      TranslationWord(
        id: 'please', word: 'S\'il vous plaît', translation: 'Please', emoji: '🙏',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Expressions', tags: ['politesse'],
      ),
    ];
  }

  // ==================== SÉRIE 5 - ÉMOTIONS ====================
  static List<TranslationWord> getSerie5Emotions() {
    return [
      TranslationWord(
        id: 'happy', word: 'Heureux', translation: 'Happy', emoji: '😊',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Émotions', tags: ['sentiment'],
      ),
      TranslationWord(
        id: 'sad', word: 'Triste', translation: 'Sad', emoji: '😢',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Émotions', tags: ['sentiment'],
      ),
      TranslationWord(
        id: 'angry', word: 'En colère', translation: 'Angry', emoji: '😠',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Émotions', tags: ['sentiment'],
      ),
      TranslationWord(
        id: 'scared', word: 'Peur', translation: 'Scared', emoji: '😨',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Émotions', tags: ['sentiment'],
      ),
      TranslationWord(
        id: 'surprised', word: 'Surpris', translation: 'Surprised', emoji: '😮',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 5', category: 'Émotions', tags: ['sentiment'],
      ),
    ];
  }

  // ==================== SERVER PLUS (Voyages, Nature, Technologie, etc.) ====================
  static List<TranslationWord> getSerie6Travel() {
    return [
      TranslationWord(
        id: 'airport', word: 'Aéroport', translation: 'Airport', emoji: '✈️',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 6', category: 'Voyages', tags: ['transport'],
      ),
      TranslationWord(
        id: 'hotel', word: 'Hôtel', translation: 'Hotel', emoji: '🏨',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 6', category: 'Voyages', tags: ['hébergement'],
      ),
      TranslationWord(
        id: 'passport', word: 'Passeport', translation: 'Passport', emoji: '📘',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 6', category: 'Voyages', tags: ['document'],
      ),
      TranslationWord(
        id: 'suitcase', word: 'Valise', translation: 'Suitcase', emoji: '🧳',
        languageFrom: 'fr', languageTo: 'en', difficulty: 5, basePoints: 30,
        series: 'Série 6', category: 'Voyages', tags: ['bagage'],
      ),
    ];
  }

  // Récupérer tous les mots
  static List<TranslationWord> getAllWords() {
    return [
      ...getSerie1Animals(),
      ...getSerie1Food(),
      ...getSerie2Family(),
      ...getSerie2School(),
      ...getSerie3Colors(),
      ...getSerie3Home(),
      ...getSerie4Clothes(),
      ...getSerie4Sports(),
      ...getSerie5Expressions(),
      ...getSerie5Emotions(),
      ...getSerie6Travel(),
    ];
  }

  // Récupérer les mots par série
  static List<TranslationWord> getWordsBySeries(String series) {
    return getAllWords().where((w) => w.series == series).toList();
  }

  // Récupérer les mots par catégorie
  static List<TranslationWord> getWordsByCategory(String category) {
    return getAllWords().where((w) => w.category == category).toList();
  }

  // Récupérer les mots par difficulté
  static List<TranslationWord> getWordsByDifficulty(int difficulty) {
    return getAllWords().where((w) => w.difficulty == difficulty).toList();
  }

  // Récupérer les mots par série et catégorie
  static List<TranslationWord> getWordsBySeriesAndCategory(String series, String category) {
    return getAllWords().where((w) => w.series == series && w.category == category).toList();
  }

  // Récupérer les mots par tag
  static List<TranslationWord> getWordsByTag(String tag) {
    return getAllWords().where((w) => w.tags.contains(tag)).toList();
  }

  // Statistiques
  static Map<String, dynamic> getStatistics() {
    final words = getAllWords();
    return {
      'totalWords': words.length,
      'totalSeries': getSeriesList().length,
      'totalCategories': getCategories().length,
      'wordsBySeries': getSeriesList().map((s) => {
        'series': s,
        'count': getWordsBySeries(s).length,
      }).toList(),
      'wordsByCategory': getCategories().map((c) => {
        'category': c,
        'count': getWordsByCategory(c).length,
      }).toList(),
    };
  }
}