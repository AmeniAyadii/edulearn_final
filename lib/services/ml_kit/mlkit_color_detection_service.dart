import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class MLKitColorDetectionService {
  late ImageLabeler _imageLabeler;
  bool _isInitialized = false;
  
  // Mapping des couleurs reconnues par ML Kit
  static const Map<String, String> colorKeywords = {
    'red': 'rouge',
    'rouge': 'rouge',
    'blue': 'bleu',
    'bleu': 'bleu',
    'green': 'vert',
    'vert': 'vert',
    'verte': 'vert',
    'yellow': 'jaune',
    'jaune': 'jaune',
    'orange': 'orange',
    'naranja': 'orange',
    'purple': 'violet',
    'violet': 'violet',
    'violette': 'violet',
    'pink': 'rose',
    'rose': 'rose',
    'brown': 'marron',
    'marron': 'marron',
    'brun': 'marron',
    'black': 'noir',
    'noir': 'noir',
    'white': 'blanc',
    'blanc': 'blanc',
    'blanche': 'blanc',
    'gray': 'gris',
    'grey': 'gris',
    'gris': 'gris',
  };
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final options = ImageLabelerOptions(
        confidenceThreshold: 0.6,
      );
      _imageLabeler = ImageLabeler(options: options);
      _isInitialized = true;
      debugPrint('✅ Color Detection ML Kit initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Color Detection: $e');
    }
  }
  
  // Méthode 1: Détection via ML Kit
  Future<ColorDetectionResult?> detectColorFromImageMLKit(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      
      debugPrint('🎨 Labels détectés par ML Kit: ${labels.map((l) => l.label).toList()}');
      
      String? detectedColor;
      double bestConfidence = 0;
      String? detectedObject;
      
      for (final label in labels) {
        final lowerLabel = label.label.toLowerCase();
        
        for (final entry in colorKeywords.entries) {
          if (lowerLabel.contains(entry.key)) {
            if (label.confidence > bestConfidence) {
              bestConfidence = label.confidence;
              detectedColor = entry.value;
              detectedObject = label.label;
            }
            break;
          }
        }
      }
      
      if (detectedColor == null && labels.isNotEmpty) {
        detectedColor = _guessColorFromLabels(labels);
        if (detectedColor != null) {
          bestConfidence = 0.5;
        }
      }
      
      if (detectedColor != null) {
        return ColorDetectionResult(
          colorName: detectedColor,
          confidence: bestConfidence,
          allLabels: labels.map((l) => l.label).toList(),
          detectedObject: detectedObject,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Erreur détection couleur ML Kit: $e');
      return null;
    }
  }
  
  // Méthode 2: Détection par analyse des pixels
  Future<ColorDetectionResult?> detectDominantColor(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Redimensionner pour accélérer l'analyse
      final img.Image resized = img.copyResize(image, width: 100, height: 100);
      
      // Compter les couleurs dominantes
      final Map<int, int> colorCounts = {};
      
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          
          // Convertir num en int
          final int r = pixel.r.toInt();
          final int g = pixel.g.toInt();
          final int b = pixel.b.toInt();
          
          // Arrondir les couleurs pour les regrouper
          final int roundedR = (r / 50).round() * 50;
          final int roundedG = (g / 50).round() * 50;
          final int roundedB = (b / 50).round() * 50;
          
          final int colorKey = (roundedR << 16) | (roundedG << 8) | roundedB;
          
          colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
        }
      }
      
      if (colorCounts.isNotEmpty) {
        final dominantColorValue = colorCounts.entries.reduce(
          (a, b) => a.value > b.value ? a : b
        ).key;
        
        final int r = (dominantColorValue >> 16) & 0xFF;
        final int g = (dominantColorValue >> 8) & 0xFF;
        final int b = dominantColorValue & 0xFF;
        
        final String colorName = _getColorNameFromRGB(r, g, b);
        final Color color = Color.fromARGB(255, r, g, b);
        
        return ColorDetectionResult(
          colorName: colorName,
          confidence: 0.8,
          allLabels: ['Couleur dominante'],
          detectedObject: null,
          dominantColor: color,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Erreur analyse couleur dominante: $e');
      return null;
    }
  }
  
  // Méthode 3: Détection par couleur centrale (plus simple)
  Future<String?> detectCenterColor(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final img.Pixel centerPixel = image.getPixel(centerX, centerY);
      
      final int r = centerPixel.r.toInt();
      final int g = centerPixel.g.toInt();
      final int b = centerPixel.b.toInt();
      
      return _getColorNameFromRGB(r, g, b);
    } catch (e) {
      debugPrint('Erreur détection couleur centrale: $e');
      return null;
    }
  }
  
  // Méthode combinée (recommandée)
  Future<ColorDetectionResult?> detectColor(File imageFile) async {
    // Essayer d'abord ML Kit
    final mlResult = await detectColorFromImageMLKit(imageFile);
    if (mlResult != null && mlResult.confidence > 0.7) {
      return mlResult;
    }
    
    // Sinon analyser les pixels
    final pixelResult = await detectDominantColor(imageFile);
    if (pixelResult != null) {
      return pixelResult;
    }
    
    // En dernier recours, prendre la couleur centrale
    final centerColor = await detectCenterColor(imageFile);
    if (centerColor != null) {
      return ColorDetectionResult(
        colorName: centerColor,
        confidence: 0.4,
        allLabels: ['Couleur centrale'],
        detectedObject: null,
      );
    }
    
    return null;
  }
  
  String? _guessColorFromLabels(List<ImageLabel> labels) {
    const Map<String, String> objectColorMap = {
      'apple': 'rouge', 'pomme': 'rouge',
      'banana': 'jaune', 'banane': 'jaune',
      'orange': 'orange',
      'lemon': 'jaune', 'citron': 'jaune',
      'grape': 'violet', 'raisin': 'violet',
      'strawberry': 'rouge', 'fraise': 'rouge',
      'blueberry': 'bleu', 'myrtille': 'bleu',
      'carrot': 'orange', 'carotte': 'orange',
      'tomato': 'rouge', 'tomate': 'rouge',
      'cucumber': 'vert', 'concombre': 'vert',
      'broccoli': 'vert', 'brocoli': 'vert',
      'sky': 'bleu', 'ciel': 'bleu',
      'grass': 'vert', 'herbe': 'vert',
      'flower': 'rose', 'fleur': 'rose',
      'sun': 'jaune', 'soleil': 'jaune',
      'rose': 'rose',
    };
    
    for (final label in labels) {
      final String lowerLabel = label.label.toLowerCase();
      for (final entry in objectColorMap.entries) {
        if (lowerLabel.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }
  
  String _getColorNameFromRGB(int r, int g, int b) {
    // Couleurs primaires
    if (r > g && r > b && r - g > 50 && r - b > 50) return 'rouge';
    if (g > r && g > b && g - r > 50 && g - b > 50) return 'vert';
    if (b > r && b > g && b - r > 50 && b - g > 50) return 'bleu';
    
    // Couleurs secondaires
    if (r > 200 && g > 150 && b < 100) return 'orange';
    if (r > 200 && g > 200 && b < 100) return 'jaune';
    if (r > 200 && g < 150 && b > 200) return 'violet';
    if (r > 200 && g < 150 && b > 150) return 'rose';
    
    // Neutres
    if (r < 50 && g < 50 && b < 50) return 'noir';
    if (r > 200 && g > 200 && b > 200) return 'blanc';
    
    final int avg = (r + g + b) ~/ 3;
    if (avg > 100 && avg < 180) return 'gris';
    
    // Détection par dominance
    if (r > g && r > b) return 'rouge';
    if (g > r && g > b) return 'vert';
    if (b > r && b > g) return 'bleu';
    
    return 'gris';
  }
  
  void dispose() {
    if (_isInitialized) {
      _imageLabeler.close();
    }
  }
}

class ColorDetectionResult {
  final String colorName;
  final double confidence;
  final List<String> allLabels;
  final String? detectedObject;
  final Color? dominantColor;
  
  ColorDetectionResult({
    required this.colorName,
    required this.confidence,
    required this.allLabels,
    this.detectedObject,
    this.dominantColor,
  });
}