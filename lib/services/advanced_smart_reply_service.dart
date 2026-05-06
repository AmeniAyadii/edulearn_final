import 'package:edulearn_final/services/kit_service.dart' as kit_service;
import '../models/conversation_model.dart';

class AdvancedSmartReplyService {
  // Modèles de réponses par catégorie
  final Map<String, List<String>> _responseTemplates = {
    'salutation': [
      'Bonjour ! Comment puis-je vous aider ?',
      'Bonjour, ravi de vous voir ! Que puis-je faire pour vous ?',
      'Bonjour ! Posez-moi votre question, je vous répondrai avec plaisir.',
    ],
    'remplissage': [
      'Je comprends votre question. Permettez-moi d\'y réfléchir...',
      'Excellente question ! Laissez-moi analyser cela pour vous.',
      'Je vois ce que vous demandez. Voici ce que je peux vous dire...',
    ],
    'aide': [
      'Voici comment je peux vous aider...',
      'Je serais ravi de vous aider avec cela. Voici ce que je propose...',
      'Pour vous aider au mieux, voici plusieurs suggestions...',
    ],
    'positif': [
      'Merci pour votre retour positif ! ✨',
      'Je suis ravi que cela vous plaise ! 😊',
      'Au plaisir de vous aider à nouveau ! 🌟',
    ],
    'negatif': [
      'Je suis désolé de lire cela. Comment puis-je améliorer mon aide ?',
      'Je comprends votre frustration. Laissez-moi trouver une meilleure solution.',
      'Toutes mes excuses. Que puis-je faire pour vous aider différemment ?',
    ],
    'general': [
      'Merci pour votre question. Voici quelques éléments de réponse...',
      'Je vous remercie pour votre message. Permettez-moi de vous donner mon avis...',
      'C\'est une interrogation pertinente. Je vous suggère de considérer...',
      'Je vais vous aider à trouver la meilleure réponse pour cela.',
      'Excellente question ! Voici ce que je peux vous recommander...',
      'Je comprends votre demande. Voici plusieurs pistes de réflexion...',
    ],
  };
  
  // Base de connaissances simple
  final Map<String, String> _knowledgeBase = {
    'flutter': 'Flutter est un framework UI open-source créé par Google pour développer des applications multiplateformes (iOS, Android, Web, Desktop) à partir d\'un seul codebase.',
    'dart': 'Dart est un langage de programmation optimisé pour le développement d\'applications multiplateformes, utilisé principalement avec Flutter.',
    'ia': 'L\'Intelligence Artificielle est un domaine de l\'informatique qui vise à créer des systèmes capables d\'apprendre et de prendre des décisions.',
    'machine learning': 'Le Machine Learning est une branche de l\'IA qui permet aux systèmes d\'apprendre à partir de données sans être programmés explicitement pour chaque tâche.',
  };
  
  Future<void> initialize() async {
    // Simuler le chargement de modèles
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<List<String>> generateSmartReplies(
    String text, {
    required List<Message> context, // Maintenant sans ambiguïté
    required Map<String, dynamic> analysis,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final lowerText = text.toLowerCase();
    final List<String> suggestions = [];
    
    // 1. Vérifier la base de connaissances
    for (final entry in _knowledgeBase.entries) {
      if (lowerText.contains(entry.key)) {
        suggestions.add(entry.value);
        break;
      }
    }
    
    // 2. Analyser le sentiment pour adapter la réponse
    final sentiment = analysis['sentiment']['label'];
    if (sentiment == 'positif') {
      suggestions.add(_getRandomResponse('positif'));
    } else if (sentiment == 'négatif') {
      suggestions.add(_getRandomResponse('negatif'));
    }
    
    // 3. Vérifier le type de question
    if (lowerText.startsWith('comment')) {
      suggestions.add('Pour ${_extractSubject(lowerText)}, je vous recommande de commencer par...');
      suggestions.add('Une bonne approche serait de...');
    } else if (lowerText.startsWith('pourquoi')) {
      suggestions.add('La raison principale est que...');
      suggestions.add('Cela s\'explique par le fait que...');
    } else if (lowerText.contains('bonjour') || lowerText.contains('salut')) {
      suggestions.add(_getRandomResponse('salutation'));
    }
    
    // 4. Ajouter des suggestions générales
    final generalResponse = _getRandomResponse('general');
    if (!suggestions.contains(generalResponse)) {
      suggestions.add(generalResponse);
    }
    
    suggestions.add(_getRandomResponse('remplissage'));
    suggestions.add('${_getRandomResponse('aide')} N\'hésitez pas à me poser d\'autres questions !');
    
    // Limiter à 4 suggestions pertinentes
    return suggestions.take(4).toList();
  }
  
  String _getRandomResponse(String category) {
    final responses = _responseTemplates[category] ?? _responseTemplates['general']!;
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }
  
  String _extractSubject(String question) {
    // Extraction simple du sujet
    final words = question.split(' ');
    if (words.length > 1) {
      return words.sublist(1, words.length > 4 ? 4 : words.length).join(' ');
    }
    return 'cette question';
  }
  
  void dispose() {
    // Nettoyage des ressources
  }
}