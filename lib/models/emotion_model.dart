// lib/models/emotion_model.dart
class EmotionModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int points;
  final int minLevel;
  final Map<String, dynamic> facialFeatures;

  EmotionModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.points,
    required this.minLevel,
    required this.facialFeatures,
  });

  static List<EmotionModel> getEmotions() {
    return [
      EmotionModel(
        id: 'happy',
        name: 'Heureux',
        emoji: '😊',
        description: 'Fais un grand sourire !',
        points: 20,
        minLevel: 1,
        facialFeatures: {'smile': true, 'eyesOpen': true, 'eyebrows': 'raised'},
      ),
      EmotionModel(
        id: 'sad',
        name: 'Triste',
        emoji: '😢',
        description: 'Fais la bouche tombante',
        points: 20,
        minLevel: 1,
        facialFeatures: {'smile': false, 'eyesOpen': true, 'eyebrows': 'lowered'},
      ),
      EmotionModel(
        id: 'surprised',
        name: 'Surpris',
        emoji: '😮',
        description: 'Ouvre grand les yeux et la bouche !',
        points: 25,
        minLevel: 2,
        facialFeatures: {'smile': false, 'eyesOpen': true, 'eyebrows': 'very_raised', 'mouthOpen': true},
      ),
      EmotionModel(
        id: 'angry',
        name: 'En colère',
        emoji: '😡',
        description: 'Fronce les sourcils !',
        points: 25,
        minLevel: 2,
        facialFeatures: {'smile': false, 'eyesOpen': false, 'eyebrows': 'furrowed'},
      ),
      EmotionModel(
        id: 'scared',
        name: 'Peur',
        emoji: '😨',
        description: 'Ouvre grand les yeux et la bouche',
        points: 30,
        minLevel: 3,
        facialFeatures: {'smile': false, 'eyesOpen': true, 'eyebrows': 'raised', 'mouthOpen': true},
      ),
      EmotionModel(
        id: 'sleepy',
        name: 'Fatigué',
        emoji: '😴',
        description: 'Ferme à moitié les yeux',
        points: 30,
        minLevel: 3,
        facialFeatures: {'smile': false, 'eyesOpen': false, 'eyebrows': 'neutral'},
      ),
    ];
  }
}