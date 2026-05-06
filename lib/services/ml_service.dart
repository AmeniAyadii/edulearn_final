import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MLService {
  // ============ SERVICES ============

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final LanguageIdentifier _languageIdentifier =
      LanguageIdentifier(confidenceThreshold: 0.5);

  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.7),
  );

  // Translators
  OnDeviceTranslator? _translatorFrEn;
  OnDeviceTranslator? _translatorFrAr;
  OnDeviceTranslator? _translatorEnFr;
  OnDeviceTranslator? _translatorArFr;

  MLService() {
    _initTranslators();
  }

  // ============ INIT TRANSLATORS ============

  Future<void> _initTranslators() async {
    _translatorFrEn = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.french,
      targetLanguage: TranslateLanguage.english,
    );

    _translatorFrAr = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.french,
      targetLanguage: TranslateLanguage.arabic,
    );

    _translatorEnFr = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.french,
    );

    _translatorArFr = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.arabic,
      targetLanguage: TranslateLanguage.french,
    );
  }

  // ============ OCR ============

  Future<String?> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText =
          await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      print('OCR error: $e');
      return null;
    }
  }

  // ============ LANGUAGE DETECTION ============

  Future<String?> detectLanguage(String text) async {
    try {
      return await _languageIdentifier.identifyLanguage(text);
    } catch (e) {
      print('Language error: $e');
      return null;
    }
  }

  // ============ IMAGE LABELING ============

  Future<List<ImageLabel>> labelImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      return await _imageLabeler.processImage(inputImage);
    } catch (e) {
      print('Label error: $e');
      return [];
    }
  }

  // ============ TRANSLATION ============

  Future<String?> translateText(
      String text, String fromLang, String toLang) async {
    try {
      OnDeviceTranslator? translator;

      if (fromLang == 'fr' && toLang == 'en') {
        translator = _translatorFrEn;
      } else if (fromLang == 'fr' && toLang == 'ar') {
        translator = _translatorFrAr;
      } else if (fromLang == 'en' && toLang == 'fr') {
        translator = _translatorEnFr;
      } else if (fromLang == 'ar' && toLang == 'fr') {
        translator = _translatorArFr;
      }

      return await translator?.translateText(text);
    } catch (e) {
      print('Translation error: $e');
      return null;
    }
  }

  Future<Map<String, String>> translateFull(
      String text, String sourceLang) async {
    Map<String, String> result = {};

    if (sourceLang == 'fr') {
      result['en'] =
          await translateText(text, 'fr', 'en') ?? '';
      result['ar'] =
          await translateText(text, 'fr', 'ar') ?? '';
      result['fr'] = text;
    } else if (sourceLang == 'en') {
      result['fr'] =
          await translateText(text, 'en', 'fr') ?? '';
      result['ar'] =
          await translateText(text, 'en', 'ar') ?? '';
      result['en'] = text;
    } else {
      result['fr'] =
          await translateText(text, 'ar', 'fr') ?? '';
      result['en'] =
          await translateText(text, 'ar', 'en') ?? '';
      result['ar'] = text;
    }

    return result;
  }

  // ============ SIMULATION SMART REPLY (FIX IMPORTANT) ============

  /// ❗ Smart Reply ML Kit n'est plus stable dans Flutter
  /// 👉 On remplace par logique IA simple (FIABLE)

  Future<List<String>> suggestReplies(String object) async {
    List<String> suggestions = [];

    if (object.toLowerCase().contains('pomme')) {
      suggestions = ['C’est une pomme', 'Je ne sais pas', 'Encore'];
    } else if (object.toLowerCase().contains('chat')) {
      suggestions = ['C’est un chat', 'C’est un chien', 'Je ne sais pas'];
    } else {
      suggestions = [
        'Je ne sais pas',
        'C’est un objet',
        'Aide-moi',
        'Réessayer'
      ];
    }

    return suggestions;
  }

  // ============ PROCESS OBJECT ============

  Future<Map<String, dynamic>> processObjectPhoto(File imageFile) async {
    try {
      final labels = await labelImage(imageFile);

      if (labels.isEmpty) {
        return {'success': false, 'error': 'Aucun objet détecté'};
      }

      final best = labels.first;

      return {
        'success': true,
        'objectName': best.label,
        'confidence': best.confidence,
        'question': 'Quel est cet objet ?',
        'suggestions': await suggestReplies(best.label),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ PROCESS WORD ============

  Future<Map<String, dynamic>> processWordScan(File imageFile) async {
    try {
      final text = await extractTextFromImage(imageFile);

      if (text == null || text.isEmpty) {
        return {'success': false, 'error': 'Aucun texte'};
      }

      final lang = await detectLanguage(text) ?? 'fr';
      final translations = await translateFull(text, lang);

      return {
        'success': true,
        'word': text,
        'language': lang,
        'translations': translations,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _languageIdentifier.close();

    _translatorFrEn?.close();
    _translatorFrAr?.close();
    _translatorEnFr?.close();
    _translatorArFr?.close();
  }
}