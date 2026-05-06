// lib/services/landmark_service.dart
import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

// ============================================================================
// CLASSES DE DONNÉES
// ============================================================================

class LandmarkInfo {
  final List<String> facts;
  final String funFact;
  final String question;
  final String answer;
  final String educationalContent;
  
  LandmarkInfo({
    required this.facts,
    required this.funFact,
    required this.question,
    required this.answer,
    required this.educationalContent,
  });
}

class ProcessedLandmarkResult {
  final bool success;
  final String? landmarkName;
  final String? location;
  final int confidence;
  final LandmarkInfo? info;
  final bool needsCustomInfo;
  
  ProcessedLandmarkResult({
    required this.success,
    this.landmarkName,
    this.location,
    required this.confidence,
    this.info,
    required this.needsCustomInfo,
  });
}

// ============================================================================
// SERVICE DE DÉTECTION
// ============================================================================

class LandmarkDetectionService {
  late ImageLabeler _labeler;
  
  // Base de données des monuments
  static final Map<String, Map<String, String>> _landmarkDatabase = {
    'eiffel': {
      'name': 'Tour Eiffel',
      'location': 'Paris, France',
      'facts': 'Construite en 1889 pour l\'Exposition Universelle. Hauteur: 330 mètres.',
      'funFact': 'Elle grandit l\'été ! Sous l\'effet de la chaleur, elle peut mesurer jusqu\'à 18 cm de plus 🌞',
      'question': 'En quelle année la Tour Eiffel a-t-elle été construite ?',
      'answer': '1889',
      'content': 'La Tour Eiffel est le symbole de Paris et le monument payant le plus visité au monde.'
    },
    'colosseum': {
      'name': 'Colisée',
      'location': 'Rome, Italie',
      'facts': 'Construit entre 70-80 après J.-C. Capacité: 50 000 spectateurs.',
      'funFact': 'Il pouvait être rempli d\'eau pour des batailles navales simulées ! 🌊',
      'question': 'Quel était le nom antique du Colisée ?',
      'answer': 'L\'Amphithéâtre Flavien',
      'content': 'Le Colisée est le plus grand amphithéâtre jamais construit dans l\'Empire romain.'
    },
    'pyramid': {
      'name': 'Pyramides de Gizeh',
      'location': 'Gizeh, Égypte',
      'facts': 'Construites vers 2560 av. J.-C. Hauteur originale: 146.6 mètres.',
      'funFact': 'Les pyramides sont parfaitement alignées avec les étoiles de la ceinture d\'Orion ✨',
      'question': 'Combien de pyramides y a-t-il à Gizeh ?',
      'answer': '3 pyramides principales (Khéops, Khéphren, Mykérinos)',
      'content': 'Les pyramides sont la seule merveille du monde antique encore debout.'
    },
    'taj': {
      'name': 'Taj Mahal',
      'location': 'Agra, Inde',
      'facts': 'Construit entre 1631 et 1653. 22 000 ouvriers.',
      'funFact': 'Il change de couleur selon l\'heure de la journée ! 🌅',
      'question': 'Pourquoi le Taj Mahal a-t-il été construit ?',
      'answer': 'Par l\'empereur Shah Jahan pour son épouse Mumtaz Mahal',
      'content': 'Symbole d\'amour éternel, joyau de l\'architecture moghole.'
    },
    'statue of liberty': {
      'name': 'Statue de la Liberté',
      'location': 'New York, États-Unis',
      'facts': 'Inaugurée en 1886. Cadeau de la France aux États-Unis.',
      'funFact': 'Son nez mesure 1.37 mètre de long ! 👃',
      'question': 'Que tient la statue dans sa main droite ?',
      'answer': 'Un flambeau symbolisant la liberté',
      'content': 'Symbole universel de liberté et de démocratie.'
    },
    'big ben': {
      'name': 'Big Ben',
      'location': 'Londres, Angleterre',
      'facts': 'Construite en 1859. Hauteur: 96 mètres.',
      'funFact': 'Big Ben est en réalité le nom de la cloche, pas de la tour ! 🔔',
      'question': 'Quel est le vrai nom de la tour ?',
      'answer': 'La Tour Elizabeth',
      'content': 'L\'une des attractions les plus photographiées du monde.'
    },
    'sagrada': {
      'name': 'Sagrada Familia',
      'location': 'Barcelone, Espagne',
      'facts': 'Conçue par Antoni Gaudí. Construction commencée en 1882.',
      'funFact': 'Elle n\'est toujours pas terminée après plus de 140 ans ! 🏗️',
      'question': 'Qui a conçu la Sagrada Familia ?',
      'answer': 'Antoni Gaudí',
      'content': 'Chef-d\'œuvre de l\'architecture moderniste catalane.'
    },
    'sydney opera': {
      'name': 'Opéra de Sydney',
      'location': 'Sydney, Australie',
      'facts': 'Inauguré en 1973. 1 067 000 tuiles sur la toiture.',
      'funFact': 'Les "voiles" de l\'opéra sont recouvertes de tuiles suédoises auto-nettoyantes ! 🎭',
      'question': 'Combien de salles l\'Opéra de Sydney possède-t-il ?',
      'answer': '7 salles de spectacle',
      'content': 'Chef-d\'œuvre architectural du XXe siècle.'
    },
    'great wall': {
      'name': 'Grande Muraille de Chine',
      'location': 'Chine',
      'facts': 'Construction débutée en 221 av. J.-C. Longueur: 21 196 km.',
      'funFact': 'La muraille a été construite avec du "gluant de riz" collant ! 🍚',
      'question': 'La Grande Muraille est-elle visible depuis la Lune ?',
      'answer': 'Non, c\'est un mythe !',
      'content': 'La plus longue structure construite par l\'homme.'
    },
    'christ redeemer': {
      'name': 'Christ Rédempteur',
      'location': 'Rio de Janeiro, Brésil',
      'facts': 'Inauguré en 1931. Hauteur: 38 mètres.',
      'funFact': 'Il est frappé par la foudre environ 3 à 6 fois par an ! ⚡',
      'question': 'De quel matériau est fait le Christ Rédempteur ?',
      'answer': 'Béton armé recouvert de stéatite',
      'content': 'Symbole du christianisme au Brésil.'
    },
  };
  
  LandmarkDetectionService() {
    _initializeLabeler();
  }
  
  void _initializeLabeler() {
    final options = ImageLabelerOptions(
      confidenceThreshold: 0.5,
    );
    _labeler = ImageLabeler(options: options);
  }
  
  Future<ProcessedLandmarkResult> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<ImageLabel> labels = await _labeler.processImage(inputImage);
      
      print('📸 Objets détectés: ${labels.length}');
      
      for (var label in labels) {
        print('🏷️ Label: ${label.label} - Confiance: ${label.confidence}');
        
        final landmark = _findLandmark(label.label);
        if (landmark != null && label.confidence >= 0.5) {
          return ProcessedLandmarkResult(
            success: true,
            landmarkName: landmark['name'],
            location: landmark['location'],
            confidence: (label.confidence * 100).toInt(),
            info: LandmarkInfo(
              facts: [landmark['facts']!],
              funFact: landmark['funFact']!,
              question: landmark['question']!,
              answer: landmark['answer']!,
              educationalContent: landmark['content']!,
            ),
            needsCustomInfo: false,
          );
        }
      }
      
      // Si des objets sont détectés mais pas de monument spécifique
      if (labels.isNotEmpty) {
        return ProcessedLandmarkResult(
          success: true,
          landmarkName: labels.first.label,
          location: 'Lieu d\'intérêt',
          confidence: (labels.first.confidence * 100).toInt(),
          info: null,
          needsCustomInfo: true,
        );
      }
      
      return ProcessedLandmarkResult(
        success: false,
        confidence: 0,
        info: null,
        needsCustomInfo: false,
      );
      
    } catch (e) {
      print('❌ Erreur détection: $e');
      return ProcessedLandmarkResult(
        success: false,
        confidence: 0,
        info: null,
        needsCustomInfo: false,
      );
    }
  }
  
  Map<String, String>? _findLandmark(String label) {
    final lowerLabel = label.toLowerCase();
    
    for (var entry in _landmarkDatabase.entries) {
      if (lowerLabel.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Vérification pour les variations
    final variations = {
      'tour': 'eiffel',
      'eiffel tower': 'eiffel',
      'colisee': 'colosseum',
      'colosseo': 'colosseum',
      'pyramide': 'pyramid',
      'pyramids': 'pyramid',
      'taj mahal': 'taj',
      'liberty': 'statue of liberty',
      'statue': 'statue of liberty',
      'ben': 'big ben',
      'sagrada familia': 'sagrada',
      'gaudi': 'sagrada',
      'opera': 'sydney opera',
      'mur': 'great wall',
      'china wall': 'great wall',
      'christ': 'christ redeemer',
      'redeemer': 'christ redeemer',
    };
    
    for (var variation in variations.entries) {
      if (lowerLabel.contains(variation.key)) {
        final landmark = _landmarkDatabase[variation.value];
        if (landmark != null) return landmark;
      }
    }
    
    return null;
  }
  
  void dispose() {
    _labeler.close();
  }
}