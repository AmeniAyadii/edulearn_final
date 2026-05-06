class WordHistory {
  final int id;
  final String word;
  final int points;
  final DateTime timestamp;
  final String? definition;
  final String? translation;
  final bool isFavorite;

  WordHistory({
    required this.id,
    required this.word,
    required this.points,
    required this.timestamp,
    this.definition,
    this.translation,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'definition': definition,
      'translation': translation,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory WordHistory.fromMap(Map<String, dynamic> map) {
    return WordHistory(
      id: map['id'],
      word: map['word'],
      points: map['points'],
      timestamp: DateTime.parse(map['timestamp']),
      definition: map['definition'],
      translation: map['translation'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateShort {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (timestamp.isAfter(today)) {
      return "Aujourd'hui";
    } else if (timestamp.isAfter(yesterday)) {
      return "Hier";
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}