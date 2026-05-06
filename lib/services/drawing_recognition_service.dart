// lib/services/drawing_recognition_service.dart
import 'dart:io';
import 'dart:async';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../models/drawing_object.dart';

class DrawingRecognitionService {
  static DrawingRecognitionService? _instance;
  static DrawingRecognitionService get instance {
    _instance ??= DrawingRecognitionService._internal();
    return _instance!;
  }
  
  late final ImageLabeler _imageLabeler;
  final Map<String, List<String>> _keywordCache = {};
  final Map<String, List<String>> _synonymsCache = {};
  bool _isInitialized = false;
  
  // Statistiques de performance
  int _totalProcessed = 0;
  int _averageTime = 0;
  
  DrawingRecognitionService._internal();
   DrawingRecognitionService()
      : _imageLabeler = ImageLabeler(
          options: ImageLabelerOptions(
            confidenceThreshold: 0.35,
          ),
        );

  Future<void> init() async {
    if (_isInitialized) return;
    
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.25, // Seuil plus bas pour plus de détections
      ),
    );
    
    _buildSynonymCache();
    _isInitialized = true;
    print('✅ DrawingRecognitionService initialisé');
  }
  
  void _buildSynonymCache() {
    // Cache des synonymes pour accélérer les correspondances
    _synonymsCache['soleil'] = ['sun', 'sunshine', 'sunlight', 'rayon', 'yellow circle'];
    _synonymsCache['lune'] = ['moon', 'crescent', 'lunar', 'croissant'];
    _synonymsCache['étoile'] = ['star', 'shining', 'twinkle', 'pointu'];
    _synonymsCache['cœur'] = ['heart', 'love', 'valentine', 'coeur'];
    _synonymsCache['chat'] = ['cat', 'kitten', 'kitty', 'feline', 'miaou'];
    _synonymsCache['chien'] = ['dog', 'puppy', 'canine', 'woof', 'toutou'];
    _synonymsCache['poisson'] = ['fish', 'aquatic', 'swimming', 'nageoire'];
    _synonymsCache['oiseau'] = ['bird', 'avian', 'feathers', 'beak'];
    _synonymsCache['fleur'] = ['flower', 'blossom', 'petal', 'daisy', 'rose'];
    _synonymsCache['arbre'] = ['tree', 'wood', 'forest', 'branch', 'trunk'];
    _synonymsCache['maison'] = ['house', 'home', 'building', 'roof', 'door'];
    _synonymsCache['voiture'] = ['car', 'automobile', 'vehicle', 'auto', 'truck'];
    _synonymsCache['pomme'] = ['apple', 'fruit', 'red fruit', 'round fruit'];
    _synonymsCache['papillon'] = ['butterfly', 'insect', 'wings', 'colorful'];
    _synonymsCache['fusée'] = ['rocket', 'space', 'spaceship', 'launch'];
    _synonymsCache['dragon'] = ['dragon', 'mythical', 'fire', 'wings', 'scales'];
  }

  // Version ultra-rapide avec timeout et traitement optimisé
  Future<Map<String, dynamic>> checkDrawingFast(
    File imageFile, 
    DrawingObject targetObject
  ) async {
    final stopwatch = Stopwatch()..start();
    final completer = Completer<Map<String, dynamic>>();
    
    // Timeout pour éviter le blocage (2 secondes max)
    final timer = Timer(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        completer.complete(_timeoutResult(targetObject));
      }
    });
    
    try {
      final result = await _processImageOptimized(imageFile, targetObject);
      stopwatch.stop();
      
      _updateStats(stopwatch.elapsedMilliseconds);
      
      if (!completer.isCompleted) {
        timer.cancel();
        completer.complete(_formatResult(result, stopwatch.elapsedMilliseconds));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        timer.cancel();
        completer.complete(_errorResult(e.toString()));
      }
    }
    
    return completer.future;
  }
  
  Future<Map<String, dynamic>> _processImageOptimized(
    File imageFile, 
    DrawingObject targetObject
  ) async {
    try {
      // Optimisation: réduire la résolution de l'image pour accélérer
      final inputImage = InputImage.fromFile(imageFile);
      
      // Traitement avec priorité à la performance
      final labels = await _imageLabeler.processImage(inputImage);
      
      if (labels.isEmpty) {
        return {
          'isMatch': false,
          'confidence': 0.0,
          'message': 'Dessin non détecté',
          'suggestions': _getSuggestions(targetObject),
        };
      }
      
      // Analyse rapide: seulement les 5 meilleurs labels
      final topLabels = labels.take(5);
      String bestLabel = '';
      double bestConfidence = 0.0;
      final detectedItems = <String, double>{};
      
      for (var label in topLabels) {
        final confidence = label.confidence;
        final normalizedLabel = _normalizeFast(label.label);
        
        if (confidence > bestConfidence && confidence > 0.25) {
          bestConfidence = confidence;
          bestLabel = normalizedLabel;
        }
        detectedItems[normalizedLabel] = confidence;
      }
      
      // Vérification rapide avec cache
      final isMatch = _fastMatch(bestLabel, targetObject);
      
      if (isMatch) {
        final qualityBonus = _calculateQualityBonus(bestConfidence);
        return {
          'isMatch': true,
          'confidence': bestConfidence,
          'detectedObject': bestLabel,
          'bonus': qualityBonus,
          'message': _getSuccessMessage(bestConfidence),
          'allDetections': detectedItems,
        };
      } else {
        return {
          'isMatch': false,
          'confidence': bestConfidence,
          'detectedObject': bestLabel,
          'message': _getErrorMessage(targetObject.name),
          'suggestions': _getSuggestions(targetObject),
          'closestMatch': _getClosestMatch(detectedItems, targetObject),
        };
      }
      
    } catch (e) {
      print('❌ Erreur traitement: $e');
      return {
        'isMatch': false,
        'confidence': 0.0,
        'message': 'Erreur technique',
        'error': e.toString(),
      };
    }
  }
  
  // Normalisation ultra-rapide
  String _normalizeFast(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ïî]'), 'i')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .substring(0, text.length.clamp(0, 30));
  }
  
  // Correspondance rapide avec cache
  bool _fastMatch(String detected, DrawingObject target) {
    if (detected.isEmpty) return false;
    
    // Cache des mots-clés
    if (!_keywordCache.containsKey(target.id)) {
      _keywordCache[target.id] = target.keywords.map((k) => k.toLowerCase()).toList();
    }
    
    final keywords = _keywordCache[target.id]!;
    final detectedLower = detected.toLowerCase();
    
    // Vérification directe
    for (var keyword in keywords) {
      if (detectedLower.contains(keyword) || keyword.contains(detectedLower)) {
        return true;
      }
    }
    
    // Vérification avec synonymes
    final synonyms = _synonymsCache[target.name.toLowerCase()];
    if (synonyms != null) {
      for (var synonym in synonyms) {
        if (detectedLower.contains(synonym) || synonym.contains(detectedLower)) {
          return true;
        }
      }
    }
    
    // Vérification des mots composés
    final parts = detectedLower.split(' ');
    for (var part in parts) {
      if (part.length > 3) {
        for (var keyword in keywords) {
          if (part.contains(keyword) || keyword.contains(part)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  int _calculateQualityBonus(double confidence) {
    if (confidence > 0.8) return 20;
    if (confidence > 0.7) return 15;
    if (confidence > 0.6) return 12;
    if (confidence > 0.5) return 10;
    if (confidence > 0.4) return 7;
    return 5;
  }
  
  String _getSuccessMessage(double confidence) {
    if (confidence > 0.8) return '🎨 Parfait ! Chef-d\'œuvre ! ✨';
    if (confidence > 0.7) return '🎨 Excellent ! Beau travail ! 🏆';
    if (confidence > 0.6) return '🎨 Très bien ! Continue comme ça ! ⭐';
    if (confidence > 0.5) return '🎨 Bien joué ! Tu progresses ! 🌟';
    return '🎨 Bravo ! Bon effort ! 👍';
  }
  
  String _getErrorMessage(String objectName) {
    final messages = [
      '❌ Ce n\'est pas $objectName',
      '🎯 Essaie encore pour $objectName',
      '✏️ Un peu plus de détails pour $objectName',
      '📝 Regarde bien l\'exemple et réessaie',
      '🎨 Dessine plus grand et plus clair',
    ];
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }
  
  List<String> _getSuggestions(DrawingObject target) {
    return [
      '✏️ ${target.drawingTip}',
      '📸 Photo bien éclairée et nette',
      '🎨 Utilise des couleurs contrastées',
      '📏 Dessine l\'objet en grand',
    ];
  }
  
  String _getClosestMatch(Map<String, double> detected, DrawingObject target) {
    if (detected.isEmpty) return '';
    
    // Trouver la correspondance la plus proche
    double bestScore = 0;
    String bestMatch = '';
    
    for (var entry in detected.entries) {
      final label = entry.key;
      final confidence = entry.value;
      
      for (var keyword in target.keywords) {
        if (label.contains(keyword.toLowerCase())) {
          final score = confidence * (keyword.length / label.length);
          if (score > bestScore) {
            bestScore = score;
            bestMatch = label;
          }
        }
      }
    }
    
    return bestMatch;
  }
  
  Map<String, dynamic> _formatResult(Map<String, dynamic> result, int timeMs) {
    return {
      ...result,
      'processingTime': timeMs,
      'quickMode': true,
    };
  }
  
  Map<String, dynamic> _timeoutResult(DrawingObject target) {
    return {
      'isMatch': false,
      'confidence': 0.0,
      'message': '⏰ Temps dépassé',
      'suggestions': ['📸 Vérifie la qualité de la photo', '✏️ Dessine plus gros'],
      'timeout': true,
    };
  }
  
  Map<String, dynamic> _errorResult(String error) {
    return {
      'isMatch': false,
      'confidence': 0.0,
      'message': 'Erreur technique',
      'error': error,
    };
  }
  
  void _updateStats(int timeMs) {
    _totalProcessed++;
    _averageTime = ((_averageTime * (_totalProcessed - 1)) + timeMs) ~/ _totalProcessed;
    if (_totalProcessed % 10 == 0) {
      print('📊 Stats - Moyenne: ${_averageTime}ms, Total: $_totalProcessed');
    }
  }
  
  int getAverageTime() => _averageTime;
  int getTotalProcessed() => _totalProcessed;
  
  void dispose() {
    _imageLabeler.close();
    _keywordCache.clear();
    _synonymsCache.clear();
  }
}