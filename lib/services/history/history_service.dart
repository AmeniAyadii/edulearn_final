// lib/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final DateTime timestamp;
  final int points;
  final Map<String, dynamic> details;
  final String childId;
  final String childName;

  HistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.timestamp,
    required this.points,
    required this.details,
    required this.childId,
    required this.childName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'timestamp': Timestamp.fromDate(timestamp),
    'points': points,
    'details': details,
    'childId': childId,
    'childName': childName,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json, String id) => HistoryItem(
    id: id,
    type: json['type'],
    title: json['title'],
    subtitle: json['subtitle'],
    imageUrl: json['imageUrl'],
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    points: json['points'],
    details: json['details'] ?? {},
    childId: json['childId'],
    childName: json['childName'],
  );
}

class HistoryFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userId => _auth.currentUser?.uid ?? 'anonymous';
  
  Future<void> saveHistoryItem(HistoryItem item) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(item.id)
          .set(item.toJson());
      print('✅ Historique sauvegardé: ${item.title}');
    } catch (e) {
      print('❌ Erreur sauvegarde historique: $e');
    }
  }
}