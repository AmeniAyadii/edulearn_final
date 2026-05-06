class ActivityModel {
  final String id;
  final String childId;
  final String activityType;
  final String title;
  final String description;
  final int points;
  final int duration;
  
  final String childName;  // ← AJOUTER CETTE LIGNE

  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityModel({
    required this.id,
    required this.childId,
    required this.activityType,
    required this.title,
    required this.description,
    required this.points,
    required this.duration,
    required this.timestamp,
    required this.childName,  // ← AJOUTER CETTE LIGNE
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'activityType': activityType,
      'title': title,
      'description': description,
      'points': points,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'childName': childName,  // ← AJOUTER CETTE LIGNE
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      childId: map['childId'],
      activityType: map['activityType'],
      title: map['title'],
      description: map['description'],
      points: map['points'],
      duration: map['duration'],
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
      childName: map['childName'],  // ← AJOUTER CETTE LIGNE
    );
  }
}