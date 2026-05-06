import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/game_animal.dart';

class AnimalDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get userAnimals => _firestore.collection('userAnimals');
  CollectionReference get animals => _firestore.collection('animals');

  // Sauvegarder un animal découvert
  Future<void> saveDiscoveredAnimal(
    String childId,
    GameAnimal animal,
    String photoUrl,
  ) async {
    final docId = '${childId}_${animal.id}';
    
    animal.discoveredAt = DateTime.now();
    animal.photoUrl = photoUrl;
    
    final Map<String, dynamic> data = animal.toMap();
    data['childId'] = childId; // Ajouter childId au document
    
    await userAnimals.doc(docId).set(data);
    
    // Ajouter les points à l'enfant
    await _addPointsToChild(childId, animal.basePoints);
  }

  Future<void> _addPointsToChild(String childId, int points) async {
    final childRef = _firestore.collection('children').doc(childId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(childRef);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final currentPoints = (data?['points'] ?? 0) as int;
        transaction.update(childRef, {'points': currentPoints + points});
      }
    });
  }

  // Récupérer les animaux découverts par un enfant
  Stream<List<GameAnimal>> getChildAnimals(String childId) {
    return userAnimals
        .where('childId', isEqualTo: childId)  // ← CORRIGÉ : utiliser un seul Filter
        .orderBy('discoveredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;  // ← CORRIGÉ : cast explicite
              return GameAnimal.fromMap(doc.id, data);
            })
            .toList());
  }

  // Mettre à jour la progression d'une langue
  Future<void> updateLanguageProgress(
    String childId,
    String animalId,
    String languageCode,
    String progressType, // 'listened', 'scanned', 'spoken', 'unlocked'
  ) async {
    final docId = '${childId}_$animalId';
    final docRef = userAnimals.doc(docId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;  // ← CORRIGÉ : cast
        if (data == null) return;
        
        final translations = Map<String, dynamic>.from(data['translations'] ?? {});
        
        if (!translations.containsKey(languageCode)) {
          translations[languageCode] = {
            'name': _getDefaultName(animalId, languageCode),
            'isUnlocked': false,
            'isListened': false,
            'isScanned': false,
            'isSpoken': false,
          };
        }
        
        translations[languageCode][progressType] = true;
        
        // Si c'est un déverrouillage, ajouter des points bonus
        if (progressType == 'unlocked') {
          await _addPointsToChild(childId, 10);
        }
        
        transaction.update(docRef, {'translations': translations});
      }
    });
  }

  String _getDefaultName(String animalId, String languageCode) {
    const defaultNames = {
      'lion': {'fr': 'lion', 'en': 'lion', 'es': 'león', 'de': 'löwe', 'it': 'leone', 'pt': 'leão', 'nl': 'leeuw', 'ru': 'лев', 'zh': '狮子', 'ja': 'ライオン', 'ar': 'أسد', 'hi': 'शेर'},
      'elephant': {'fr': 'éléphant', 'en': 'elephant', 'es': 'elefante', 'de': 'elefant', 'it': 'elefante', 'pt': 'elefante', 'nl': 'olifant', 'ru': 'слон', 'zh': '大象', 'ja': 'ゾウ', 'ar': 'فيل', 'hi': 'हाथी'},
      'giraffe': {'fr': 'girafe', 'en': 'giraffe', 'es': 'jirafa', 'de': 'giraffe', 'it': 'giraffa', 'pt': 'girafa', 'nl': 'giraf', 'ru': 'жираф', 'zh': '长颈鹿', 'ja': 'キリン', 'ar': 'زرافة', 'hi': 'जिराफ'},
      'panda': {'fr': 'panda', 'en': 'panda', 'es': 'panda', 'de': 'panda', 'it': 'panda', 'pt': 'panda', 'nl': 'panda', 'ru': 'панда', 'zh': '熊猫', 'ja': 'パンダ', 'ar': 'باندا', 'hi': 'पांडा'},
      'dolphin': {'fr': 'dauphin', 'en': 'dolphin', 'es': 'delfín', 'de': 'delfin', 'it': 'delfino', 'pt': 'golfinho', 'nl': 'dolfijn', 'ru': 'дельфин', 'zh': '海豚', 'ja': 'イルカ', 'ar': 'دلفين', 'hi': 'डॉल्फिन'},
      'tiger': {'fr': 'tigre', 'en': 'tiger', 'es': 'tigre', 'de': 'tiger', 'it': 'tigre', 'pt': 'tigre', 'nl': 'tijger', 'ru': 'тигр', 'zh': '老虎', 'ja': 'トラ', 'ar': 'نمر', 'hi': 'बाघ'},
    };
    return defaultNames[animalId]?[languageCode] ?? animalId;
  }

  // Statistiques de l'enfant
  Future<Map<String, dynamic>> getChildGameStats(String childId) async {
    final animalsSnapshot = await userAnimals.where('childId', isEqualTo: childId).get();
    
    int totalPoints = 0;
    int totalMastery = 0;
    int unlockedLanguages = 0;
    
    for (final doc in animalsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;  // ← CORRIGÉ : cast
      final animal = GameAnimal.fromMap(doc.id, data);
      totalPoints += animal.basePoints;
      totalMastery += animal.totalMasteryPoints;
      unlockedLanguages += animal.unlockedLanguagesCount;
    }
    
    return {
      'animalsDiscovered': animalsSnapshot.docs.length,
      'totalPoints': totalPoints,
      'totalMastery': totalMastery,
      'unlockedLanguages': unlockedLanguages,
    };
  }
}