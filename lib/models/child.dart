import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  final String id;
  final String userId;
  final String pseudo;
  final int age;
  final String avatarUrl;
  final int level;
  final int points;
  final int daysStreak;
  final DateTime lastActive;
  final String languagePreference;
  final Map<String, bool> settings;
  final List<String> masteredLanguages;
  final DateTime createdAt;

  Child({
    required this.id,
    required this.userId,
    required this.pseudo,
    required this.age,
    required this.avatarUrl,
    this.level = 1,
    this.points = 0,
    this.daysStreak = 0,
    required this.lastActive,
    this.languagePreference = 'fr',
    required this.settings,
    required this.masteredLanguages,
    required this.createdAt,
  });

  factory Child.fromMap(String id, Map<String, dynamic> map) {
    return Child(
      id: id,
      userId: map['userId'] ?? '',
      pseudo: map['pseudo'] ?? '',
      age: map['age'] ?? 0,
      avatarUrl: map['avatarUrl'] ?? '',
      level: map['level'] ?? 1,
      points: map['points'] ?? 0,
      daysStreak: map['daysStreak'] ?? 0,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      languagePreference: map['languagePreference'] ?? 'fr',
      settings: Map<String, bool>.from(map['settings'] ?? {}),
      masteredLanguages: List<String>.from(map['masteredLanguages'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pseudo': pseudo,
      'age': age,
      'avatarUrl': avatarUrl,
      'level': level,
      'points': points,
      'daysStreak': daysStreak,
      'lastActive': Timestamp.fromDate(lastActive),
      'languagePreference': languagePreference,
      'settings': settings,
      'masteredLanguages': masteredLanguages,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get nextLevelThreshold {
    switch (level) {
      case 1: return 100;
      case 2: return 300;
      case 3: return 600;
      case 4: return 1000;
      case 5: return 1500;
      default: return 2000;
    }
  }

  double get progressToNextLevel {
    final threshold = nextLevelThreshold;
    final previousThreshold = level == 1 ? 0 : 
      level == 2 ? 100 :
      level == 3 ? 300 :
      level == 4 ? 600 :
      level == 5 ? 1000 : 1500;
    
    final current = points - previousThreshold;
    final needed = threshold - previousThreshold;
    
    if (needed <= 0) return 1.0;
    return (current / needed).clamp(0.0, 1.0);
  }

  Child copyWith({
    String? id,
    String? userId,
    String? pseudo,
    int? age,
    String? avatarUrl,
    int? level,
    int? points,
    int? daysStreak,
    DateTime? lastActive,
    String? languagePreference,
    Map<String, bool>? settings,
    List<String>? masteredLanguages,
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pseudo: pseudo ?? this.pseudo,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      points: points ?? this.points,
      daysStreak: daysStreak ?? this.daysStreak,
      lastActive: lastActive ?? this.lastActive,
      languagePreference: languagePreference ?? this.languagePreference,
      settings: settings ?? this.settings,
      masteredLanguages: masteredLanguages ?? this.masteredLanguages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}