import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class MLKitOCRService {
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final script = TextRecognitionScript.latin;
      _textRecognizer = TextRecognizer(script: script);
      _isInitialized = true;
      debugPrint('✅ OCR ML Kit initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation OCR: $e');
    }
  }
  
  Future<OCRResult?> scanText(File imageFile) async {
    if (!_isInitialized) await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = recognizedText.text.trim();
      if (text.isEmpty) return null;
      
      // Extraire le premier mot/phrase
      final words = text.split(RegExp(r'\s+'));
      final firstWord = words.isNotEmpty ? words[0].toLowerCase() : '';
      
      return OCRResult(
        fullText: text,
        firstWord: firstWord,
        allWords: words,
        confidence: recognizedText.blocks.isEmpty ? 0.0 : 1.0,
      );
    } catch (e) {
      debugPrint('❌ Erreur OCR: $e');
      return null;
    }
  }
  
  Future<bool> verifyScannedWord(File imageFile, String expectedWord) async {
    final result = await scanText(imageFile);
    if (result == null) return false;
    
    final normalizedExpected = _normalizeText(expectedWord);
    final normalizedScanned = _normalizeText(result.firstWord);
    
    return normalizedScanned == normalizedExpected;
  }
  
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c');
  }
  
  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
    }
  }
}

class OCRResult {
  final String fullText;
  final String firstWord;
  final List<String> allWords;
  final double confidence;
  
  OCRResult({
    required this.fullText,
    required this.firstWord,
    required this.allWords,
    required this.confidence,
  });
}