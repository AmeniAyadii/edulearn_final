// lib/services/word_recognition_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/category_word.dart';

class WordRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String?> recognizeWordFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim().toLowerCase();
      
      if (text.isEmpty) return null;
      
      final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      return cleanText;
    } catch (e) {
      print('Erreur reconnaissance: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> recognizeWithConfidence(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim().toLowerCase();
      
      if (text.isEmpty) {
        return {'success': false, 'word': null, 'confidence': 0.0};
      }
      
      final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      return {
        'success': true,
        'word': cleanText,
        'confidence': 1.0,
      };
    } catch (e) {
      return {'success': false, 'word': null, 'confidence': 0.0, 'error': e.toString()};
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}