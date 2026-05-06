import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;
  bool _isInitialized = false;
  
  // Singleton
  factory GeminiService() {
    _instance ??= GeminiService._internal();
    return _instance!;
  }
  
  GeminiService._internal();
  
  /// Initialiser le service avec la clé API
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) return;
    
    try {
      // Configuration du modèle Gemini
      _model = GenerativeModel(
        //model: 'gemini-pro', // Modèle gratuit et puissant
        //model: 'gemini-1.5-flash',  // Plus rapide et gratuit
        model: 'gemini-2.5-flash',  
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,    // Créativité (0 = précis, 1 = créatif)
          maxOutputTokens: 150, // Longueur max de la réponse
          topP: 0.9,
          topK: 40,
        ),
      );
      
      _isInitialized = true;
      print('✅ Gemini service initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation Gemini: $e');
      rethrow;
    }
  }
  
  /// Générer une réponse intelligente
  Future<List<String>> generateReplies(String question) async {
    if (!_isInitialized) {
      throw Exception('GeminiService non initialisé. Appelez initialize() d\'abord.');
    }
    
    if (question.isEmpty || question.trim().isEmpty) {
      return [
        '👋 Hello! How can I help you today?',
        '💡 Ask me anything about learning!',
      ];
    }
    
    try {
      // Prompt optimisé pour un assistant éducatif
      final prompt = _buildPrompt(question);
      
      // Générer la réponse
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        // Formater la réponse en suggestions
        return _formatResponse(text);
      }
      
      return _getDefaultResponses(question);
      
    } catch (e) {
      print('❌ Erreur Gemini: $e');
      return _getDefaultResponses(question);
    }
  }
  
  /// Construire un prompt éducatif
  String _buildPrompt(String question) {
    return '''
Tu es un assistant éducatif amical pour enfants (6-12 ans). 
Réponds à la question suivante de manière simple, éducative et amusante.
Utilise des émojis pour rendre la réponse plus attrayante.
Garde la réponse courte (2-3 phrases maximum).
Réponds TOUJOURS en anglais.

Question de l'enfant : "$question"

Règles importantes :
- Sois positif et encourageant
- Explique simplement mais précisément  
- Utilise des exemples concrets
- Ajoute 1 émoji pertinent par phrase

Réponse éducative :''';
  }
  
  /// Formater la réponse en suggestions
  List<String> _formatResponse(String response) {
    // Nettoyer la réponse
    String cleanResponse = response.trim();
    
    // Générer 3 variations de la même réponse
    final suggestions = <String>[];
    suggestions.add(cleanResponse);
    
    // Ajouter une version simplifiée
    if (cleanResponse.length > 80) {
      final shortened = cleanResponse.length > 100 
          ? '${cleanResponse.substring(0, 100)}...'
          : cleanResponse;
      suggestions.add(shortened);
    } else {
      suggestions.add('✨ $cleanResponse (Great question!)');
    }
    
    // Ajouter une invite pour continuer
    suggestions.add('📚 Would you like to learn more about this?');
    
    return suggestions.take(3).toList();
  }
  
  /// Réponses par défaut (fallback)
  List<String> _getDefaultResponses(String question) {
    return [
      '✨ That\'s a great question! I\'m here to help you learn.',
      '📚 Let me think about that... Ask me about fruits, animals, or colors!',
      '💪 You\'re doing amazing! Keep asking questions!',
    ];
  }
  
  /// Générer une seule réponse (simplifié)
  Future<String> generateOneReply(String question) async {
    final replies = await generateReplies(question);
    return replies.isNotEmpty ? replies.first : "I'm here to help you learn!";
  }
  
  /// Vérifier si le service est disponible
  bool isAvailable() => _isInitialized;
  
  /// Réinitialiser la conversation (optionnel)
  void resetConversation() {
    // Gemini est sans état, rien à réinitialiser
  }
}