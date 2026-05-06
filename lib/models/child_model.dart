import 'package:equatable/equatable.dart';

class ChildModel extends Equatable {
  final String id;
  final String userId;        // ID du parent
  final String pseudo;
  final int age;
  final String? avatarUrl;
  final int level;
  final int points;
  final int daysStreak;
  final DateTime lastActive;
  final String languagePreference;
  final Map<String, bool> settings;

  const ChildModel({
    required this.id,
    required this.userId,
    required this.pseudo,
    required this.age,
    this.avatarUrl,
    this.level = 1,
    this.points = 0,
    this.daysStreak = 0,
    required this.lastActive,
    this.languagePreference = 'fr',
    this.settings = const {
      'soundEnabled': true,
      'vibrationEnabled': true,
      'notificationsEnabled': true,
    },
  });

  factory ChildModel.fromMap(Map<String, dynamic> map, String id) {
    return ChildModel(
      id: id,
      userId: map['userId'] ?? '',
      pseudo: map['pseudo'] ?? '',
      age: map['age'] ?? 5,
      avatarUrl: map['avatarUrl'],
      level: map['level'] ?? 1,
      points: map['points'] ?? 0,
      daysStreak: map['daysStreak'] ?? 0,
      lastActive: (map['lastActive'] as dynamic).toDate(),
      languagePreference: map['languagePreference'] ?? 'fr',
      settings: Map<String, bool>.from(map['settings'] ?? {}),
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
      'lastActive': lastActive,
      'languagePreference': languagePreference,
      'settings': settings,
    };
  }

  @override
  List<Object?> get props => [id, pseudo, points, level];
}