import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/foundation.dart';
import '../../models/game_animal.dart';

class AnimalRecognitionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final String? matchedAnimalId;

  AnimalRecognitionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.matchedAnimalId,
  });
}

class AnimalRecognitionService {
  late ImageLabeler _imageLabeler;
  late ObjectDetector _objectDetector;
  
  // Liste des noms d'animaux à reconnaître
  static const Map<String, String> animalMapping = {
    'lion': 'lion', 'cat': 'lion', 'big cat': 'lion',
    'elephant': 'elephant', 'elephant trunk': 'elephant',
    'giraffe': 'giraffe', 'giraffe neck': 'giraffe',
    'panda': 'panda', 'panda bear': 'panda',
    'dolphin': 'dolphin', 'dolphin fish': 'dolphin',
    'tiger': 'tiger', 'tiger stripes': 'tiger',
  };

  AnimalRecognitionService() {
    _initializeServices();
  }

  void _initializeServices() {
    final imageLabelerOptions = ImageLabelerOptions(
      confidenceThreshold: 0.7,
    );
    _imageLabeler = ImageLabeler(options: imageLabelerOptions);
    
    final objectDetectorOptions = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectDetectorOptions);
  }

  Future<AnimalRecognitionResult?> recognizeAnimal(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      
      // Exécuter reconnaissance
      final labels = await _imageLabeler.processImage(inputImage);
      final objects = await _objectDetector.processImage(inputImage);
      
      if (labels.isEmpty) return null;
      
      // Chercher un label d'animal
      String? animalLabel;
      double bestConfidence = 0;
      
      for (final label in labels) {
        final lowerLabel = label.label.toLowerCase();
        
        // Vérifier si c'est un animal connu
        for (final entry in animalMapping.entries) {
          if (lowerLabel.contains(entry.key)) {
            if (label.confidence > bestConfidence) {
              bestConfidence = label.confidence;
              animalLabel = entry.value;
            }
            break;
          }
        }
      }
      
      if (animalLabel == null) return null;
      
      // Récupérer l'encadrement
      final boundingBox = objects.isEmpty 
          ? const Rect.fromLTWH(0, 0, 100, 100)
          : objects.first.boundingBox;
      
      return AnimalRecognitionResult(
        label: animalLabel,
        confidence: bestConfidence,
        boundingBox: boundingBox,
        matchedAnimalId: animalLabel,
      );
    } catch (e) {
      debugPrint('Erreur reconnaissance: $e');
      return null;
    }
  }

  void dispose() {
    _imageLabeler.close();
    _objectDetector.close();
  }
}