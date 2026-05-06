// models/quiz_question.dart
class QuizQuestion {
  final String id;
  final String questionText;      // "Que signifie 'grand' en anglais ?"
  final String? imageUrl;         // null pour mode texte, sinon URL Firebase Storage
  final String correctAnswer;
  final List<String> options;     // 4 réponses (1 correcte + 3 distracteurs)
  final int points;
  final String category;          // "vocabulaire", "objets", etc.

  QuizQuestion({
    required this.id,
    required this.questionText,
    this.imageUrl,
    required this.correctAnswer,
    required this.options,
    required this.points,
    required this.category,
  });
}