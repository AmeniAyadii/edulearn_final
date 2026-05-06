import 'package:equatable/equatable.dart';

class ObjectModel extends Equatable {
  final String id;
  final String childId;
  final String objectName;
  final String category;
  final double confidence;
  final String photoUrl;
  final DateTime discoveredAt;
  final int pointsEarned;
  final bool questionAnswered;

  const ObjectModel({
    required this.id,
    required this.childId,
    required this.objectName,
    required this.category,
    required this.confidence,
    required this.photoUrl,
    required this.discoveredAt,
    required this.pointsEarned,
    this.questionAnswered = true,
  });

  factory ObjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ObjectModel(
      id: id,
      childId: map['childId'] ?? '',
      objectName: map['objectName'] ?? '',
      category: map['category'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      photoUrl: map['photoUrl'] ?? '',
      discoveredAt: (map['discoveredAt'] as dynamic).toDate(),
      pointsEarned: map['pointsEarned'] ?? 15,
      questionAnswered: map['questionAnswered'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'objectName': objectName,
      'category': category,
      'confidence': confidence,
      'photoUrl': photoUrl,
      'discoveredAt': discoveredAt,
      'pointsEarned': pointsEarned,
      'questionAnswered': questionAnswered,
    };
  }

  @override
  List<Object?> get props => [id, objectName, discoveredAt];
}