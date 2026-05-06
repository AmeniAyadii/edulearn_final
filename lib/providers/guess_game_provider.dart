// lib/providers/guess_game_provider.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
// import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart'; // Commenté si pas disponible
import '../models/game_session.dart';

// ============================================================================
// ENUMS ET CLASSES AUXILIAIRES
// ============================================================================

enum GuessResult { correct, wrong }

class _DetectedObject {
  final String label;
  final double confidence;
  _DetectedObject({required this.label, required this.confidence});
}

class _RandomObject {
  final String label;
  final double confidence;
  _RandomObject(this.label, this.confidence);
}

// ============================================================================
// GUESS GAME PROVIDER - VERSION STABLE
// ============================================================================

class GuessGameProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = FirebaseStorage.instance;
  
  late ObjectDetector _objectDetector;
  // SmartReplyGenerator? _smartReplyGenerator; // Commenté temporairement
  
  GameSession? currentSession;
  bool isProcessing = false;
  String? errorMessage;
  
  GuessGameProvider() {
    _initMLKit();
  }

  // ==========================================================================
  // CRÉATION DE SESSION
  // ==========================================================================
  
  Future<String> createNewSession({String? childId}) async {
    try {
      print('🔵 createNewSession - Début pour enfant: $childId');
      
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      print('🔵 Session ID généré: "$sessionId"');
      
      if (sessionId.isEmpty) {
        throw Exception('Session ID cannot be empty');
      }
      
      // ✅ Récupérer un objet aléatoire
      final randomObject = _getRandomObject();
      print('🔵 Objet sélectionné: ${randomObject.label}');
      
      // ✅ Générer les indices
      final clues = _generateClues(randomObject.label);
      
      // ✅ Créer le document Firestore avec TOUS les champs nécessaires
      final sessionData = {
        'sessionId': sessionId,
        'childId': childId ?? '',
        'secretObjectLabel': randomObject.label,
        'confidence': randomObject.confidence,
        'clues': clues.map((c) => c.toMap()).toList(),
        'currentClueIndex': 0,
        'attemptsUsed': 0,
        'pointsEarned': 0,
        'status': 0,
        'mode': 0,
        'difficulty': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
      };
      
      await _firestore.collection('gameSessions').doc(sessionId).set(sessionData);
      print('🟢 Document Firestore créé avec succès');
      
      // ✅ Créer la session locale
      currentSession = GameSession(
        sessionId: sessionId,
        creatorChildId: childId ?? '',
        secretObjectLabel: randomObject.label,
        confidence: randomObject.confidence,
        clues: clues,
        currentClueIndex: 0,
        attemptsUsed: 0,
        pointsEarned: 0,
        status: GameStatus.inProgress,
        mode: GameMode.solo,
        difficulty: Difficulty.medium,
        createdAt: DateTime.now(),
      );
      
      print('🟢 Session locale créée avec succès');
      notifyListeners();
      return sessionId;
    } catch (e) {
      print('🔴 Erreur création session: $e');
      errorMessage = e.toString();
      return '';
    }
  }
  
  // ✅ MÉTHODE _getRandomObject AJOUTÉE
  _RandomObject _getRandomObject() {
    final objects = _getAllRandomObjects();
    final random = Random();
    return objects[random.nextInt(objects.length)];
  }
  
  Future<void> _initMLKit() async {
    try {
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: false,
      );
      _objectDetector = ObjectDetector(options: options);
      debugPrint('✅ ObjectDetector initialisé');
    } catch (e) {
      debugPrint('❌ Erreur ObjectDetector: $e');
    }
  }
  
  Future<_DetectedObject?> _detectObject(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      
      if (objects.isEmpty) return null;
      
      final bestObject = objects.first;
      String label = "Objet inconnu";
      double confidence = 0.5;
      
      if (bestObject.labels.isNotEmpty) {
        label = bestObject.labels.first.text;
        confidence = bestObject.labels.first.confidence;
      }
      
      debugPrint('📷 Objet détecté: $label (${(confidence * 100).toInt()}%)');
      return _DetectedObject(label: label, confidence: confidence);
    } catch (e) {
      debugPrint('Erreur détection objet: $e');
      return null;
    }
  }
  
  // ==========================================================================
  // GÉNÉRATION D'INDICES
  // ==========================================================================
  
  List<Clue> _generateClues(String objectLabel) {
    final clues = <Clue>[];
    final clueTemplates = _getCluesForObject(objectLabel);
    
    for (int i = 0; i < clueTemplates.length && i < 3; i++) {
      clues.add(Clue(
        clueText: clueTemplates[i],
        clueNumber: i + 1,
        generatedAt: DateTime.now(),
      ));
    }
    
    return clues;
  }
  
  List<String> _getCluesForObject(String objectLabel) {
    final lowerLabel = objectLabel.toLowerCase();
    
    // ==================== ANIMAUX ====================
    if (lowerLabel.contains('chat') || lowerLabel.contains('cat')) {
      return ["🐱 Je fais miaou", "🥛 J'adore le lait", "🐭 Je chasse les souris"];
    }
    if (lowerLabel.contains('chien') || lowerLabel.contains('dog')) {
      return ["🐶 Meilleur ami de l'homme", "🗣️ J'aboie", "🦴 J'aime les os"];
    }
    if (lowerLabel.contains('oiseau') || lowerLabel.contains('bird')) {
      return ["🦜 Je vole dans le ciel", "🥚 Je ponds des œufs", "🎵 Je chante le matin"];
    }
    if (lowerLabel.contains('poisson') || lowerLabel.contains('fish')) {
      return ["🐟 Je vis dans l'eau", "🌊 Je respire avec des branchies", "🐠 Je nage dans un aquarium"];
    }
    if (lowerLabel.contains('lapin') || lowerLabel.contains('rabbit')) {
      return ["🐰 J'ai de longues oreilles", "🥕 J'adore les carottes", "🐇 Je saute très haut"];
    }
    if (lowerLabel.contains('cheval') || lowerLabel.contains('horse')) {
      return ["🐴 Je cours très vite", "🌾 Je mange du foin", "🏇 On peut me monter"];
    }
    if (lowerLabel.contains('vache') || lowerLabel.contains('cow')) {
      return ["🐮 Je donne du lait", "🌿 Je vis dans les champs", "🧀 On fait du fromage avec mon lait"];
    }
    if (lowerLabel.contains('cochon') || lowerLabel.contains('pig')) {
      return ["🐷 J'ai le nez rond", "🌾 Je mange tout", "💕 Je suis rose"];
    }
    if (lowerLabel.contains('lion')) {
      return ["🦁 Je suis le roi des animaux", "👑 J'ai une grande crinière", "🐾 Je vis dans la savane"];
    }
    if (lowerLabel.contains('tigre') || lowerLabel.contains('tiger')) {
      return ["🐅 J'ai des rayures noires", "🌏 Je vis en Asie", "🏃 Je cours très vite"];
    }
    if (lowerLabel.contains('girafe') || lowerLabel.contains('giraffe')) {
      return ["🦒 J'ai un très long cou", "🌿 Je mange les feuilles en haut des arbres", "📏 Je suis l'animal le plus grand"];
    }
    if (lowerLabel.contains('éléphant') || lowerLabel.contains('elephant')) {
      return ["🐘 Je suis le plus grand animal terrestre", "👃 J'ai une longue trompe", "🦷 J'ai de grandes défenses"];
    }
    if (lowerLabel.contains('singe') || lowerLabel.contains('monkey')) {
      return ["🐒 J'adore les bananes", "🌴 Je vis dans la jungle", "🧗 Je grimpe aux arbres"];
    }
    if (lowerLabel.contains('panda')) {
      return ["🐼 Je suis noir et blanc", "🎋 Je mange du bambou", "🇨🇳 Je vis en Chine"];
    }
    if (lowerLabel.contains('ours') || lowerLabel.contains('bear')) {
      return ["🐻 J'hiberne en hiver", "🍯 J'adore le miel", "🌲 Je vis dans la forêt"];
    }
    if (lowerLabel.contains('kangourou')) {
      return ["🦘 Je saute sur mes pattes arrière", "👛 La femelle a une poche", "🇦🇺 Je vis en Australie"];
    }
    if (lowerLabel.contains('dauphin') || lowerLabel.contains('dolphin')) {
      return ["🐬 Je suis très intelligent", "🌊 Je saute hors de l'eau", "🗣️ Je communique par sifflements"];
    }
    if (lowerLabel.contains('baleine')) {
      return ["🐋 Je suis le plus grand animal du monde", "💦 Je projette de l'eau par mon évent", "🌊 Je vis dans les océans"];
    }
    if (lowerLabel.contains('abeille') || lowerLabel.contains('bee')) {
      return ["🐝 Je produis du miel", "🌸 Je butine les fleurs", "🏠 Je vis dans une ruche"];
    }
    if (lowerLabel.contains('papillon') || lowerLabel.contains('butterfly')) {
      return ["🦋 J'ai des ailes colorées", "🌸 Je vole autour des fleurs", "🐛 J'étais une chenille avant"];
    }
    
    // ==================== FRUITS ET LÉGUMES ====================
    if (lowerLabel.contains('pomme') || lowerLabel.contains('apple')) {
      return ["🍎 Je suis un fruit rouge ou vert", "🌳 Je pousse sur un arbre", "🥧 On fait de la tarte avec moi"];
    }
    if (lowerLabel.contains('banane') || lowerLabel.contains('banana')) {
      return ["🍌 Je suis jaune et courbé", "🐒 Les singes m'adorent", "🌴 Je pousse en grappe"];
    }
    if (lowerLabel.contains('fraise') || lowerLabel.contains('strawberry')) {
      return ["🍓 Je suis petit et rouge", "🌱 Je pousse près du sol", "🍰 On me met sur les gâteaux"];
    }
    if (lowerLabel.contains('orange')) {
      return ["🍊 Je suis rond et orange", "🧃 On fait du jus avec moi", "🍊 Je suis plein de vitamine C"];
    }
    if (lowerLabel.contains('citron') || lowerLabel.contains('lemon')) {
      return ["🍋 Je suis jaune et acide", "🍋 On me met dans l'eau", "🥧 On fait des tartes au citron"];
    }
    if (lowerLabel.contains('raisin') || lowerLabel.contains('grape')) {
      return ["🍇 Je pousse en grappe", "🍷 On fait du vin avec moi", "🍇 Je suis sucré"];
    }
    if (lowerLabel.contains('cerise') || lowerLabel.contains('cherry')) {
      return ["🍒 Je suis petit et rouge", "🌳 Je pousse sur un arbre", "🥧 On fait des clafoutis"];
    }
    if (lowerLabel.contains('carotte') || lowerLabel.contains('carrot')) {
      return ["🥕 Je suis orange", "🐰 Les lapins m'adorent", "🌱 Je pousse sous terre"];
    }
    if (lowerLabel.contains('tomate') || lowerLabel.contains('tomato')) {
      return ["🍅 Je suis rouge", "🍝 On fait de la sauce avec moi", "🥗 Je suis bonne dans la salade"];
    }
    if (lowerLabel.contains('pastèque') || lowerLabel.contains('watermelon')) {
      return ["🍉 Je suis vert dehors, rouge dedans", "🌞 Je suis rafraîchissante en été", "🖤 J'ai des pépins noirs"];
    }
    if (lowerLabel.contains('ananas') || lowerLabel.contains('pineapple')) {
      return ["🍍 J'ai une peau piquante", "🏝️ Je pousse dans les pays chauds", "🍍 Je suis jaune et sucré"];
    }
    
    // ==================== VÉHICULES ====================
    if (lowerLabel.contains('voiture') || lowerLabel.contains('car')) {
      return ["🚗 J'ai 4 roues", "⛽ J'ai besoin d'essence", "🔑 On me conduit avec un volant"];
    }
    if (lowerLabel.contains('vélo') || lowerLabel.contains('bike') || lowerLabel.contains('velo')) {
      return ["🚲 J'ai 2 roues", "🦵 On me pédale avec les pieds", "🚴 Je suis écologique"];
    }
    if (lowerLabel.contains('moto') || lowerLabel.contains('motorcycle')) {
      return ["🏍️ J'ai 2 roues", "⛽ Je roule à l'essence", "🏍️ Je suis plus rapide qu'un vélo"];
    }
    if (lowerLabel.contains('camion') || lowerLabel.contains('truck')) {
      return ["🚛 Je transporte des marchandises", "📦 J'ai une grande remorque", "🚚 Je livre dans les magasins"];
    }
    if (lowerLabel.contains('avion') || lowerLabel.contains('plane')) {
      return ["✈️ Je vole dans le ciel", "🛫 Je décolle d'un aéroport", "🌍 Je sers à voyager loin"];
    }
    if (lowerLabel.contains('train')) {
      return ["🚂 Je roule sur des rails", "🚆 Je suis très long", "🔔 Je fais tchou tchou"];
    }
    if (lowerLabel.contains('bateau') || lowerLabel.contains('boat')) {
      return ["⛵ Je flotte sur l'eau", "🌊 Je navigue sur la mer", "⚓ Je jette l'ancre pour m'arrêter"];
    }
    if (lowerLabel.contains('hélicoptère') || lowerLabel.contains('helicopter')) {
      return ["🚁 J'ai des pales sur le toit", "🛩️ Je peux voler sur place", "🚁 Je sers souvent aux secours"];
    }
    
    // ==================== OBJETS DE LA MAISON ====================
    if (lowerLabel.contains('chaise') || lowerLabel.contains('chair')) {
      return ["🪑 On s'assoit sur moi", "🏠 Je suis dans la salle à manger", "4️⃣ J'ai 4 pieds"];
    }
    if (lowerLabel.contains('table')) {
      return ["🪵 On pose les assiettes sur moi", "🏠 Je suis dans la salle à manger", "🍽️ Je suis entourée de chaises"];
    }
    if (lowerLabel.contains('lit') || lowerLabel.contains('bed')) {
      return ["🛏️ On dort sur moi", "🛌 Je suis moelleux", "🌙 Je suis dans la chambre"];
    }
    if (lowerLabel.contains('livre') || lowerLabel.contains('book')) {
      return ["📖 J'ai beaucoup de pages", "📚 On me lit pour apprendre", "🔖 On me range dans une bibliothèque"];
    }
    if (lowerLabel.contains('stylo') || lowerLabel.contains('pen')) {
      return ["✍️ Je sers à écrire", "🖊️ J'ai de l'encre", "📝 On me tient à la main"];
    }
    if (lowerLabel.contains('téléphone') || lowerLabel.contains('phone')) {
      return ["📱 Je sers à communiquer", "📞 On peut appeler avec moi", "💬 Je sers à envoyer des messages"];
    }
    if (lowerLabel.contains('ordinateur') || lowerLabel.contains('computer')) {
      return ["💻 Je sers à travailler", "🖥️ J'ai un écran", "⌨️ On utilise un clavier avec moi"];
    }
    if (lowerLabel.contains('télévision') || lowerLabel.contains('tv')) {
      return ["📺 Je suis un écran", "📡 On capte les chaînes avec une antenne", "🎬 On peut voir des films sur moi"];
    }
    if (lowerLabel.contains('lampe') || lowerLabel.contains('lamp')) {
      return ["💡 J'éclaire la pièce", "🔘 On m'allume avec un bouton", "🌙 Je sers la nuit"];
    }
    if (lowerLabel.contains('réfrigérateur') || lowerLabel.contains('fridge')) {
      return ["🧊 Je garde les aliments au froid", "🥛 On met le lait en moi", "❄️ Je fais du froid à l'intérieur"];
    }
    if (lowerLabel.contains('four') || lowerLabel.contains('oven')) {
      return ["🔥 Je chauffe", "🍕 On fait cuire des pizzas en moi", "🥧 On peut faire des gâteaux"];
    }
    if (lowerLabel.contains('aspirateur') || lowerLabel.contains('vacuum')) {
      return ["🧹 J'aspire la poussière", "🔌 On me branche sur secteur", "🏠 On nettoie la maison avec moi"];
    }
    if (lowerLabel.contains('montre') || lowerLabel.contains('watch')) {
      return ["⌚ Je porte au poignet", "⏰ J'indique l'heure", "🏃 On me porte pour le sport"];
    }
    if (lowerLabel.contains('lunettes') || lowerLabel.contains('glasses')) {
      return ["👓 Je aide à mieux voir", "☀️ Les lunettes de soleil protègent du soleil", "👀 J'ai deux verres"];
    }
    if (lowerLabel.contains('couteau') || lowerLabel.contains('knife')) {
      return ["🔪 Je suis tranchant", "🍞 Je sers à couper le pain", "🍴 Je suis dangereux"];
    }
    
    // ==================== NATURE ====================
    if (lowerLabel.contains('fleur') || lowerLabel.contains('flower')) {
      return ["🌸 J'ai des pétales colorés", "🌻 Je tourne vers le soleil", "🐝 Les abeilles butinent mon pollen"];
    }
    if (lowerLabel.contains('arbre') || lowerLabel.contains('tree')) {
      return ["🌳 J'ai un tronc et des branches", "🍎 Je donne des fruits", "🍂 Je perds mes feuilles en automne"];
    }
    if (lowerLabel.contains('soleil') || lowerLabel.contains('sun')) {
      return ["☀️ Je suis une grosse étoile", "🌞 Je donne de la chaleur", "🌍 La Terre tourne autour de moi"];
    }
    if (lowerLabel.contains('lune') || lowerLabel.contains('moon')) {
      return ["🌙 Je brille la nuit", "🌕 Je change de forme", "🚀 Les astronautes sont allés sur moi"];
    }
    if (lowerLabel.contains('étoile') || lowerLabel.contains('star')) {
      return ["⭐ Je suis un point brillant dans le ciel", "✨ On en voit des milliers", "⭐ On fait des vœux en me voyant"];
    }
    
    // ==================== NOURRITURE ====================
    if (lowerLabel.contains('pain') || lowerLabel.contains('bread')) {
      return ["🥖 Je suis fait de farine et d'eau", "🍞 On me mange au petit-déjeuner", "🥐 Je peux être en baguette"];
    }
    if (lowerLabel.contains('pizza')) {
      return ["🍕 Je suis rond avec de la sauce tomate", "🧀 On met du fromage sur moi", "🔥 Je cuit au four"];
    }
    if (lowerLabel.contains('glace') || lowerLabel.contains('ice cream')) {
      return ["🍦 Je suis un dessert qui fond", "🍨 Je suis froide et sucrée", "☀️ On m'adore en été"];
    }
    if (lowerLabel.contains('chocolat') || lowerLabel.contains('chocolate')) {
      return ["🍫 Je suis une friandise brune", "🍬 On me mange en tablette", "🥛 Le chocolat chaud se boit"];
    }
    if (lowerLabel.contains('hamburger') || lowerLabel.contains('burger')) {
      return ["🍔 Je suis un sandwich rond", "🧀 On met du fromage dedans", "🍟 On me mange avec des frites"];
    }
    if (lowerLabel.contains('frites') || lowerLabel.contains('fries')) {
      return ["🍟 Je suis des bâtonnets de pommes de terre", "🥔 On me fait avec des pommes de terre", "🍔 On me mange avec un burger"];
    }
    
    // ==================== SPORT ====================
    if (lowerLabel.contains('ballon') || lowerLabel.contains('ball')) {
      return ["⚽ Je suis rond", "🏀 On me lance dans un panier", "🎾 On me frappe avec une raquette"];
    }
    if (lowerLabel.contains('football') || lowerLabel.contains('soccer')) {
      return ["⚽ Je suis un sport", "🥅 Les buts gardent le ballon", "🏆 Il y a la Coupe du monde"];
    }
    
    // ==================== DÉFAUT ====================
    return ["🔍 C'est un objet du quotidien", "✨ Tu l'utilises souvent", "🎯 Devine mon nom !"];
  }
  
  // ==========================================================================
  // CRÉATION DE PARTIES
  // ==========================================================================
  
  
  
  // ==========================================================================
// CRÉATION DE PARTIE À PARTIR D'UNE IMAGE
// ==========================================================================

Future<void> createGameSessionFromImage(
  File imageFile,
  String childId,
  String childName, {
  GameMode mode = GameMode.multiplayer,
  Difficulty difficulty = Difficulty.medium,
}) async {
  isProcessing = true;
  errorMessage = null;
  notifyListeners();
  
  try {
    final imageUrl = await _uploadImage(imageFile, childId);
    final detectedObject = await _detectObject(imageFile);
    
    if (detectedObject == null) {
      throw Exception("Aucun objet détecté");
    }
    
    final clues = _generateClues(detectedObject.label);
    final joinCode = mode == GameMode.multiplayer ? _generateJoinCode() : null;
    
    final sessionId = _generateSessionId();
    
    // ✅ CORRIGÉ: Ajout de currentClueIndex et attemptsUsed
    final session = GameSession(
      sessionId: sessionId,
      creatorChildId: childId,
      secretObjectLabel: detectedObject.label,
      confidence: detectedObject.confidence,
      imageUrl: imageUrl,
      clues: clues,
      currentClueIndex: 0,           // ← AJOUTÉ OBLIGATOIREMENT
      status: GameStatus.waiting,
      mode: mode,
      difficulty: difficulty,
      attemptsUsed: 0,               // ← AJOUTÉ OBLIGATOIREMENT
      createdAt: DateTime.now(),
      pointsEarned: 0,               // ← AJOUTÉ OBLIGATOIREMENT
      joinCode: joinCode,
    );
    
    await _firestore.collection('gameSessions').doc(sessionId).set(session.toFirestore());
    currentSession = session;
    isProcessing = false;
    notifyListeners();
    
    debugPrint('✅ Partie créée - Objet: ${detectedObject.label}');
  } catch (e) {
    errorMessage = e.toString();
    isProcessing = false;
    notifyListeners();
    rethrow;
  }
}

// ==========================================================================
// CRÉATION DE PARTIE SOLO
// ==========================================================================

Future<void> createSoloGame(String childId, Difficulty difficulty) async {
  isProcessing = true;
  errorMessage = null;
  notifyListeners();
  
  try {
    final randomObject = _getRandomObjectByDifficulty(difficulty);
    final clues = _generateClues(randomObject.label);
    
    final sessionId = 'SOLO_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    
    // ✅ CORRIGÉ: Ajout de currentClueIndex, attemptsUsed et pointsEarned
    final session = GameSession(
      sessionId: sessionId,
      creatorChildId: childId,
      guesserChildId: childId,
      secretObjectLabel: randomObject.label,
      confidence: randomObject.confidence,
      clues: clues,
      currentClueIndex: 0,           // ← AJOUTÉ OBLIGATOIREMENT
      status: GameStatus.inProgress,
      mode: GameMode.solo,
      difficulty: difficulty,
      attemptsUsed: 0,               // ← AJOUTÉ OBLIGATOIREMENT
      createdAt: DateTime.now(),
      pointsEarned: 0,               // ← AJOUTÉ OBLIGATOIREMENT
    );
    
    currentSession = session;
    isProcessing = false;
    notifyListeners();
    
    debugPrint('✅ Partie solo - Objet: ${randomObject.label}');
  } catch (e) {
    errorMessage = e.toString();
    isProcessing = false;
    notifyListeners();
    rethrow;
  }
}
  
  List<_RandomObject> _getAllRandomObjects() {
    return [
      _RandomObject('chat', 0.95),
      _RandomObject('chien', 0.95),
      _RandomObject('pomme', 0.95),
      _RandomObject('banane', 0.95),
      _RandomObject('voiture', 0.85),
      _RandomObject('oiseau', 0.95),
      _RandomObject('poisson', 0.95),
      _RandomObject('soleil', 0.95),
      _RandomObject('fleur', 0.95),
      _RandomObject('lapin', 0.95),
      _RandomObject('souris', 0.95),
      _RandomObject('abeille', 0.95),
      _RandomObject('papillon', 0.95),
      _RandomObject('fraise', 0.95),
      _RandomObject('carotte', 0.95),
      _RandomObject('tomate', 0.95),
      _RandomObject('vélo', 0.85),
      _RandomObject('chaise', 0.85),
      _RandomObject('table', 0.85),
      _RandomObject('livre', 0.85),
      _RandomObject('stylo', 0.85),
      _RandomObject('téléphone', 0.80),
      _RandomObject('ordinateur', 0.80),
      _RandomObject('lit', 0.85),
      _RandomObject('lampe', 0.85),
      _RandomObject('montre', 0.85),
      _RandomObject('lunettes', 0.85),
      _RandomObject('couteau', 0.85),
      _RandomObject('arbre', 0.90),
      _RandomObject('lune', 0.90),
      _RandomObject('étoile', 0.90),
      _RandomObject('pain', 0.95),
      _RandomObject('pizza', 0.85),
      _RandomObject('glace', 0.90),
      _RandomObject('chocolat', 0.90),
      _RandomObject('ballon', 0.90),
      _RandomObject('girafe', 0.85),
      _RandomObject('éléphant', 0.85),
      _RandomObject('lion', 0.85),
      _RandomObject('tigre', 0.85),
      _RandomObject('singe', 0.85),
      _RandomObject('panda', 0.85),
      _RandomObject('dauphin', 0.85),
      _RandomObject('baleine', 0.80),
      _RandomObject('train', 0.80),
      _RandomObject('avion', 0.80),
      _RandomObject('bateau', 0.85),
      _RandomObject('hélicoptère', 0.80),
      _RandomObject('pastèque', 0.90),
      _RandomObject('ananas', 0.90),
      _RandomObject('citron', 0.90),
      _RandomObject('raisin', 0.90),
      _RandomObject('cerise', 0.90),
      _RandomObject('fourchette', 0.85),
      _RandomObject('cuillère', 0.85),
      _RandomObject('assiette', 0.85),
      _RandomObject('verre', 0.85),
      _RandomObject('tasse', 0.85),
      _RandomObject('parapluie', 0.85),
      _RandomObject('hamburger', 0.85),
      _RandomObject('frites', 0.90),
    ];
  }
  
  _RandomObject _getRandomObjectByDifficulty(Difficulty difficulty) {
    final objects = _getAllRandomObjects();
    final random = Random();
    return objects[random.nextInt(objects.length)];
  }
  
  Future<String?> _uploadImage(File imageFile, String childId) async {
    debugPrint('⚠️ Image locale uniquement');
    return null;
  }
  
  // ==========================================================================
  // REJOINDRE UNE SESSION
  // ==========================================================================
  
  Future<void> joinGameSession(String sessionId, String childId) async {
    print('🔵 joinGameSession - Session: $sessionId, Enfant: $childId');
    
    // ✅ Vérifications
    if (sessionId.isEmpty) {
      throw Exception('ID de session invalide (vide)');
    }
    
    if (childId.isEmpty) {
      throw Exception('ID enfant invalide (vide)');
    }
    
    try {
      final docRef = _firestore.collection('gameSessions').doc(sessionId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Session non trouvée: $sessionId');
      }
      
      final data = doc.data()!;
      print('🔵 Données Firestore: $data');
      
      // ✅ Récupérer les indices
      final cluesList = <Clue>[];
      final cluesData = data['clues'] as List<dynamic>?;
      if (cluesData != null) {
        for (var clueMap in cluesData) {
          cluesList.add(Clue(
            clueText: clueMap['clueText'] ?? '',
            clueNumber: clueMap['clueNumber'] ?? 0,
            generatedAt: clueMap['generatedAt'] != null 
                ? DateTime.parse(clueMap['generatedAt']) 
                : DateTime.now(),
          ));
        }
      }
      
      // ✅ Conversion des valeurs (sans utiliser fromStatusCode)
      final statusValue = data['status'] ?? 0;
      GameStatus gameStatus;
      if (statusValue == 0) gameStatus = GameStatus.waiting;
      else if (statusValue == 1) gameStatus = GameStatus.inProgress;
      else gameStatus = GameStatus.finished;
      
      final modeValue = data['mode'] ?? 0;
      GameMode gameMode = modeValue == 0 ? GameMode.solo : GameMode.multiplayer;
      
      final difficultyValue = data['difficulty'] ?? 1;
      Difficulty gameDifficulty;
      if (difficultyValue == 0) gameDifficulty = Difficulty.easy;
      else if (difficultyValue == 1) gameDifficulty = Difficulty.medium;
      else gameDifficulty = Difficulty.hard;
      
      currentSession = GameSession(
        sessionId: sessionId,
        creatorChildId: data['childId'] ?? '',
        secretObjectLabel: data['secretObjectLabel'] ?? '?',
        confidence: (data['confidence'] ?? 0.5).toDouble(),
        clues: cluesList,
        currentClueIndex: data['currentClueIndex'] ?? 0,
        attemptsUsed: data['attemptsUsed'] ?? 0,
        pointsEarned: data['pointsEarned'] ?? 0,
        status: gameStatus,
        mode: gameMode,
        difficulty: gameDifficulty,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
      
      print('🟢 Session chargée avec succès');
      notifyListeners();
    } catch (e) {
      print('🔴 Erreur joinGameSession: $e');
      rethrow;
    }
  }
  
  Future<void> joinGameByCode(String joinCode, String guesserChildId) async {
    final query = await _firestore
        .collection('gameSessions')
        .where('joinCode', isEqualTo: joinCode)
        .where('status', isEqualTo: GameStatus.waiting.index)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) throw Exception("Code invalide");
    
    final doc = query.docs.first;
    await joinGameSession(doc.id, guesserChildId);
  }
  
  // ==========================================================================
  // FAIRE UNE DEVINETTE
  // ==========================================================================
  
  Future<GuessResult> makeGuess(String guess, String childId) async {
    if (currentSession == null) throw Exception("Aucune partie active");
    
    final isCorrect = _compareGuess(guess, currentSession!.secretObjectLabel);
    final attemptsUsed = currentSession!.attemptsUsed + 1;
    
    if (isCorrect) {
      int points = attemptsUsed == 1 ? 15 : (attemptsUsed == 2 ? 10 : 5);
      
      if (currentSession!.mode == GameMode.multiplayer) {
        await _firestore.collection('gameSessions').doc(currentSession!.sessionId).update({
          'status': 2,
          'attemptsUsed': attemptsUsed,
          'pointsEarned': points,
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      
      currentSession!.status = GameStatus.finished;
      currentSession!.attemptsUsed = attemptsUsed;
      currentSession!.pointsEarned = points;
      currentSession!.completedAt = DateTime.now();
      notifyListeners();
      
      return GuessResult.correct;
    } else {
      if (currentSession!.mode == GameMode.multiplayer) {
        await _firestore.collection('gameSessions').doc(currentSession!.sessionId).update({
          'attemptsUsed': attemptsUsed,
        });
      }
      
      currentSession!.attemptsUsed = attemptsUsed;
      notifyListeners();
      return GuessResult.wrong;
    }
  }
  
  bool _compareGuess(String guess, String secret) {
    final guessNorm = guess.trim().toLowerCase();
    final secretNorm = secret.trim().toLowerCase();
    
    if (guessNorm == secretNorm) return true;
    if (secretNorm.contains(guessNorm) && guessNorm.length > 2) return true;
    if (guessNorm.contains(secretNorm)) return true;
    if (guessNorm == "${secretNorm}s" || "${guessNorm}s" == secretNorm) return true;
    
    return false;
  }
  
  Stream<List<GameSession>> getAvailableGames() {
    return _firestore
        .collection('gameSessions')
        .where('status', isEqualTo: GameStatus.waiting.index)
        .where('mode', isEqualTo: GameMode.multiplayer.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameSession.fromFirestore(doc.data(), doc.id))
            .toList());
  }
  
  Future<List<GameHistory>> getGameHistory(String childId) async {
    final snapshot = await _firestore
        .collection('children')
        .doc(childId)
        .collection('gameHistory')
        .orderBy('completedAt', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs
        .map((doc) => GameHistory.fromFirestore(doc.data(), doc.id))
        .toList();
  }
  
  String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'GAME_${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }
  
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  void resetCurrentSession() {
    currentSession = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _objectDetector.close();
    super.dispose();
  }
}