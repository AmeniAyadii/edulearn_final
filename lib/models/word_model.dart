class WordModel {
  int? id;
  String text;
  String timestamp;
  int points;
  
  //final String? definition;  // ← AJOUTEZ CETTE LIGNE
  //final String? translation; // ← Optionnel aussi

  WordModel({
    this.id,
    required this.text,
    required this.timestamp,
    //this.definition,        // ← AJOUTEZ CETTE LIGNE
    //this.translation,       // ← Optionnel
    this.points = 10,
  });

  // Convertir un objet WordModel en Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp,
      'points': points,
      //'definition': definition,      // ← AJOUTEZ CETTE LIGNE
      //'translation': translation,    // ← Optionnel
    };
  }

  // Créer un objet WordModel à partir d'un Map (depuis la base de données)
  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'],
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? '',
      points: map['points'] ?? 10,
      //definition: map['definition'],      // ← AJOUTEZ CETTE LIGNE
      //translation: map['translation'],    // ← Optionnel
    );
  }
}