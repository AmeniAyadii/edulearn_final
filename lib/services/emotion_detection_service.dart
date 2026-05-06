// lib/services/emotion_detection_service.dart
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import '../models/emotion_model.dart';

class EmotionDetectionService {
  final FaceDetector _faceDetector;
  
  EmotionDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableContours: false,
            enableTracking: false,
            performanceMode: FaceDetectorMode.accurate,
            minFaceSize: 0.1,
          ),
        );

  Future<String?> detectEmotion(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) return null;
      
      final face = faces.first;
      return _classifyEmotion(face);
    } catch (e) {
      print('Erreur détection: $e');
      return null;
    }
  }

  String _classifyEmotion(Face face) {
    // Obtenir les probabilités avec gestion des nulls
    final smilingProb = face.smilingProbability ?? 0.0;
    final leftEyeProb = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeProb = face.rightEyeOpenProbability ?? 0.0;
    
    final bool isSmiling = smilingProb > 0.6;
    final bool areEyesOpen = leftEyeProb > 0.6 && rightEyeProb > 0.6;
    
    // Logique de détection des émotions
    if (isSmiling && areEyesOpen) {
      return 'happy';
    } else if (!isSmiling && areEyesOpen) {
      return 'sad';
    } else if (!isSmiling && !areEyesOpen) {
      return 'sleepy';
    } else if (isSmiling && !areEyesOpen) {
      return 'mischievous';
    } else {
      return 'neutral';
    }
  }

  // Version avec plus d'émotions
  String _classifyEmotionDetailed(Face face) {
    final smilingProb = face.smilingProbability ?? 0.0;
    final leftEyeProb = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeProb = face.rightEyeOpenProbability ?? 0.0;
    final double headEulerAngleY = face.headEulerAngleY ?? 0.0;
    
    final bool isSmiling = smilingProb > 0.6;
    final bool areEyesOpen = leftEyeProb > 0.6 && rightEyeProb > 0.6;
    final bool isLookingLeft = headEulerAngleY < -10;
    final bool isLookingRight = headEulerAngleY > 10;
    
    if (isSmiling && areEyesOpen) {
      if (isLookingLeft || isLookingRight) {
        return 'mischievous';
      }
      return 'happy';
    } else if (!isSmiling && areEyesOpen) {
      return 'sad';
    } else if (!isSmiling && !areEyesOpen) {
      if (smilingProb < 0.2) {
        return 'angry';
      }
      return 'sleepy';
    } else if (isSmiling && !areEyesOpen) {
      return 'cheeky';
    }
    
    return 'neutral';
  }

  Future<double> getConfidenceLevel(File imageFile, String targetEmotionId) async {
    final detectedEmotion = await detectEmotion(imageFile);
    return detectedEmotion == targetEmotionId ? 1.0 : 0.0;
  }

  Future<Map<String, dynamic>> getDetailedFaceAnalysis(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return {
          'success': false,
          'hasFace': false, 
          'emotion': null,
          'message': 'Aucun visage détecté'
        };
      }
      
      final face = faces.first;
      final emotion = _classifyEmotion(face);
      final smilingProb = face.smilingProbability ?? 0.0;
      final leftEyeProb = face.leftEyeOpenProbability ?? 0.0;
      final rightEyeProb = face.rightEyeOpenProbability ?? 0.0;
      
      return {
        'success': true,
        'hasFace': true,
        'emotion': emotion,
        'confidence': {
          'smiling': smilingProb,
          'leftEye': leftEyeProb,
          'rightEye': rightEyeProb,
        },
        'details': {
          'isSmiling': smilingProb > 0.6,
          'areEyesOpen': leftEyeProb > 0.6 && rightEyeProb > 0.6,
          'smileLevel': _getLevel(smilingProb),
          'eyesLevel': _getLevel((leftEyeProb + rightEyeProb) / 2),
        }
      };
    } catch (e) {
      print('Erreur analyse détaillée: $e');
      return {
        'success': false,
        'hasFace': false, 
        'emotion': null, 
        'error': e.toString()
      };
    }
  }

  String _getLevel(double probability) {
    if (probability > 0.8) return 'très élevé';
    if (probability > 0.6) return 'élevé';
    if (probability > 0.4) return 'moyen';
    if (probability > 0.2) return 'faible';
    return 'très faible';
  }

  void dispose() {
    _faceDetector.close();
  }
}