import 'package:equatable/equatable.dart';

class BadgeModel extends Equatable {
  final String id;
  final String childId;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String conditionMet;

  const BadgeModel({
    required this.id,
    required this.childId,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    required this.conditionMet,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map, String id) {
    return BadgeModel(
      id: id,
      childId: map['childId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      earnedAt: (map['earnedAt'] as dynamic).toDate(),
      conditionMet: map['conditionMet'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt,
      'conditionMet': conditionMet,
    };
  }

  @override
  List<Object?> get props => [id, name, earnedAt];
}

// Badges prédéfinis
class Badges {
  static const List<Map<String, String>> predefined = [
    {
      'name': '📖 Petit lecteur',
      'description': '10 mots lus',
      'condition': 'words_count>=10',
      'icon': 'assets/badges/reader.png'
    },
    {
      'name': '🔍 Explorateur',
      'description': '10 objets découverts',
      'condition': 'objects_count>=10',
      'icon': 'assets/badges/explorer.png'
    },
    {
      'name': '🌍 Polyglotte',
      'description': '50 traductions effectuées',
      'condition': 'translations_count>=50',
      'icon': 'assets/badges/polyglot.png'
    },
    {
      'name': '⚡ Série',
      'description': '7 jours consécutifs',
      'condition': 'streak>=7',
      'icon': 'assets/badges/streak.png'
    },
    {
      'name': '🏆 Champion',
      'description': '500 points',
      'condition': 'points>=500',
      'icon': 'assets/badges/champion.png'
    },
  ];
}