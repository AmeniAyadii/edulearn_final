// lib/services/object_detection_service.dart
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'dart:io';
import '../models/game_object_model.dart';

class ObjectDetectionService {
  late final ImageLabeler _imageLabeler;
  late final ImageLabeler _customImageLabeler;
  
  ObjectDetectionService() {
    _initDetectors();
  }

  void _initDetectors() {
    // Détecteur standard avec seuil de confiance élevé
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.5, // Seuil abaissé pour plus de détections
      ),
    );
    
    // Détecteur personnalisé pour les objets quotidiens
    _customImageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.4,
      ),
    );
  }

  // Version améliorée avec multiple passes et post-traitement
  Future<Map<String, dynamic>> detectObjectWithDetails(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      
      // 1. Détection avec le détecteur standard
      final List<ImageLabel> standardLabels = await _imageLabeler.processImage(inputImage);
      
      // 2. Détection avec le détecteur personnalisé
      final List<ImageLabel> customLabels = await _customImageLabeler.processImage(inputImage);
      
      // 3. Fusionner et optimiser les résultats
      final allLabels = <String, double>{};
      
      for (var label in standardLabels) {
        final key = label.label.toLowerCase();
        final confidence = label.confidence;
        if (confidence > 0.4) {
          allLabels[key] = allLabels.containsKey(key) 
              ? (allLabels[key]! + confidence) / 2 
              : confidence;
        }
      }
      
      for (var label in customLabels) {
        final key = label.label.toLowerCase();
        final confidence = label.confidence;
        if (confidence > 0.4) {
          allLabels[key] = allLabels.containsKey(key) 
              ? (allLabels[key]! + confidence) / 2 
              : confidence;
        }
      }
      
      // 4. Post-traitement : nettoyer et normaliser
      final processedLabels = _postProcessLabels(allLabels);
      
      // 5. Obtenir le meilleur résultat
      if (processedLabels.isEmpty) {
        return _createEmptyResult();
      }
      
      final bestEntry = processedLabels.entries.reduce((a, b) => 
          a.value > b.value ? a : b);
      
      return {
        'success': true,
        'detectedObject': bestEntry.key,
        'confidence': bestEntry.value,
        'allLabels': processedLabels.entries.map((e) => ({
          'label': e.key,
          'confidence': e.value,
        })).toList(),
        'rawLabels': allLabels,
      };
      
    } catch (e) {
      print('Erreur détection détaillée: $e');
      return _createErrorResult(e.toString());
    }
  }

  // Post-traitement des labels
  Map<String, double> _postProcessLabels(Map<String, double> labels) {
    final processed = <String, double>{};
    final synonyms = _getSynonyms();
    
    for (var entry in labels.entries) {
      String label = entry.key;
      double confidence = entry.value;
      
      // Normaliser le label
      label = _normalizeLabel(label);
      
      // Vérifier les synonymes
      String? mainLabel = _getMainLabel(label, synonyms);
      if (mainLabel != null) {
        processed[mainLabel] = processed.containsKey(mainLabel)
            ? (processed[mainLabel]! + confidence) / 2
            : confidence;
      } else {
        processed[label] = confidence;
      }
    }
    
    return processed;
  }

  // Normaliser le label (enlever accents, pluriel, etc.)
  String _normalizeLabel(String label) {
    // Convertir en minuscules
    label = label.toLowerCase();
    
    // Supprimer les accents
    label = label
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i');
    
    // Supprimer le pluriel (s/x)
    if (label.endsWith('s') || label.endsWith('x')) {
      label = label.substring(0, label.length - 1);
    }
    
    return label;
  }

  // Obtenir le label principal à partir des synonymes
  String? _getMainLabel(String label, Map<String, List<String>> synonyms) {
    for (var entry in synonyms.entries) {
      if (entry.key == label || entry.value.contains(label)) {
        return entry.key;
      }
    }
    return null;
  }

  // Dictionnaire des synonymes
  Map<String, List<String>> _getSynonyms() {
    return {
      'pomme': ['apple', 'fruit rouge', 'pomme rouge', 'pomme verte'],
      'banane': ['banana', 'fruit jaune', 'banane jaune'],
      'orange': ['fruit orange', 'orange fruit', 'clémentine'],
      'fraise': ['strawberry', 'fruit rouge', 'fraise rouge'],
      'raisin': ['grape', 'fruit violet', 'raisin violet'],
      'poire': ['pear', 'fruit vert', 'poire verte'],
      'cerise': ['cherry', 'fruit rouge', 'cerise rouge'],
      'citron': ['lemon', 'fruit jaune', 'citron jaune'],
      'pastèque': ['watermelon', 'fruit vert', 'pastèque verte'],
      'carotte': ['carrot', 'légume orange', 'carotte orange'],
      'tomate': ['tomato', 'légume rouge', 'fruit rouge'],
      'brocoli': ['broccoli', 'légume vert', 'brocoli vert'],
      'concombre': ['cucumber', 'légume vert', 'concombre vert'],
      'aubergine': ['eggplant', 'légume violet', 'aubergine violette'],
      'chat': ['cat', 'chatte', 'minou', 'félin'],
      'chien': ['dog', 'chienne', 'toutou', 'canin'],
      'oiseau': ['bird', 'oiseau', 'petit oiseau'],
      'poisson': ['fish', 'poisson rouge', 'poisson d\'aquarium'],
      'lapin': ['rabbit', 'lapin blanc', 'petit lapin'],
      'ours': ['bear', 'ours brun', 'ours blanc'],
      'lion': ['lion', 'lionceau', 'fauve'],
      'éléphant': ['elephant', 'éléphant d\'afrique', 'pachyderme'],
      'girafe': ['giraffe', 'girafe d\'afrique'],
      'singe': ['monkey', 'singe', 'petit singe'],
      'panda': ['panda', 'panda roux'],
      'voiture': ['car', 'automobile', 'véhicule', 'auto'],
      'camion': ['truck', 'camion', 'poids lourd'],
      'moto': ['motorcycle', 'moto', 'motocyclette'],
      'vélo': ['bicycle', 'bike', 'vélo', 'cyclisme'],
      'avion': ['airplane', 'plane', 'avion', 'aéronef'],
      'bateau': ['ship', 'boat', 'bateau', 'navire'],
      'train': ['train', 'train', 'locomotive'],
      'livre': ['book', 'livre', 'bouquin', 'roman'],
      'stylo': ['pen', 'stylo', 'stylo bille'],
      'crayon': ['pencil', 'crayon', 'crayon à papier'],
      'téléphone': ['phone', 'smartphone', 'téléphone', 'mobile'],
      'montre': ['watch', 'montre', 'bracelet montre'],
      'lunettes': ['glasses', 'lunettes', 'lunettes de vue'],
      'chapeau': ['hat', 'chapeau', 'casquette'],
      'chaussure': ['shoe', 'chaussure', 'basket', 'sneaker'],
      'balle': ['ball', 'balle', 'ballon'],
    };
  }

  // Détection avec score de confiance amélioré
  Future<Map<String, dynamic>> detectWithConfidence(File imageFile, GameObjectModel targetObject) async {
    final result = await detectObjectWithDetails(imageFile);
    
    if (!result['success'] || result['detectedObject'] == null) {
      return {
        'isMatch': false,
        'confidence': 0.0,
        'message': 'Aucun objet détecté',
        'suggestions': [],
      };
    }
    
    final detectedLabel = result['detectedObject'] as String;
    final confidence = result['confidence'] as double;
    final isMatch = matchesObject(detectedLabel, targetObject);
    
    // Calculer un score de correspondance plus précis
    double matchScore = 0.0;
    String matchMessage = '';
    List<String> suggestions = [];
    
    if (isMatch) {
      // Bonus si correspondance exacte
      if (detectedLabel == targetObject.name.toLowerCase()) {
        matchScore = confidence * 1.2; // Bonus 20%
        matchMessage = '✅ Parfait ! Objet bien reconnu';
      } else {
        matchScore = confidence;
        matchMessage = '✅ Bonne correspondance';
      }
      
      // Vérifier la qualité de l'image
      if (confidence < 0.6) {
        matchMessage = '⚠️ Objet reconnu, mais image peu claire';
        suggestions.add('📸 Prenez une photo mieux éclairée');
        suggestions.add('🔍 Rapprochez l\'objet de la caméra');
      }
    } else {
      // Proposer des suggestions
      matchScore = 0.0;
      matchMessage = '❌ Ce n\'est pas le bon objet';
      
      // Trouver l'objet le plus proche
      final possibleMatches = result['allLabels'] as List;
      if (possibleMatches.isNotEmpty) {
        final bestMatch = possibleMatches.first;
        suggestions.add('🎯 Objet détecté: ${bestMatch['label']}');
        suggestions.add('💡 Essayez avec un ${targetObject.name}');
        
        // Améliorer l'éclairage
        if (confidence < 0.5) {
          suggestions.add('💡 Améliorez l\'éclairage');
          suggestions.add('📱 Placez l\'objet sur un fond uni');
        }
      } else {
        suggestions.add('🔍 Aucun objet détecté');
        suggestions.add('📸 Assurez-vous que l\'objet est bien visible');
        suggestions.add('💡 Éclairez mieux la scène');
      }
    }
    
    // Calculer les points bonus
    int bonusPoints = 0;
    if (isMatch) {
      if (confidence > 0.85) bonusPoints = 15;
      else if (confidence > 0.7) bonusPoints = 10;
      else if (confidence > 0.6) bonusPoints = 5;
    }
    
    return {
      'isMatch': isMatch,
      'confidence': confidence,
      'matchScore': matchScore.clamp(0.0, 1.0),
      'detectedLabel': detectedLabel,
      'message': matchMessage,
      'suggestions': suggestions,
      'bonusPoints': bonusPoints,
      'allDetections': result['allLabels'],
    };
  }

  // Détection par lot pour améliorer la précision
  Future<Map<String, dynamic>> detectMultipleTimes(File imageFile, int attempts) async {
    double totalConfidence = 0.0;
    String? bestLabel;
    double bestConfidence = 0.0;
    final allDetections = <String, double>{};
    
    for (int i = 0; i < attempts; i++) {
      try {
        final result = await detectObjectWithDetails(imageFile);
        if (result['success'] && result['detectedObject'] != null) {
          final label = result['detectedObject'] as String;
          final confidence = result['confidence'] as double;
          
          totalConfidence += confidence;
          
          if (confidence > bestConfidence) {
            bestConfidence = confidence;
            bestLabel = label;
          }
          
          allDetections[label] = (allDetections[label] ?? 0) + confidence;
        }
        
        // Petit délai entre les tentatives
        await Future.delayed(Duration(milliseconds: 100 * i));
      } catch (e) {
        print('Erreur tentative $i: $e');
      }
    }
    
    final avgConfidence = attempts > 0 ? totalConfidence / attempts : 0.0;
    
    return {
      'detectedObject': bestLabel,
      'confidence': bestConfidence,
      'averageConfidence': avgConfidence,
      'allDetections': allDetections,
    };
  }

  // Vérifier la qualité de l'image
  Future<Map<String, dynamic>> checkImageQuality(File imageFile) async {
    try {
      final result = await detectObjectWithDetails(imageFile);
      
      if (result['allLabels'] == null || (result['allLabels'] as List).isEmpty) {
        return {
          'isGoodQuality': false,
          'message': 'Aucun objet détecté, image peu claire',
          'suggestions': [
            '📸 Prenez une photo mieux éclairée',
            '🔍 Placez l\'objet au centre',
            '📱 Utilisez un fond uni',
          ],
        };
      }
      
      final topLabel = (result['allLabels'] as List).first;
      final confidence = topLabel['confidence'] as double;
      
      if (confidence > 0.7) {
        return {
          'isGoodQuality': true,
          'message': 'Excellente qualité d\'image !',
          'confidence': confidence,
        };
      } else if (confidence > 0.5) {
        return {
          'isGoodQuality': true,
          'message': 'Bonne qualité, mais peut être améliorée',
          'confidence': confidence,
          'suggestions': [
            '💡 Augmentez un peu l\'éclairage',
            '📸 Stabilisez mieux l\'appareil',
          ],
        };
      } else {
        return {
          'isGoodQuality': false,
          'message': 'Image floue ou mal éclairée',
          'confidence': confidence,
          'suggestions': [
            '💡 Améliorez l\'éclairage',
            '📱 Placez l\'objet sur un fond contrasté',
            '🔍 Rapprochez-vous de l\'objet',
            '🖼️ Évitez les arrière-plans chargés',
          ],
        };
      }
    } catch (e) {
      return {
        'isGoodQuality': false,
        'message': 'Erreur d\'analyse',
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _createEmptyResult() {
    return {
      'success': false,
      'detectedObject': null,
      'confidence': 0.0,
      'allLabels': [],
      'message': 'Aucun objet détecté',
      'suggestions': [
        '📸 Prenez une photo mieux éclairée',
        '🔍 Placez l\'objet bien en évidence',
        '📱 Utilisez un fond clair et uni',
        '💡 Assurez-vous que l\'objet est net',
      ],
    };
  }

  Map<String, dynamic> _createErrorResult(String error) {
    return {
      'success': false,
      'detectedObject': null,
      'confidence': 0.0,
      'allLabels': [],
      'error': error,
      'message': 'Erreur technique, réessayez',
    };
  }

  bool matchesObject(String detectedLabel, GameObjectModel targetObject) {
    final labelLower = detectedLabel.toLowerCase();
    final processedTarget = _normalizeLabel(targetObject.name.toLowerCase());
    
    // Vérification exacte
    if (labelLower == processedTarget) {
      return true;
    }
    
    // Vérification dans les mots-clés
    for (var keyword in targetObject.keywords) {
      if (labelLower.contains(_normalizeLabel(keyword.toLowerCase()))) {
        return true;
      }
    }
    
    // Vérification dans les synonymes
    final synonyms = _getSynonyms();
    for (var entry in synonyms.entries) {
      if (entry.key == processedTarget || entry.value.map((e) => _normalizeLabel(e)).contains(labelLower)) {
        // Le label détecté correspond à un synonyme de l'objet cible
        return true;
      }
    }
    
    return false;
  }

  Future<double> getMatchingScore(File imageFile, GameObjectModel targetObject) async {
    final result = await detectWithConfidence(imageFile, targetObject);
    return result['confidence'] ?? 0.0;
  }

  void dispose() {
    _imageLabeler.close();
    _customImageLabeler.close();
  }
}