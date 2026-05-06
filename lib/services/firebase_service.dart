// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // MÉTHODES EXISTANTES (à garder)
  // ============================================================================

  Future<void> saveLandmarkDetection({
    required String childId,
    required String landmarkName,
    required String location,
    required int confidence,
    required String imageUrl,
    required int pointsEarned,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .collection('landmark_detections')
          .add({
        'landmarkName': landmarkName,
        'location': location,
        'confidence': confidence,
        'imageUrl': imageUrl,
        'pointsEarned': pointsEarned,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur saveLandmarkDetection: $e');
    }
  }

  Future<Map<String, dynamic>?> getChildStats(String childId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .get();

      if (doc.exists) {
        return {
          'gamesPlayed': doc.data()?['gamesPlayed'] ?? 0,
          'totalPoints': doc.data()?['totalPoints'] ?? 0,
          'activitiesCompleted': doc.data()?['activitiesCompleted'] ?? 0,
          'currentStreak': doc.data()?['currentStreak'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('Erreur getChildStats: $e');
      return null;
    }
  }

  Future<void> updateChildStats(String childId, {int? streak}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (streak != null) updates['currentStreak'] = streak;
      updates['lastActive'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .update(updates);
    } catch (e) {
      print('Erreur updateChildStats: $e');
    }
  }

  // ============================================================================
  // NOUVELLES MÉTHODES POUR LE PROFIL ENFANT
  // ============================================================================

  /// Récupère les données d'un enfant
  Future<Map<String, dynamic>?> getChildData(String childId) async {
    try {
      final userId = _auth.currentUser?.uid;
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
      print('❌ Erreur getChildData: $e');
      return null;
    }
  }

  /// Met à jour le profil d'un enfant
  Future<void> updateChildProfile({
    required String childId,
    required String name,
    required String age,
    required String gender,
    required String level,
    required String avatarUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
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
      
      print('✅ Profil enfant mis à jour: $name');
    } catch (e) {
      print('❌ Erreur updateChildProfile: $e');
    }
  }

  /// Supprime le profil d'un enfant
  Future<void> deleteChildProfile(String childId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Supprimer le document de l'enfant
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .delete();
      
      // Optionnel: Supprimer également toutes les sous-collections
      // (landmark_detections, game_sessions, etc.)
      await _deleteChildSubCollections(userId, childId);
      
      print('✅ Profil enfant supprimé: $childId');
    } catch (e) {
      print('❌ Erreur deleteChildProfile: $e');
    }
  }

  /// Supprime les sous-collections d'un enfant
  Future<void> _deleteChildSubCollections(String userId, String childId) async {
    try {
      final subCollections = [
        'landmark_detections',
        'game_sessions',
        'activity_history',
        'quiz_results',
      ];

      for (var collection in subCollections) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('children')
            .doc(childId)
            .collection(collection)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      
      print('✅ Sous-collections supprimées pour: $childId');
    } catch (e) {
      print('❌ Erreur suppression sous-collections: $e');
    }
  }

  /// Sauvegarde une activité dans l'historique
  Future<void> saveChildActivity({
    required String childId,
    required String activityType,
    required String title,
    required int points,
    Map<String, dynamic>? details,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .collection('activity_history')
          .add({
        'activityType': activityType,
        'title': title,
        'points': points,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mettre à jour les points totaux
      await _updateTotalPoints(childId, points);
      
      print('✅ Activité sauvegardée: $title (+$points points)');
    } catch (e) {
      print('❌ Erreur saveChildActivity: $e');
    }
  }

  /// Met à jour les points totaux de l'enfant
  Future<void> _updateTotalPoints(String childId, int points) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final childRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(childRef);
        if (snapshot.exists) {
          final currentPoints = snapshot.data()?['totalPoints'] ?? 0;
          transaction.update(childRef, {
            'totalPoints': currentPoints + points,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('❌ Erreur _updateTotalPoints: $e');
    }
  }

  /// Récupère tous les enfants d'un parent
  Future<List<Map<String, dynamic>>> getChildren() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Erreur getChildren: $e');
      return [];
    }
  }

  /// Ajoute un nouvel enfant
  Future<String?> addChild({
    required String name,
    required int age,
    required String gender,
    required String level,
    String? avatarUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .add({
        'name': name,
        'age': age.toString(),
        'gender': gender,
        'level': level,
        'avatarUrl': avatarUrl ?? '',
        'totalPoints': 0,
        'gamesPlayed': 0,
        'activitiesCompleted': 0,
        'currentStreak': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Enfant ajouté: $name');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur addChild: $e');
      return null;
    }
  }

  /// Met à jour seulement le nom de l'enfant
  Future<void> updateChildName(String childId, String newName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Nom enfant mis à jour: $newName');
    } catch (e) {
      print('❌ Erreur updateChildName: $e');
    }
  }

  /// Récupère l'historique des activités d'un enfant
  Future<List<Map<String, dynamic>>> getChildActivityHistory(
    String childId, {
    int limit = 50,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .collection('activity_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Erreur getChildActivityHistory: $e');
      return [];
    }
  }
}