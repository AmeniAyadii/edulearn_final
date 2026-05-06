import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // ============================================================================
  // BASE DE DONNÉES DES QUESTIONS - 45 QUESTIONS
  // ============================================================================
  
  final List<Map<String, dynamic>> _questions = [
    // ==================== NIVEAU 1 - DÉBUTANT (15 questions) ====================
    
    // Animaux (Niveau 1)
    {
      'id': 1,
      'level': 1,
      'category': '🐶 Animaux',
      'question': 'Quel animal fait "Miaou" ?',
      'options': ['Chien', 'Chat', 'Oiseau', 'Poisson'],
      'correctAnswer': 'Chat',
      'explanation': 'Le chat miaule, le chien aboie !',
      'imageIcon': '🐱',
    },
    {
      'id': 2,
      'level': 1,
      'category': '🐶 Animaux',
      'question': 'Quel animal aboie ?',
      'options': ['Chat', 'Vache', 'Chien', 'Cheval'],
      'correctAnswer': 'Chien',
      'explanation': 'Le chien dit "Ouaf ouaf" !',
      'imageIcon': '🐕',
    },
    {
      'id': 3,
      'level': 1,
      'category': '🐶 Animaux',
      'question': 'Quel animal a une longue cou ?',
      'options': ['Éléphant', 'Girafe', 'Lion', 'Zèbre'],
      'correctAnswer': 'Girafe',
      'explanation': 'La girafe a le cou très long pour manger les feuilles des arbres !',
      'imageIcon': '🦒',
    },
    
    // Fruits (Niveau 1)
    {
      'id': 4,
      'level': 1,
      'category': '🍎 Fruits',
      'question': 'Quel fruit est rouge et rond ?',
      'options': ['Banane', 'Orange', 'Pomme', 'Raisin'],
      'correctAnswer': 'Pomme',
      'explanation': 'La pomme est rouge et délicieuse !',
      'imageIcon': '🍎',
    },
    {
      'id': 5,
      'level': 1,
      'category': '🍎 Fruits',
      'question': 'Quel fruit est jaune et incurvé ?',
      'options': ['Pomme', 'Orange', 'Banane', 'Fraise'],
      'correctAnswer': 'Banane',
      'explanation': 'La banane est jaune et en forme de croissant !',
      'imageIcon': '🍌',
    },
    {
      'id': 6,
      'level': 1,
      'category': '🍎 Fruits',
      'question': 'Quel fruit est orange et rond ?',
      'options': ['Pomme', 'Orange', 'Kiwi', 'Poire'],
      'correctAnswer': 'Orange',
      'explanation': "L'orange est orange et pleine de vitamines !",
      'imageIcon': '🍊',
    },
    
    // Couleurs (Niveau 1)
    {
      'id': 7,
      'level': 1,
      'category': '🎨 Couleurs',
      'question': 'De quelle couleur est le ciel par beau temps ?',
      'options': ['Vert', 'Rouge', 'Bleu', 'Jaune'],
      'correctAnswer': 'Bleu',
      'explanation': 'Le ciel est bleu quand il fait beau !',
      'imageIcon': '🔵',
    },
    {
      'id': 8,
      'level': 1,
      'category': '🎨 Couleurs',
      'question': 'De quelle couleur est l\'herbe ?',
      'options': ['Bleu', 'Vert', 'Rouge', 'Jaune'],
      'correctAnswer': 'Vert',
      'explanation': "L'herbe est verte !",
      'imageIcon': '🟢',
    },
    {
      'id': 9,
      'level': 1,
      'category': '🎨 Couleurs',
      'question': 'De quelle couleur est le soleil ?',
      'options': ['Bleu', 'Vert', 'Rouge', 'Jaune'],
      'correctAnswer': 'Jaune',
      'explanation': 'Le soleil est jaune et brillant !',
      'imageIcon': '🟡',
    },
    
    // Mathématiques (Niveau 1)
    {
      'id': 10,
      'level': 1,
      'category': '🔢 Maths',
      'question': 'Combien font 2 + 2 ?',
      'options': ['3', '4', '5', '6'],
      'correctAnswer': '4',
      'explanation': '2 pommes + 2 pommes = 4 pommes !',
      'imageIcon': '➕',
    },
    {
      'id': 11,
      'level': 1,
      'category': '🔢 Maths',
      'question': 'Combien font 3 + 1 ?',
      'options': ['2', '3', '4', '5'],
      'correctAnswer': '4',
      'explanation': '3 + 1 = 4',
      'imageIcon': '➕',
    },
    {
      'id': 12,
      'level': 1,
      'category': '🔢 Maths',
      'question': 'Combien font 5 - 2 ?',
      'options': ['2', '3', '4', '5'],
      'correctAnswer': '3',
      'explanation': '5 - 2 = 3',
      'imageIcon': '➖',
    },
    
    // Langues (Niveau 1)
    {
      'id': 13,
      'level': 1,
      'category': '🌍 Langues',
      'question': 'Comment dit-on "Merci" en anglais ?',
      'options': ['Hello', 'Goodbye', 'Thank you', 'Please'],
      'correctAnswer': 'Thank you',
      'explanation': 'Thank you veut dire merci en anglais !',
      'imageIcon': '🇬🇧',
    },
    {
      'id': 14,
      'level': 1,
      'category': '🌍 Langues',
      'question': 'Comment dit-on "Bonjour" en anglais ?',
      'options': ['Goodbye', 'Hello', 'Thank you', 'Yes'],
      'correctAnswer': 'Hello',
      'explanation': 'Hello signifie bonjour en anglais !',
      'imageIcon': '🇬🇧',
    },
    {
      'id': 15,
      'level': 1,
      'category': '🌍 Langues',
      'question': 'Comment dit-on "Oui" en anglais ?',
      'options': ['No', 'Yes', 'Ok', 'Good'],
      'correctAnswer': 'Yes',
      'explanation': 'Yes signifie oui en anglais !',
      'imageIcon': '🇬🇧',
    },

    // ==================== NIVEAU 2 - INTERMÉDIAIRE (15 questions) ====================
    
    // Animaux (Niveau 2)
    {
      'id': 16,
      'level': 2,
      'category': '🐶 Animaux',
      'question': 'Quel est le plus grand animal du monde ?',
      'options': ['Éléphant', 'Girafe', 'Baleine', 'Requin'],
      'correctAnswer': 'Baleine',
      'explanation': 'La baleine bleue est le plus grand animal !',
      'imageIcon': '🐋',
    },
    {
      'id': 17,
      'level': 2,
      'category': '🐶 Animaux',
      'question': 'Quel animal est le roi de la jungle ?',
      'options': ['Tigre', 'Lion', 'Éléphant', 'Gorille'],
      'correctAnswer': 'Lion',
      'explanation': 'Le lion est considéré comme le roi de la jungle !',
      'imageIcon': '🦁',
    },
    {
      'id': 18,
      'level': 2,
      'category': '🐶 Animaux',
      'question': 'Quel animal change de couleur pour se camoufler ?',
      'options': ['Caméléon', 'Serpent', 'Grenouille', 'Poisson'],
      'correctAnswer': 'Caméléon',
      'explanation': 'Le caméléon peut changer de couleur pour se camoufler !',
      'imageIcon': '🦎',
    },
    
    // Géographie (Niveau 2)
    {
      'id': 19,
      'level': 2,
      'category': '🌍 Géographie',
      'question': 'Quelle est la capitale de la France ?',
      'options': ['Lyon', 'Marseille', 'Paris', 'Bordeaux'],
      'correctAnswer': 'Paris',
      'explanation': 'Paris est la capitale de la France !',
      'imageIcon': '🇫🇷',
    },
    {
      'id': 20,
      'level': 2,
      'category': '🌍 Géographie',
      'question': 'Quel est le plus haut sommet du monde ?',
      'options': ['Mont Blanc', 'Kilimandjaro', 'Everest', 'Annapurna'],
      'correctAnswer': 'Everest',
      'explanation': "L'Everest est la plus haute montagne du monde !",
      'imageIcon': '🏔️',
    },
    {
      'id': 21,
      'level': 2,
      'category': '🌍 Géographie',
      'question': 'Quel est le plus grand océan du monde ?',
      'options': ['Atlantique', 'Indien', 'Arctique', 'Pacifique'],
      'correctAnswer': 'Pacifique',
      'explanation': "L'océan Pacifique est le plus grand !",
      'imageIcon': '🌊',
    },
    
    // Sciences (Niveau 2)
    {
      'id': 22,
      'level': 2,
      'category': '🔬 Sciences',
      'question': 'Quelle planète est la plus proche du soleil ?',
      'options': ['Vénus', 'Terre', 'Mars', 'Mercure'],
      'correctAnswer': 'Mercure',
      'explanation': 'Mercure est la planète la plus proche du soleil !',
      'imageIcon': '🪐',
    },
    {
      'id': 23,
      'level': 2,
      'category': '🔬 Sciences',
      'question': "Quel est le plus grand organe du corps humain ?",
      'options': ['Cœur', 'Cerveau', 'Peau', 'Foie'],
      'correctAnswer': 'Peau',
      'explanation': 'La peau est le plus grand organe du corps humain !',
      'imageIcon': '🧬',
    },
    {
      'id': 24,
      'level': 2,
      'category': '🔬 Sciences',
      'question': 'Que produit une plante lors de la photosynthèse ?',
      'options': ['Dioxyde de carbone', 'Oxygène', 'Azote', 'Eau'],
      'correctAnswer': 'Oxygène',
      'explanation': 'Les plantes produisent de l\'oxygène !',
      'imageIcon': '🌿',
    },
    
    // Sports (Niveau 2)
    {
      'id': 25,
      'level': 2,
      'category': '⚽ Sports',
      'question': 'Combien de joueurs y a-t-il dans une équipe de football ?',
      'options': ['9', '10', '11', '12'],
      'correctAnswer': '11',
      'explanation': 'Une équipe de football a 11 joueurs !',
      'imageIcon': '⚽',
    },
    {
      'id': 26,
      'level': 2,
      'category': '⚽ Sports',
      'question': 'Quel sport utilise une raquette et un volant ?',
      'options': ['Tennis', 'Badminton', 'Squash', 'Padel'],
      'correctAnswer': 'Badminton',
      'explanation': 'Le badminton se joue avec une raquette et un volant !',
      'imageIcon': '🏸',
    },
    {
      'id': 27,
      'level': 2,
      'category': '⚽ Sports',
      'question': 'Quel est le nom du trophée du tournoi de tennis de Wimbledon ?',
      'options': ['Coupe Davis', 'Trophée des Champions', 'Coupe du Roi', "Coupe du vainqueur"],
      'correctAnswer': 'Coupe du vainqueur',
      'explanation': "Le vainqueur de Wimbledon reçoit la Coupe du vainqueur !",
      'imageIcon': '🎾',
    },
    
    // Arts (Niveau 2)
    {
      'id': 28,
      'level': 2,
      'category': '🎨 Arts',
      'question': 'Qui a peint "La Joconde" ?',
      'options': ['Van Gogh', 'Picasso', 'Léonard de Vinci', 'Monet'],
      'correctAnswer': 'Léonard de Vinci',
      'explanation': 'La Joconde a été peinte par Léonard de Vinci !',
      'imageIcon': '🎨',
    },
    {
      'id': 29,
      'level': 2,
      'category': '🎨 Arts',
      'question': "Quel instrument a 88 touches ?",
      'options': ['Guitare', 'Violon', 'Piano', 'Batterie'],
      'correctAnswer': 'Piano',
      'explanation': 'Un piano standard a 88 touches !',
      'imageIcon': '🎹',
    },
    {
      'id': 30,
      'level': 2,
      'category': '🎨 Arts',
      'question': 'Qui a composé la "Symphonie n°5" ?',
      'options': ['Mozart', 'Beethoven', 'Bach', 'Chopin'],
      'correctAnswer': 'Beethoven',
      'explanation': 'La Symphonie n°5 a été composée par Beethoven !',
      'imageIcon': '🎵',
    },

    // ==================== NIVEAU 3 - AVANCÉ (15 questions) ====================
    
    // Sciences (Niveau 3)
    {
      'id': 31,
      'level': 3,
      'category': '🔬 Sciences',
      'question': 'Quelle est la formule chimique de l\'eau ?',
      'options': ['CO2', 'O2', 'H2O', 'NaCl'],
      'correctAnswer': 'H2O',
      'explanation': "L'eau a pour formule chimique H2O !",
      'imageIcon': '💧',
    },
    {
      'id': 32,
      'level': 3,
      'category': '🔬 Sciences',
      'question': "Qui a découvert la gravité ?",
      'options': ['Einstein', 'Newton', 'Galilée', 'Archimède'],
      'correctAnswer': 'Newton',
      'explanation': 'Isaac Newton a découvert la gravité après avoir vu une pomme tomber !',
      'imageIcon': '🍎',
    },
    {
      'id': 33,
      'level': 3,
      'category': '🔬 Sciences',
      'question': 'Quelle est la vitesse de la lumière ?',
      'options': ['300 000 km/s', '150 000 km/s', '450 000 km/s', '100 000 km/s'],
      'correctAnswer': '300 000 km/s',
      'explanation': 'La lumière se déplace à environ 300 000 km/s !',
      'imageIcon': '💡',
    },
    
    // Histoire (Niveau 3)
    {
      'id': 34,
      'level': 3,
      'category': '📜 Histoire',
      'question': 'En quelle année a eu lieu la Révolution française ?',
      'options': ['1776', '1789', '1799', '1804'],
      'correctAnswer': '1789',
      'explanation': 'La Révolution française a commencé en 1789 !',
      'imageIcon': '🇫🇷',
    },
    {
      'id': 35,
      'level': 3,
      'category': '📜 Histoire',
      'question': 'Qui était le premier empereur de France ?',
      'options': ['Louis XIV', 'Charlemagne', 'Napoléon', "César"],
      'correctAnswer': 'Napoléon',
      'explanation': 'Napoléon Bonaparte a été le premier empereur de France !',
      'imageIcon': '👑',
    },
    {
      'id': 36,
      'level': 3,
      'category': '📜 Histoire',
      'question': "Quel navire a transporté Christophe Colomb vers l'Amérique ?",
      'options': ['Victoria', 'Santa Maria', 'Pinta', 'Mayflower'],
      'correctAnswer': 'Santa Maria',
      'explanation': "Christophe Colomb a traversé l'Atlantique sur la Santa Maria !",
      'imageIcon': '⛵',
    },
    
    // Littérature (Niveau 3)
    {
      'id': 37,
      'level': 3,
      'category': '📚 Littérature',
      'question': 'Qui a écrit "Les Misérables" ?',
      'options': ['Victor Hugo', 'Émile Zola', 'Albert Camus', 'Molière'],
      'correctAnswer': 'Victor Hugo',
      'explanation': 'Les Misérables est un roman de Victor Hugo !',
      'imageIcon': '📖',
    },
    {
      'id': 38,
      'level': 3,
      'category': '📚 Littérature',
      'question': 'Quel est le nom du célèbre détective créé par Arthur Conan Doyle ?',
      'options': ['Hercule Poirot', 'Sherlock Holmes', 'Miss Marple', 'Nero Wolfe'],
      'correctAnswer': 'Sherlock Holmes',
      'explanation': 'Sherlock Holmes est le détective créé par Arthur Conan Doyle !',
      'imageIcon': '🔍',
    },
    {
      'id': 39,
      'level': 3,
      'category': '📚 Littérature',
      'question': 'Qui a écrit "Le Petit Prince" ?',
      'options': ['Saint-Exupéry', 'Jean de La Fontaine', 'Charles Perrault', 'Victor Hugo'],
      'correctAnswer': 'Saint-Exupéry',
      'explanation': 'Le Petit Prince a été écrit par Antoine de Saint-Exupéry !',
      'imageIcon': '👑',
    },
    
    // Musique (Niveau 3)
    {
      'id': 40,
      'level': 3,
      'category': '🎵 Musique',
      'question': 'Quel groupe a chanté "Bohemian Rhapsody" ?',
      'options': ['The Beatles', 'Queen', 'Rolling Stones', 'Pink Floyd'],
      'correctAnswer': 'Queen',
      'explanation': 'Bohemian Rhapsody est une chanson du groupe Queen !',
      'imageIcon': '🎤',
    },
    {
      'id': 41,
      'level': 3,
      'category': '🎵 Musique',
      'question': "Quel instrument est surnommé le 'roi des instruments' ?",
      'options': ['Piano', 'Violon', 'Orgue', 'Guitare'],
      'correctAnswer': 'Orgue',
      'explanation': "L'orgue est souvent surnommé le 'roi des instruments' !",
      'imageIcon': '🎹',
    },
    {
      'id': 42,
      'level': 3,
      'category': '🎵 Musique',
      'question': 'Qui a composé "La Lettre à Élise" ?',
      'options': ['Mozart', 'Beethoven', 'Bach', 'Chopin'],
      'correctAnswer': 'Beethoven',
      'explanation': 'La Lettre à Élise a été composée par Beethoven !',
      'imageIcon': '🎼',
    },
    
    // Animaux (Niveau 3)
    {
      'id': 43,
      'level': 3,
      'category': '🐶 Animaux',
      'question': "Quel animal est connu pour porter des rayures noires et blanches ?",
      'options': ['Zèbre', 'Tigre', 'Panda', 'Léopard'],
      'correctAnswer': 'Zèbre',
      'explanation': 'Le zèbre a des rayures noires et blanches uniques !',
      'imageIcon': '🦓',
    },
    {
      'id': 44,
      'level': 3,
      'category': '🐶 Animaux',
      'question': 'Quel est l\'animal terrestre le plus rapide ?',
      'options': ['Cheval', 'Lion', 'Guépard', 'Lièvre'],
      'correctAnswer': 'Guépard',
      'explanation': 'Le guépard peut courir jusqu\'à 120 km/h !',
      'imageIcon': '🐆',
    },
    {
      'id': 45,
      'level': 3,
      'category': '🐶 Animaux',
      'question': "Quel animal est le symbole de l'Australie ?",
      'options': ['Koala', 'Kangourou', 'Diable de Tasmanie', 'Ornithorynque'],
      'correctAnswer': 'Kangourou',
      'explanation': 'Le kangourou est l\'animal emblématique de l\'Australie !',
      'imageIcon': '🦘',
    },
  ];

  // ============================================================================
  // MÉTHODES
  // ============================================================================

  Future<Map<String, dynamic>> getQuestionsByLevel(int level) async {
    final levelQuestions = _questions.where((q) => q['level'] == level).toList();
    return {
      'questions': levelQuestions,
      'total': levelQuestions.length,
    };
  }

  Future<Map<String, dynamic>> getRandomQuestions(int count) async {
    final shuffled = List.of(_questions)..shuffle(Random());
    final randomQuestions = shuffled.take(count).toList();
    return {
      'questions': randomQuestions,
      'total': randomQuestions.length,
    };
  }

  Future<Map<String, dynamic>> getQuestionsByCategory(String category, int level) async {
    final categoryQuestions = _questions.where((q) => 
      q['category'] == category && q['level'] == level
    ).toList();
    return {
      'questions': categoryQuestions,
      'total': categoryQuestions.length,
    };
  }

  Future<List<String>> getAllCategories() async {
    final categories = _questions.map((q) => q['category'] as String).toSet().toList();
    return categories;
  }

  Future<List<int>> getAvailableLevels() async {
    return [1, 2, 3];
  }

  Future<int> getTotalQuestionsCount() async {
    return _questions.length;
  }

  Future<Map<String, int>> getQuestionsCountByLevel() async {
    final countByLevel = <String, int>{};
    for (int level = 1; level <= 3; level++) {
      final count = _questions.where((q) => q['level'] == level).length;
      countByLevel['level_$level'] = count;
    }
    return countByLevel;
  }

  Future<void> saveScore(int level, int score, int total, String childName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_score_${childName}_$level';
    final existingScore = prefs.getInt(key) ?? 0;
    
    if (score > existingScore) {
      await prefs.setInt(key, score);
    }
    
    final totalKey = 'quiz_total_${childName}_$level';
    await prefs.setInt(totalKey, total);
  }

  Future<int> getBestScore(int level, String childName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_score_${childName}_$level';
    return prefs.getInt(key) ?? 0;
  }

  Future<Map<String, int>> getAllScores(String childName) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = <String, int>{};
    for (int level = 1; level <= 3; level++) {
      final key = 'quiz_score_${childName}_$level';
      scores['level_$level'] = prefs.getInt(key) ?? 0;
    }
    int total = scores.values.reduce((a, b) => a + b);
    scores['total'] = total;
    return scores;
  }

  Future<void> resetAllScores(String childName) async {
    final prefs = await SharedPreferences.getInstance();
    for (int level = 1; level <= 3; level++) {
      final key = 'quiz_score_${childName}_$level';
      await prefs.remove(key);
      final totalKey = 'quiz_total_${childName}_$level';
      await prefs.remove(totalKey);
    }
  }
}