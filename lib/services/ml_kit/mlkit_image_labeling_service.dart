import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter/foundation.dart';

class MLKitImageLabelingService {
  late ImageLabeler _imageLabeler;
  bool _isInitialized = false;
  
  // Base de données des fruits et légumes pour correspondance
  static const Map<String, List<String>> foodMapping = {
    'fruit': ['apple', 'banana', 'orange', 'strawberry', 'grape', 'pear', 
              'peach', 'pineapple', 'kiwi', 'mango', 'watermelon', 'lemon',
              'pomme', 'banane', 'orange', 'fraise', 'raisin', 'poire',
              'pêche', 'ananas', 'kiwi', 'mangue', 'pastèque'],
    'vegetable': ['carrot', 'broccoli', 'tomato', 'cucumber', 'spinach', 
                  'pepper', 'cauliflower', 'eggplant', 'zucchini', 'radish',
                  'carotte', 'brocoli', 'tomate', 'concombre', 'épinard',
                  'poivron', 'chou-fleur', 'aubergine', 'courgette', 'radis'],
  };
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final options = ImageLabelerOptions(
        confidenceThreshold: 0.7,
      );
      _imageLabeler = ImageLabeler(options: options);
      _isInitialized = true;
      debugPrint('✅ Image Labeler ML Kit initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Image Labeler: $e');
    }
  }
  
  Future<FoodRecognitionResult?> recognizeFood(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      
      debugPrint('📸 Labels détectés: ${labels.map((l) => l.label).toList()}');
      
      String? detectedFood;
      String? detectedCategory;
      double bestConfidence = 0;
      
      for (final label in labels) {
        final lowerLabel = label.label.toLowerCase();
        
        // Vérifier si c'est un fruit
        for (final fruit in foodMapping['fruit']!) {
          if (lowerLabel.contains(fruit) || fruit.contains(lowerLabel)) {
            if (label.confidence > bestConfidence) {
              bestConfidence = label.confidence;
              detectedFood = _getFrenchName(lowerLabel);
              detectedCategory = 'fruit';
            }
            break;
          }
        }
        
        // Vérifier si c'est un légume
        for (final vegetable in foodMapping['vegetable']!) {
          if (lowerLabel.contains(vegetable) || vegetable.contains(lowerLabel)) {
            if (label.confidence > bestConfidence) {
              bestConfidence = label.confidence;
              detectedFood = _getFrenchName(lowerLabel);
              detectedCategory = 'vegetable';
            }
            break;
          }
        }
      }
      
      if (detectedFood != null) {
        return FoodRecognitionResult(
          foodName: detectedFood,
          category: detectedCategory!,
          confidence: bestConfidence,
          allLabels: labels.map((l) => l.label).toList(),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Erreur reconnaissance aliment: $e');
      return null;
    }
  }
  
  String _getFrenchName(String englishName) {
    const mapping = {
      'apple': 'pomme', 'banana': 'banane', 'orange': 'orange',
      'strawberry': 'fraise', 'grape': 'raisin', 'pear': 'poire',
      'peach': 'pêche', 'pineapple': 'ananas', 'kiwi': 'kiwi',
      'mango': 'mangue', 'watermelon': 'pastèque', 'carrot': 'carotte',
      'broccoli': 'brocoli', 'tomato': 'tomate', 'cucumber': 'concombre',
      'spinach': 'épinard', 'pepper': 'poivron', 'cauliflower': 'chou-fleur',
      'eggplant': 'aubergine', 'zucchini': 'courgette', 'radish': 'radis',
    };
    return mapping[englishName] ?? englishName;
  }
  
  void dispose() {
    if (_isInitialized) {
      _imageLabeler.close();
    }
  }
}

class FoodRecognitionResult {
  final String foodName;
  final String category;
  final double confidence;
  final List<String> allLabels;
  
  FoodRecognitionResult({
    required this.foodName,
    required this.category,
    required this.confidence,
    required this.allLabels,
  });
}