import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection => 
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _childrenCollection => 
      _firestore.collection('children');
  CollectionReference<Map<String, dynamic>> get _landmarksCollection => 
      _firestore.collection('landmarks');
  CollectionReference<Map<String, dynamic>> get _wordsCollection => 
      _firestore.collection('words');
  CollectionReference<Map<String, dynamic>> get _objectsCollection => 
      _firestore.collection('objects');
  CollectionReference<Map<String, dynamic>> get _badgesCollection => 
      _firestore.collection('badges');

  /// Sauvegarde une détection de monument
  Future<void> saveLandmarkDetection({
    required String childId,
    required String landmarkName,
    required String location,
    required int confidence,
    required String imageUrl,
    required int pointsEarned,
  }) async {
    try {
      final landmarkDoc = _landmarksCollection.doc();
      
      await landmarkDoc.set({
        'childId': childId,
        'landmarkName': landmarkName,
        'location': location,
        'confidence': confidence,
        'imageUrl': imageUrl,
        'pointsEarned': pointsEarned,
        'discoveredAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Mettre à jour les points de l'enfant
      await _updateChildPoints(childId, pointsEarned);
      
      // Vérifier si l'enfant a droit à un badge
      await _checkAndAwardBadge(childId);
      
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  /// Met à jour les points d'un enfant
  Future<void> _updateChildPoints(String childId, int pointsToAdd) async {
    try {
      final childRef = _childrenCollection.doc(childId);
      
      await _firestore.runTransaction((transaction) async {
        final childDoc = await transaction.get(childRef);
        
        if (childDoc.exists) {
          final childData = childDoc.data();
          final currentPoints = (childData?['points'] as int?) ?? 0;
          final newPoints = currentPoints + pointsToAdd;
          
          transaction.update(childRef, {
            'points': newPoints,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Erreur mise à jour points: $e');
    }
  }

  // lib/services/firestore_service.dart

// Ajoutez ces méthodes dans la classe FirestoreService

Future<Map<String, dynamic>?> getChildData(String childId) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .get();
    
    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (e) {
    print('Erreur getChildData: $e');
    return null;
  }
}

Future<void> updateChildProfile({
  required String childId,
  required String name,
  required String age,
  required String gender,
  required String level,
  required String avatarUrl,
}) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .update({
      'name': name,
      'age': age,
      'gender': gender,
      'level': level,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Erreur updateChildProfile: $e');
  }
}

Future<void> deleteChildProfile(String childId) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('children')
        .doc(childId)
        .delete();
  } catch (e) {
    print('Erreur deleteChildProfile: $e');
  }
}

  /// Vérifie et attribue les badges
  Future<void> _checkAndAwardBadge(String childId) async {
    try {
      // Compter le nombre de monuments découverts
      final landmarksQuery = await _landmarksCollection
          .where('childId', isEqualTo: childId)
          .count()
          .get();
      
      final landmarkCount = landmarksQuery.count;
      
      // Vérifier les conditions des badges
      List<Map<String, dynamic>> badgeConditions = [
        {'name': 'Explorateur débutant', 'minDiscoveries': 1, 'points': 50},
        {'name': 'Petit archéologue', 'minDiscoveries': 5, 'points': 100},
        {'name': 'Grand voyageur', 'minDiscoveries': 10, 'points': 250},
        {'name': 'Chasseur de monuments', 'minDiscoveries': 20, 'points': 500},
      ];
      
      for (var condition in badgeConditions) {
        final minDiscoveries = condition['minDiscoveries'] as int;
        
        if ((landmarkCount ?? 0) >= minDiscoveries) {
          // Vérifier si le badge n'a pas déjà été attribué
          final existingBadge = await _badgesCollection
              .where('childId', isEqualTo: childId)
              .where('badgeName', isEqualTo: condition['name'])
              .limit(1)
              .get();
          
          if (existingBadge.docs.isEmpty) {
            await _badgesCollection.add({
              'childId': childId,
              'badgeName': condition['name'],
              'badgeDescription': 'A découvert ${condition['minDiscoveries']} monument(s)',
              'badgeIcon': '🏆',
              'pointsEarned': condition['points'],
              'earnedAt': FieldValue.serverTimestamp(),
              'conditionMet': '${condition['minDiscoveries']}_discoveries',
            });
            
            // Ajouter les points du badge
            await _updateChildPoints(childId, condition['points'] as int);
          }
        }
      }
    } catch (e) {
      print('Erreur vérification badge: $e');
    }
  }

  /// Récupère l'historique des détections d'un enfant
  Future<List<Map<String, dynamic>>> getLandmarkHistory(String childId) async {
    try {
      final querySnapshot = await _landmarksCollection
          .where('childId', isEqualTo: childId)
          .orderBy('discoveredAt', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Erreur récupération historique: $e');
      return [];
    }
  }

  /// Récupère les statistiques d'un enfant
  Future<Map<String, dynamic>> getChildStats(String childId) async {
    try {
      final childDoc = await _childrenCollection.doc(childId).get();
      
      if (!childDoc.exists) {
        return {
          'totalDiscoveries': 0,
          'totalPoints': 0,
          'badgesCount': 0,
          'streak': 0,
        };
      }
      
      final childData = childDoc.data()!;
      
      // Compter les découvertes
      final discoveriesCount = await _landmarksCollection
          .where('childId', isEqualTo: childId)
          .count()
          .get();
      
      // Compter les badges
      final badgesCount = await _badgesCollection
          .where('childId', isEqualTo: childId)
          .count()
          .get();
      
      return {
        'totalDiscoveries': discoveriesCount.count,
        'totalPoints': childData['points'] as int? ?? 0,
        'badgesCount': badgesCount.count,
        'streak': childData['daysStreak'] as int? ?? 0,
        'level': childData['level'] as int? ?? 1,
      };
    } catch (e) {
      print('Erreur récupération stats: $e');
      return {
        'totalDiscoveries': 0,
        'totalPoints': 0,
        'badgesCount': 0,
        'streak': 0,
      };
    }
  }

  /// Sauvegarde un mot scanné (pour la fonction lecture)
  Future<void> saveWord({
    required String childId,
    required String originalWord,
    required String sourceLanguage,
    required Map<String, String> translations,
    String? imageUrl,
    int pointsEarned = 10,
  }) async {
    try {
      await _wordsCollection.add({
        'childId': childId,
        'originalWord': originalWord,
        'sourceLanguage': sourceLanguage,
        'translations': translations,
        'imageUrl': imageUrl,
        'pointsEarned': pointsEarned,
        'scannedAt': FieldValue.serverTimestamp(),
        'success': true,
      });
      
      await _updateChildPoints(childId, pointsEarned);
    } catch (e) {
      print('Erreur sauvegarde mot: $e');
      rethrow;
    }
  }

  /// Sauvegarde un objet identifié (pour les flashcards)
  Future<void> saveObject({
    required String childId,
    required String objectName,
    required String category,
    required double confidence,
    String? photoUrl,
    int pointsEarned = 15,
  }) async {
    try {
      await _objectsCollection.add({
        'childId': childId,
        'objectName': objectName,
        'category': category,
        'confidence': confidence,
        'photoUrl': photoUrl,
        'pointsEarned': pointsEarned,
        'discoveredAt': FieldValue.serverTimestamp(),
        'questionAnswered': false,
      });
      
      await _updateChildPoints(childId, pointsEarned);
    } catch (e) {
      print('Erreur sauvegarde objet: $e');
      rethrow;
    }
  }

  /// Récupère tous les enfants d'un parent
  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    try {
      final querySnapshot = await _childrenCollection
          .where('userId', isEqualTo: parentId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Erreur récupération enfants: $e');
      return [];
    }
  }

  /// Crée un nouveau profil enfant
  Future<String> createChildProfile({
    required String parentId,
    required String pseudo,
    required int age,
    String? avatarUrl,
    String languagePreference = 'fr',
  }) async {
    try {
      final docRef = await _childrenCollection.add({
        'userId': parentId,
        'pseudo': pseudo,
        'age': age,
        'avatarUrl': avatarUrl,
        'level': 1,
        'points': 0,
        'daysStreak': 0,
        'lastActive': FieldValue.serverTimestamp(),
        'languagePreference': languagePreference,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'soundEnabled': true,
          'vibrationEnabled': true,
          'notificationsEnabled': true,
        },
      });
      
      return docRef.id;
    } catch (e) {
      print('Erreur création profil: $e');
      rethrow;
    }
  }

  /// Met à jour les paramètres d'un enfant
  Future<void> updateChildSettings({
    required String childId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _childrenCollection.doc(childId).update({
        'settings': settings,
      });
    } catch (e) {
      print('Erreur mise à jour paramètres: $e');
      rethrow;
    }
  }

  /// Récupère le défi du jour
  Future<Map<String, dynamic>?> getDailyChallenge() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final querySnapshot = await _firestore
          .collection('dailyChallenges')
          .where('date', isEqualTo: today)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      
      // Créer un défi par défaut si aucun n'existe
      return {
        'type': 'discover_landmark',
        'targetValue': 1,
        'rewardPoints': 20,
        'description': 'Découvre un nouveau monument aujourd\'hui !',
        'completed': false,
      };
    } catch (e) {
      print('Erreur récupération défi: $e');
      return null;
    }
  }
}