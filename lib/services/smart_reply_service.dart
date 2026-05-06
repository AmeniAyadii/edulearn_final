import 'dart:math';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';

class SmartReplyService {
  late final SmartReply _smartReply;
  final Random _random = Random();
  
  SmartReplyService() {
    _smartReply = SmartReply();
  }

  Future<List<String>> suggestReplies(String question) async {
    // Vérification null avec guard clause
    if (question.isEmpty || question.trim().isEmpty) {
      return [];
    }

    try {
      final trimmedQuestion = question.trim();
      
      _smartReply.addMessageToConversationFromLocalUser(
        trimmedQuestion,
        DateTime.now().millisecondsSinceEpoch,
      );

      final response = await _smartReply.suggestReplies();

      if (response.suggestions.isNotEmpty) {
        // ✅ Correction: Vérifier le type correctement
        final suggestions = <String>[];
        for (final suggestion in response.suggestions.take(3)) {
          final suggestionText = suggestion.toString();
          if (suggestionText.isNotEmpty) {
            suggestions.add(suggestionText);
          }
        }
        
        if (suggestions.isNotEmpty) {
          // ✅ Vérification avec toString().toLowerCase()
          final hasGenericReply = suggestions.any((s) {
            final lower = s.toString().toLowerCase();
            return lower == 'okay' || 
                   lower == 'yes' || 
                   lower == 'no' || 
                   lower == 'nothing' ||
                   lower.length < 3;
          });
          
          if (!hasGenericReply) {
            print('✅ Utilisation des suggestions ML Kit: $suggestions');
            return suggestions;
          }
        }
      }
      
      // Fallback avec réponses éducatives
      print('📚 Utilisation du fallback éducatif');
      return _getEducationalResponses(question);
      
    } catch (e) {
      print('❌ Erreur: $e');
      return _getEducationalResponses(question);
    }
  }
  
  List<String> _getEducationalResponses(String question) {
    // ✅ Vérification null
    if (question.isEmpty) {
      return [
        '✨ Please ask me a question!',
        '📚 I\'m here to help you learn.',
        '💪 What would you like to know?',
      ];
    }
    
    final q = question.toLowerCase();
    
    // Catégorie: Fruits
    if (q.contains('fruit') || q.contains('apple') || q.contains('banana')) {
      return [
        '🍎 An apple is a healthy fruit that grows on trees. It can be red, green, or yellow!',
        '🍌 A banana is a yellow fruit that gives you energy. Monkeys love them!',
        '🍊 An orange is full of vitamin C, which helps your body fight colds.',
      ];
    }
    
    // Catégorie: Animaux
    if (q.contains('animal') || q.contains('cat') || q.contains('dog')) {
      return [
        '🐱 Cats say "Meow!" They are soft, furry pets that love to sleep and play.',
        '🐶 Dogs are called "man\'s best friend." They are loyal and love to go for walks.',
        '🦁 Lions are wild cats known as the "Kings of the Jungle." They live in Africa.',
      ];
    }
    
    // Catégorie: Couleurs
    if (q.contains('color') || q.contains('blue') || q.contains('sky')) {
      return [
        '🔵 The sky is blue because sunlight scatters off the air molecules in our atmosphere!',
        '🔴 Red is a primary color. Strawberries, apples, and fire trucks are red.',
        '🟢 Green is the color of grass, leaves, and healthy plants. It represents nature!',
      ];
    }
    
    // Catégorie: Mathématiques
    if (q.contains('math') || q.contains('2+2') || q.contains('number')) {
      return [
        '🔢 2 + 2 = 4! That\'s correct! You\'re good at math!',
        '📐 Math helps us count money, tell time, and measure things.',
        '🧮 Would you like to learn multiplication? 2 x 2 = 4 as well!',
      ];
    }
    
    // Catégorie: Salutations
    if (q.contains('hello') || q.contains('hi')) {
      return [
        '👋 Hello! How can I help you learn something new today?',
        '🌟 Hi there! I\'m your AI assistant. What\'s your question?',
        '😊 Greetings! Let\'s explore and learn together!',
      ];
    }
    
    if (q.contains('how are you')) {
      return [
        '😊 I\'m doing great, thank you for asking! How can I help you?',
        '🌟 I\'m fantastic! Always happy to answer your questions.',
        '💪 I\'m doing well! What would you like to learn about?',
      ];
    }
    
    // Catégorie: Remerciements
    if (q.contains('thank')) {
      return [
        '🎉 You\'re very welcome! It\'s my pleasure to help you learn.',
        '😊 My pleasure! Feel free to ask me anything, anytime.',
        '✨ Anytime! Learning is fun, and I\'m here to help!',
      ];
    }
    
    // Réponses générales éducatives
    return [
      '✨ That\'s a great question! Keep being curious and asking questions.',
      '📚 I love helping people learn. What else would you like to know?',
      '💪 You\'re doing amazing! Every question makes you smarter.',
      '🌟 Learning is a journey, and every question is a step forward!',
    ].take(3).toList();
  }
  
  void addRemoteMessage(String message, String userId) {
    if (message.isNotEmpty) {
      try {
        _smartReply.addMessageToConversationFromRemoteUser(
          message,
          DateTime.now().millisecondsSinceEpoch,
          userId,
        );
      } catch (e) {
        print('Erreur addRemoteMessage: $e');
      }
    }
  }

  void resetConversation() {
    try {
      _smartReply.close();
    } catch (e) {
      print('Erreur reset: $e');
    }
    _smartReply = SmartReply();
  }

  void dispose() {
    try {
      _smartReply.close();
    } catch (e) {
      print('Erreur dispose: $e');
    }
  }
}