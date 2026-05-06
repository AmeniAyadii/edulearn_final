import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WordCategory {
  final String word;
  final CategoryType type;
  final Color color;
  final String emoji;
  final String definition;

  WordCategory({
    required this.word,
    required this.type,
    required this.color,
    required this.emoji,
    this.definition = '',
  });
}

enum CategoryType {
  // Types existants
  person, animal, food, disease, disaster, place, date,
  email, phone, url, number, object, action, feeling,
  color, vehicle, profession, family, school, nature,
  technology, sport, music, art, adjective, verb, other,
  
  // NOUVEAUX TYPES AJOUTÉS
  noun,           // Nom commun
  pronoun,        // Pronom
  preposition,    // Préposition
  conjunction,    // Conjonction
  adverb,         // Adverbe
  interjection,   // Interjection
  quantity,       // Quantité
  time,           // Temps
  weather,        // Météo
  body,           // Partie du corps
  cloth,          // Vêtement
  furniture,      // Meuble
  tool,           // Outil
  plant,          // Plante
  mineral,        // Minéral
  country,        // Pays
  city,           // Ville
  language,       // Langue
  religion,       // Religion
  mythology,      // Mythologie
  science,        // Science
  geometry,       // Géométrie
  chemistry,      // Chimie
  biology,        // Biologie
  astronomy,      // Astronomie
  computing,      // Informatique
  gaming,         // Jeu vidéo
  cooking,        // Cuisine
  beauty,         // Beauté
}

class TextAnalysisService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Dictionnaire des suffixes pour détection
  final Map<CategoryType, List<String>> _suffixPatterns = {
    CategoryType.person: ['eur', 'rice', 'ien', 'iste', 'ard', 'ouard', 'er', 'ère'],
    CategoryType.action: ['er', 'ir', 're', 'oir', 'ger', 'cer', 'ander'],
    CategoryType.feeling: ['eur', 'esse', 'ité', 'tion', 'sion', 'ance', 'ence'],
    CategoryType.profession: ['ier', 'ien', 'iste', 'eur', 'rice', 'logue', 'icien'],
    CategoryType.school: ['age', 'tion', 'tude', 'cole', 'ivers', 'aire'],
    CategoryType.nature: ['eau', 'ine', 'ette', 'elle', 'ole', 'age'],
    CategoryType.adjective: ['eux', 'euse', 'if', 'ive', 'ant', 'ent', 'able', 'ible'],
    CategoryType.verb: ['er', 'ir', 're', 'oir', 'ander', 'endre'],
    CategoryType.noun: ['age', 'tion', 'sion', 'ure', 'esse', 'isme', 'ment', 'té'],
    CategoryType.adverb: ['ment', 'emment', 'amment'],
  };
  
  // Dictionnaire étendu (mots communs)
  final Map<CategoryType, Map<String, String>> _dictionary = {
    // ==================== TYPES EXISTANTS ====================
    
    // Personnes
    CategoryType.person: {
      'papa': '👨', 'maman': '👩', 'frère': '👨', 'sœur': '👩', 'bébé': '👶',
      'enfant': '🧒', 'adulte': '🧑', 'ami': '👫', 'copain': '👬', 'copine': '👭',
      'professeur': '👨‍🏫', 'docteur': '👨‍⚕️', 'policier': '👮', 'pompier': '👨‍🚒',
      'cuisinier': '👨‍🍳', 'boulanger': '👨‍🍳', 'chanteur': '🎤', 'danseur': '💃',
      'roi': '👑', 'reine': '👸', 'prince': '🤴', 'princesse': '👸',
      'voisin': '🏘️', 'collègue': '💼', 'client': '🤝', 'patient': '🏥',
    },
    
    // Animaux
    CategoryType.animal: {
      'chat': '🐱', 'chien': '🐶', 'oiseau': '🐦', 'poisson': '🐟', 'lapin': '🐰',
      'souris': '🐭', 'cheval': '🐴', 'vache': '🐮', 'cochon': '🐷', 'mouton': '🐑',
      'lion': '🦁', 'tigre': '🐯', 'éléphant': '🐘', 'girafe': '🦒', 'singe': '🐵',
      'poule': '🐔', 'canard': '🦆', 'abeille': '🐝', 'papillon': '🦋', 'escargot': '🐌',
      'serpent': '🐍', 'grenouille': '🐸', 'ours': '🐻', 'renard': '🦊', 'loup': '🐺',
      'dauphin': '🐬', 'baleine': '🐋', 'requin': '🦈', 'panda': '🐼', 'koala': '🐨',
      'kangourou': '🦘', 'zèbre': '🦓', 'hippopotame': '🦛', 'rhinocéros': '🦏',
    },
    
    // Nourriture
    CategoryType.food: {
      'pomme': '🍎', 'banane': '🍌', 'orange': '🍊', 'fraise': '🍓', 'poire': '🍐',
      'raisin': '🍇', 'cerise': '🍒', 'melon': '🍈', 'pastèque': '🍉', 'ananas': '🍍',
      'pizza': '🍕', 'burger': '🍔', 'frites': '🍟', 'glace': '🍦', 'gateau': '🍰',
      'pain': '🍞', 'fromage': '🧀', 'chocolat': '🍫', 'bonbon': '🍬', 'eau': '💧',
      'jus': '🧃', 'lait': '🥛', 'café': '☕', 'thé': '🍵', 'soupe': '🥣',
      'riz': '🍚', 'pâtes': '🍝', 'oeuf': '🥚', 'salade': '🥗', 'sushi': '🍣',
    },
    
    // Couleurs
    CategoryType.color: {
      'rouge': '🔴', 'bleu': '🔵', 'vert': '🟢', 'jaune': '🟡', 'orange': '🟠',
      'violet': '🟣', 'rose': '🌸', 'marron': '🟤', 'noir': '⚫', 'blanc': '⚪',
      'gris': '◻️', 'doré': '✨', 'argent': '⭐', 'argenté': '⭐',
    },
    
    // Véhicules
    CategoryType.vehicle: {
      'voiture': '🚗', 'bus': '🚌', 'train': '🚂', 'avion': '✈️', 'bateau': '⛵',
      'vélo': '🚲', 'moto': '🏍️', 'camion': '🚚', 'tracteur': '🚜', 'hélicoptère': '🚁',
      'fusée': '🚀', 'metro': '🚇', 'tramway': '🚊', 'taxi': '🚕', 'ambulance': '🚑',
      'scooter': '🛴', 'trottinette': '🛴',
    },
    
    // École
    CategoryType.school: {
      'école': '🏫', 'livre': '📚', 'cahier': '📓', 'stylo': '✒️', 'crayon': '✏️',
      'gomme': '🧽', 'règle': '📏', 'cartable': '🎒', 'classe': '🏫', 'maître': '👨‍🏫',
      'maths': '🔢', 'français': '🇫🇷', 'histoire': '📜', 'géographie': '🌍',
      'sciences': '🔬', 'physique': '⚛️', 'chimie': '🧪',
    },
    
    // Sports
    CategoryType.sport: {
      'football': '⚽', 'basket': '🏀', 'tennis': '🎾', 'rugby': '🏉', 'natation': '🏊',
      'course': '🏃', 'ski': '🎿', 'judo': '🥋', 'boxe': '🥊', 'gymnastique': '🤸',
      'danse': '💃', 'yoga': '🧘', 'volley': '🏐', 'handball': '🤾',
    },
    
    // Émotions
    CategoryType.feeling: {
      'heureux': '😊', 'triste': '😢', 'content': '😊', 'fâché': '😠', 'fatigué': '😴',
      'excité': '🤩', 'calme': '😌', 'peur': '😨', 'surprise': '😲', 'amour': '❤️',
      'joie': '🎉', 'colère': '😤', 'tranquille': '😎', 'stressé': '😫',
      'malade': '🤒', 'blessé': '🤕', 'fier': '🦚',
    },
    
    // Nature
    CategoryType.nature: {
      'soleil': '☀️', 'lune': '🌙', 'étoile': '⭐', 'pluie': '🌧️', 'neige': '❄️',
      'vent': '💨', 'nuage': '☁️', 'arbre': '🌳', 'fleur': '🌻', 'montagne': '⛰️',
      'mer': '🌊', 'rivière': '🏞️', 'forêt': '🌲', 'jardin': '🌺', 'volcan': '🌋',
      'désert': '🏜️', 'océan': '🌊', 'tempête': '🌪️',
    },
    
    // Adjectifs
    CategoryType.adjective: {
      'grand': '📏', 'petit': '📏', 'beau': '✨', 'joli': '✨', 'laid': '👎',
      'rapide': '⚡', 'lent': '🐢', 'chaud': '🔥', 'froid': '❄️', 'doux': '☁️',
      'dure': '🪨', 'facile': '✅', 'difficile': '❌', 'important': '⭐',
      'long': '📏', 'court': '📏', 'large': '📐', 'étroit': '📏',
      'jeune': '🧒', 'vieux': '👴', 'nouveau': '🆕', 'ancien': '📜',
    },
    
    // Verbes
    CategoryType.verb: {
      'manger': '🍽️', 'boire': '🥤', 'dormir': '😴', 'courir': '🏃', 'marcher': '🚶',
      'lire': '📖', 'écrire': '✍️', 'parler': '💬', 'chanter': '🎤', 'danser': '💃',
      'jouer': '🎮', 'travailler': '💼', 'étudier': '📚', 'apprendre': '🧠',
      'penser': '💭', 'aimer': '❤️', 'détester': '💔', 'rire': '😂', 'pleurer': '😢',
    },
    
    // ==================== NOUVEAUX TYPES ====================
    
    // Noms communs
    CategoryType.noun: {
      'maison': '🏠', 'jardin': '🌺', 'voiture': '🚗', 'ordinateur': '💻',
      'téléphone': '📱', 'table': '🪑', 'chaise': '💺', 'lit': '🛏️',
      'fenêtre': '🪟', 'porte': '🚪', 'jardin': '🌿', 'jardin': '🌻',
    },
    
    // Pronoms
    CategoryType.pronoun: {
      'je': '🙋', 'tu': '👤', 'il': '👨', 'elle': '👩', 'nous': '👥',
      'vous': '👥', 'ils': '👥', 'elles': '👥', 'me': '🙋', 'te': '👤',
      'se': '🔄', 'lui': '👤', 'leur': '👥', 'ce': '👉', 'cet': '👉',
      'cette': '👉', 'ces': '👉', 'mon': '👤', 'ton': '👤', 'son': '👤',
      'ma': '👤', 'ta': '👤', 'sa': '👤', 'mes': '👥', 'tes': '👥', 'ses': '👥',
    },
    
    // Prépositions
    CategoryType.preposition: {
      'à': '📍', 'de': '➡️', 'en': '📍', 'dans': '📦', 'sur': '⬆️',
      'sous': '⬇️', 'avec': '🤝', 'sans': '🚫', 'pour': '🎯', 'par': '➡️',
      'vers': '➡️', 'chez': '🏠', 'entre': '🤝', 'contre': '🔄', 'après': '⏰',
      'avant': '⏰', 'pendant': '⏱️', 'depuis': '⏰', 'jusque': '➡️',
    },
    
    // Conjonctions
    CategoryType.conjunction: {
      'et': '➕', 'ou': '🔀', 'mais': '⚠️', 'donc': '➡️', 'or': '⚠️',
      'ni': '🚫', 'car': '📖', 'que': '📖', 'si': '❓', 'comme': '🔍',
      'lorsque': '⏰', 'quand': '❓', 'parce que': '📖', 'puisque': '➡️',
    },
    
    // Adverbes
    CategoryType.adverb: {
      'bien': '👍', 'mal': '👎', 'vite': '⚡', 'lentement': '🐢',
      'souvent': '🔄', 'rarement': '❌', 'toujours': '🔄', 'jamais': '🚫',
      'très': '📈', 'beaucoup': '📊', 'peu': '📉', 'assez': '⚖️',
      'ici': '📍', 'là': '📍', 'ailleurs': '📍', 'maintenant': '⏰',
      'hier': '📅', 'aujourd': '📅', 'demain': '📅',
    },
    
    // Interjections
    CategoryType.interjection: {
      'oh': '😲', 'ah': '😮', 'hélas': '😢', 'youpi': '🎉', 'bravo': '👏',
      'chut': '🤫', 'ouf': '😅', 'aïe': '😖', 'coucou': '👋', 'wouah': '😲',
      'zut': '😤', 'mince': '😤', 'flûte': '😤', 'hourra': '🎉',
    },
    
    // Quantité
    CategoryType.quantity: {
      'un': '1️⃣', 'une': '1️⃣', 'deux': '2️⃣', 'trois': '3️⃣', 'quatre': '4️⃣',
      'cinq': '5️⃣', 'six': '6️⃣', 'sept': '7️⃣', 'huit': '8️⃣', 'neuf': '9️⃣',
      'dix': '🔟', 'cent': '💯', 'mille': '1000', 'million': '💰',
      'peu': '📉', 'beaucoup': '📈', 'plusieurs': '📊', 'quelques': '🔢',
    },
    
    // Temps
    CategoryType.time: {
      'matin': '🌅', 'midi': '☀️', 'après-midi': '☀️', 'soir': '🌆',
      'nuit': '🌙', 'heure': '⏰', 'minute': '⏱️', 'seconde': '⏲️',
      'jour': '📅', 'semaine': '📅', 'mois': '📅', 'année': '📅',
      'lundi': '📅', 'mardi': '📅', 'mercredi': '📅', 'jeudi': '📅',
      'vendredi': '📅', 'samedi': '📅', 'dimanche': '📅',
    },
    
    // Météo
    CategoryType.weather: {
      'soleil': '☀️', 'pluie': '🌧️', 'neige': '❄️', 'vent': '💨',
      'orage': '⛈️', 'tempête': '🌪️', 'brume': '🌫️', 'brouillard': '🌫️',
      'canicule': '🔥', 'froid': '❄️', 'chaud': '🔥', 'doux': '🌡️',
    },
    
    // Parties du corps
    CategoryType.body: {
      'tête': '🗣️', 'yeux': '👀', 'nez': '👃', 'bouche': '👄',
      'oreilles': '👂', 'bras': '💪', 'mains': '🖐️', 'jambes': '🦵',
      'pieds': '🦶', 'cœur': '❤️', 'cerveau': '🧠', 'estomac': '🍽️',
      'dos': '🔙', 'ventre': '🤰', 'cou': '🦒', 'épaules': '🤷',
    },
    
    // Vêtements
    CategoryType.cloth: {
      'chemise': '👔', 'pantalon': '👖', 'robe': '👗', 'jupe': '👗',
      'veste': '🧥', 'manteau': '🧥', 'chaussures': '👟', 'bottes': '👢',
      'chapeau': '🧢', 'casquette': '🧢', 'écharpe': '🧣', 'gants': '🧤',
      'lunettes': '👓', 'montre': '⌚', 'ceinture': '⛓️',
    },
    
    // Meubles
    CategoryType.furniture: {
      'table': '🪑', 'chaise': '💺', 'canapé': '🛋️', 'lit': '🛏️',
      'armoire': '🗄️', 'étagère': '📚', 'bureau': '📋', 'commode': '🗄️',
      'fauteuil': '💺', 'tabouret': '🪑', 'bibliothèque': '📚',
    },
    
    // Pays
    CategoryType.country: {
      'france': '🇫🇷', 'tunisie': '🇹🇳', 'algérie': '🇩🇿', 'maroc': '🇲🇦',
      'espagne': '🇪🇸', 'italie': '🇮🇹', 'allemagne': '🇩🇪', 'angleterre': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'états-unis': '🇺🇸', 'canada': '🇨🇦', 'japon': '🇯🇵', 'chine': '🇨🇳',
    },
    
    // Villes
    CategoryType.city: {
      'paris': '🗼', 'tunis': '🏙️', 'alger': '🏙️', 'casablanca': '🏙️',
      'marseille': '⛵', 'lyon': '🏙️', 'bordeaux': '🍷', 'londres': '🏰',
      'new york': '🗽', 'tokyo': '🗼', 'rome': '🏟️', 'barcelone': '💃',
    },
    
    // Langues
    CategoryType.language: {
      'français': '🇫🇷', 'anglais': '🇬🇧', 'arabe': '🇸🇦', 'espagnol': '🇪🇸',
      'allemand': '🇩🇪', 'italien': '🇮🇹', 'portugais': '🇵🇹', 'russe': '🇷🇺',
      'chinois': '🇨🇳', 'japonais': '🇯🇵', 'turc': '🇹🇷',
    },
    
    // Sciences
    CategoryType.science: {
      'physique': '⚛️', 'chimie': '🧪', 'biologie': '🔬', 'mathématiques': '📐',
      'astronomie': '🔭', 'géologie': '⛰️', 'médecine': '💊', 'informatique': '💻',
    },
    
    // Informatique
    CategoryType.computing: {
      'clavier': '⌨️', 'souris': '🖱️', 'écran': '🖥️', 'disque dur': '💾',
      'logiciel': '💿', 'application': '📱', 'site web': '🌐', 'email': '📧',
    },
  };

  // Motifs regex
  final Map<CategoryType, RegExp> _patterns = {
    CategoryType.email: RegExp(r'[\w\.-]+@[\w\.-]+\.\w+'),
    CategoryType.phone: RegExp(r'(0|\+33)[1-9][0-9]{8}|(\+\d{1,3}[-.]?)?\d{9,10}'),
    CategoryType.url: RegExp(r'https?://[^\s]+|www\.[^\s]+'),
    CategoryType.number: RegExp(r'\b\d+(?:[.,]\d+)?\b'),
    CategoryType.date: RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{4}'),
  };

  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text.trim();
  }

  Future<List<WordCategory>> analyzeText(String text) async {
    final List<WordCategory> results = [];
    final words = text.split(RegExp(r'[\s\n\r\t]+'));
    
    for (var word in words) {
      if (word.trim().isEmpty) continue;
      
      final cleanWord = _cleanWord(word);
      final category = await _getWordCategory(cleanWord, word);
      results.add(WordCategory(
        word: word,
        type: category,
        color: getCategoryColor(category),
        emoji: _getCategoryEmoji(category, cleanWord),
        definition: _getDefinition(cleanWord, category),
      ));
    }
    
    return results;
  }

  String _cleanWord(String word) {
    return word.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s-]'), '');
  }

  Future<CategoryType> _getWordCategory(String word, String originalWord) async {
    // 1. Vérifier les patterns regex
    for (var entry in _patterns.entries) {
      if (entry.value.hasMatch(originalWord)) {
        return entry.key;
      }
    }
    
    // 2. Vérifier le dictionnaire local
    for (var entry in _dictionary.entries) {
      if (entry.value.containsKey(word)) {
        return entry.key;
      }
    }
    
    // 3. Vérifier les préfixes/suffixes
    for (var entry in _suffixPatterns.entries) {
      for (var suffix in entry.value) {
        if (word.endsWith(suffix)) {
          return entry.key;
        }
      }
    }
    
    // 4. Détection par capitalisation (noms propres)
    if (originalWord.isNotEmpty && originalWord[0].toUpperCase() == originalWord[0] && 
        originalWord.length > 1 && originalWord[1].toLowerCase() == originalWord[1]) {
      return CategoryType.person;
    }
    
    // 5. Détection par longueur et structure
    if (word.length >= 5 && word.endsWith('tion')) {
      return CategoryType.noun;
    }
    if (word.endsWith('ment')) {
      return CategoryType.noun;
    }
    if (word.endsWith('ité') || word.endsWith('té')) {
      return CategoryType.noun;
    }
    
    // 6. Détection des mots composés
    if (word.contains('-')) {
      return CategoryType.object;
    }
    
    // 7. Détection des prépositions (mots courts)
    if (word.length <= 3 && ['à', 'de', 'en', 'dans', 'sur', 'sous', 'avec', 'sans', 'par', 'pour', 'chez', 'entre', 'contre', 'après', 'avant', 'pendant', 'depuis', 'jusque'].contains(word)) {
      return CategoryType.preposition;
    }
    
    // 8. Détection des pronoms
    if (['je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'me', 'te', 'se', 'lui', 'leur', 'ce', 'cet', 'cette', 'ces', 'mon', 'ton', 'son', 'ma', 'ta', 'sa', 'mes', 'tes', 'ses'].contains(word)) {
      return CategoryType.pronoun;
    }
    
    // 9. Détection des conjonctions
    if (['et', 'ou', 'mais', 'donc', 'or', 'ni', 'car', 'que', 'si', 'comme', 'lorsque', 'quand', 'parce que', 'puisque'].contains(word)) {
      return CategoryType.conjunction;
    }
    
    // 10. Détection des adverbes
    if (word.endsWith('ment')) {
      return CategoryType.adverb;
    }
    
    // 11. API en ligne (si le mot est long et inconnu)
    if (word.length > 3) {
      try {
        final apiCategory = await _checkOnlineDictionary(word);
        if (apiCategory != CategoryType.other) {
          return apiCategory;
        }
      } catch (e) {}
    }
    
    return CategoryType.other;
  }

  Future<CategoryType> _checkOnlineDictionary(String word) async {
    try {
      final url = Uri.parse('https://fr.wiktionary.org/w/api.php?action=parse&page=$word&format=json&prop=text');
      final response = await http.get(url).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('parse')) {
          final text = data['parse']['text']['*'].toString().toLowerCase();
          
          if (text.contains('nom commun')) {
            if (text.contains('animal')) return CategoryType.animal;
            if (text.contains('aliment') || text.contains('fruit') || text.contains('légume')) return CategoryType.food;
            if (text.contains('personne')) return CategoryType.person;
            if (text.contains('lieu') || text.contains('ville')) return CategoryType.place;
            if (text.contains('couleur')) return CategoryType.color;
            if (text.contains('sentiment') || text.contains('émotion')) return CategoryType.feeling;
            return CategoryType.noun;
          }
          if (text.contains('verbe')) return CategoryType.verb;
          if (text.contains('adjectif')) return CategoryType.adjective;
          if (text.contains('adverbe')) return CategoryType.adverb;
          if (text.contains('préposition')) return CategoryType.preposition;
          if (text.contains('conjonction')) return CategoryType.conjunction;
          if (text.contains('pronom')) return CategoryType.pronoun;
          if (text.contains('interjection')) return CategoryType.interjection;
        }
      }
    } catch (e) {}
    return CategoryType.other;
  }

  String _getDefinition(String word, CategoryType type) {
    switch (type) {
      case CategoryType.person: return 'Une personne';
      case CategoryType.animal: return 'Un animal';
      case CategoryType.food: return 'Un aliment';
      case CategoryType.disease: return 'Une maladie';
      case CategoryType.disaster: return 'Une catastrophe';
      case CategoryType.place: return 'Un lieu';
      case CategoryType.date: return 'Une date';
      case CategoryType.email: return 'Une adresse email';
      case CategoryType.phone: return 'Un numéro de téléphone';
      case CategoryType.url: return 'Un lien web';
      case CategoryType.number: return 'Un nombre';
      case CategoryType.object: return 'Un objet';
      case CategoryType.action: return 'Une action';
      case CategoryType.feeling: return 'Un sentiment';
      case CategoryType.color: return 'Une couleur';
      case CategoryType.vehicle: return 'Un véhicule';
      case CategoryType.profession: return 'Un métier';
      case CategoryType.family: return 'Membre de la famille';
      case CategoryType.school: return 'Objet scolaire';
      case CategoryType.nature: return 'Élément de la nature';
      case CategoryType.technology: return 'Technologie';
      case CategoryType.sport: return 'Un sport';
      case CategoryType.music: return 'Musique';
      case CategoryType.art: return 'Art';
      case CategoryType.adjective: return 'Un adjectif';
      case CategoryType.verb: return 'Un verbe';
      case CategoryType.noun: return 'Un nom commun';
      case CategoryType.pronoun: return 'Un pronom';
      case CategoryType.preposition: return 'Une préposition';
      case CategoryType.conjunction: return 'Une conjonction';
      case CategoryType.adverb: return 'Un adverbe';
      case CategoryType.interjection: return 'Une interjection';
      case CategoryType.quantity: return 'Une quantité';
      case CategoryType.time: return 'Un moment';
      case CategoryType.weather: return 'Phénomène météo';
      case CategoryType.body: return 'Partie du corps';
      case CategoryType.cloth: return 'Vêtement';
      case CategoryType.furniture: return 'Meuble';
      case CategoryType.country: return 'Un pays';
      case CategoryType.city: return 'Une ville';
      case CategoryType.language: return 'Une langue';
      case CategoryType.science: return 'Une science';
      case CategoryType.computing: return 'Informatique';
      default: return 'Mot inconnu';
    }
  }

  Color getCategoryColor(CategoryType type) {
    switch (type) {
      case CategoryType.person: return Colors.indigo;
      case CategoryType.animal: return Colors.orange;
      case CategoryType.food: return Colors.red;
      case CategoryType.disease: return Colors.purple;
      case CategoryType.disaster: return Colors.deepOrange;
      case CategoryType.place: return Colors.teal;
      case CategoryType.date: return Colors.green;
      case CategoryType.email: return Colors.blue;
      case CategoryType.phone: return Colors.cyan;
      case CategoryType.url: return Colors.pink;
      case CategoryType.number: return Colors.amber;
      case CategoryType.object: return Colors.brown;
      case CategoryType.action: return Colors.lime;
      case CategoryType.feeling: return Colors.pinkAccent;
      case CategoryType.color: return Colors.purpleAccent;
      case CategoryType.vehicle: return Colors.blueGrey;
      case CategoryType.profession: return Colors.deepPurple;
      case CategoryType.family: return Colors.lightGreen;
      case CategoryType.school: return Colors.lightBlue;
      case CategoryType.nature: return Colors.greenAccent;
      case CategoryType.technology: return Colors.cyanAccent;
      case CategoryType.sport: return Colors.orangeAccent;
      case CategoryType.music: return Colors.deepPurpleAccent;
      case CategoryType.art: return Colors.pinkAccent;
      case CategoryType.adjective: return Colors.lightBlueAccent;
      case CategoryType.verb: return Colors.amberAccent;
      case CategoryType.noun: return Colors.blueGrey;
      case CategoryType.pronoun: return Colors.purple.shade300;
      case CategoryType.preposition: return Colors.cyan.shade300;
      case CategoryType.conjunction: return Colors.teal.shade300;
      case CategoryType.adverb: return Colors.indigo.shade300;
      case CategoryType.interjection: return Colors.pink.shade300;
      case CategoryType.quantity: return Colors.orangeAccent;
      case CategoryType.time: return Colors.lightGreen;
      case CategoryType.weather: return Colors.lightBlue;
      case CategoryType.body: return Colors.redAccent;
      case CategoryType.cloth: return Colors.purpleAccent;
      case CategoryType.furniture: return Colors.brown;
      case CategoryType.country: return Colors.blue;
      case CategoryType.city: return Colors.indigo;
      case CategoryType.language: return Colors.cyan;
      case CategoryType.science: return Colors.green;
      case CategoryType.computing: return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String _getCategoryEmoji(CategoryType type, String word) {
    // Vérifier dans le dictionnaire
    for (var entry in _dictionary.entries) {
      if (entry.value.containsKey(word)) {
        return entry.value[word]!;
      }
    }
    
    // Emojis par défaut par catégorie
    switch (type) {
      case CategoryType.person: return '👤';
      case CategoryType.animal: return '🐾';
      case CategoryType.food: return '🍽️';
      case CategoryType.disease: return '🏥';
      case CategoryType.disaster: return '⚠️';
      case CategoryType.place: return '📍';
      case CategoryType.date: return '📅';
      case CategoryType.email: return '📧';
      case CategoryType.phone: return '📞';
      case CategoryType.url: return '🔗';
      case CategoryType.number: return '🔢';
      case CategoryType.object: return '📦';
      case CategoryType.action: return '⚡';
      case CategoryType.feeling: return '😊';
      case CategoryType.color: return '🎨';
      case CategoryType.vehicle: return '🚗';
      case CategoryType.profession: return '💼';
      case CategoryType.family: return '👨‍👩‍👧';
      case CategoryType.school: return '📚';
      case CategoryType.nature: return '🌿';
      case CategoryType.technology: return '💻';
      case CategoryType.sport: return '⚽';
      case CategoryType.music: return '🎵';
      case CategoryType.art: return '🎨';
      case CategoryType.adjective: return '✨';
      case CategoryType.verb: return '⚡';
      case CategoryType.noun: return '📖';
      case CategoryType.pronoun: return '🔤';
      case CategoryType.preposition: return '↗️';
      case CategoryType.conjunction: return '🔗';
      case CategoryType.adverb: return '⏱️';
      case CategoryType.interjection: return '❗';
      case CategoryType.quantity: return '🔢';
      case CategoryType.time: return '⏰';
      case CategoryType.weather: return '🌤️';
      case CategoryType.body: return '🫀';
      case CategoryType.cloth: return '👕';
      case CategoryType.furniture: return '🪑';
      case CategoryType.country: return '🌍';
      case CategoryType.city: return '🏙️';
      case CategoryType.language: return '🗣️';
      case CategoryType.science: return '🔬';
      case CategoryType.computing: return '💻';
      default: return '❓';
    }
  }

  String getCategoryLabel(CategoryType type) {
    switch (type) {
      case CategoryType.person: return 'Personne';
      case CategoryType.animal: return 'Animal';
      case CategoryType.food: return 'Nourriture';
      case CategoryType.disease: return 'Maladie';
      case CategoryType.disaster: return 'Catastrophe';
      case CategoryType.place: return 'Lieu';
      case CategoryType.date: return 'Date';
      case CategoryType.email: return 'Email';
      case CategoryType.phone: return 'Téléphone';
      case CategoryType.url: return 'Lien web';
      case CategoryType.number: return 'Nombre';
      case CategoryType.object: return 'Objet';
      case CategoryType.action: return 'Action';
      case CategoryType.feeling: return 'Sentiment';
      case CategoryType.color: return 'Couleur';
      case CategoryType.vehicle: return 'Véhicule';
      case CategoryType.profession: return 'Métier';
      case CategoryType.family: return 'Famille';
      case CategoryType.school: return 'École';
      case CategoryType.nature: return 'Nature';
      case CategoryType.technology: return 'Technologie';
      case CategoryType.sport: return 'Sport';
      case CategoryType.music: return 'Musique';
      case CategoryType.art: return 'Art';
      case CategoryType.adjective: return 'Adjectif';
      case CategoryType.verb: return 'Verbe';
      case CategoryType.noun: return 'Nom';
      case CategoryType.pronoun: return 'Pronom';
      case CategoryType.preposition: return 'Préposition';
      case CategoryType.conjunction: return 'Conjonction';
      case CategoryType.adverb: return 'Adverbe';
      case CategoryType.interjection: return 'Interjection';
      case CategoryType.quantity: return 'Quantité';
      case CategoryType.time: return 'Temps';
      case CategoryType.weather: return 'Météo';
      case CategoryType.body: return 'Corps';
      case CategoryType.cloth: return 'Vêtement';
      case CategoryType.furniture: return 'Meuble';
      case CategoryType.country: return 'Pays';
      case CategoryType.city: return 'Ville';
      case CategoryType.language: return 'Langue';
      case CategoryType.science: return 'Science';
      case CategoryType.computing: return 'Informatique';
      default: return 'Autre';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}