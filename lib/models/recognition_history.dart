class RecognitionHistory {
  final String id;
  final String imagePath;
  final String recognizedText;
  final DateTime timestamp;
  final int charactersCount;
  final int wordsCount;
  final int linesCount;
  final String scriptUsed;

  RecognitionHistory({
    required this.id,
    required this.imagePath,
    required this.recognizedText,
    required this.timestamp,
    required this.charactersCount,
    required this.wordsCount,
    required this.linesCount,
    required this.scriptUsed,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'recognizedText': recognizedText,
    'timestamp': timestamp.toIso8601String(),
    'charactersCount': charactersCount,
    'wordsCount': wordsCount,
    'linesCount': linesCount,
    'scriptUsed': scriptUsed,
  };

  factory RecognitionHistory.fromJson(Map<String, dynamic> json) {
    return RecognitionHistory(
      id: json['id'],
      imagePath: json['imagePath'],
      recognizedText: json['recognizedText'],
      timestamp: DateTime.parse(json['timestamp']),
      charactersCount: json['charactersCount'],
      wordsCount: json['wordsCount'],
      linesCount: json['linesCount'],
      scriptUsed: json['scriptUsed'],
    );
  }
}