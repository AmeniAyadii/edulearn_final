import 'dart:io';
import 'package:flutter/services.dart';

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();
  
  String? _apiKey;
  
  /// Charger la clé API depuis le fichier .env
  Future<String?> loadApiKey() async {
    if (_apiKey != null) return _apiKey;
    
    try {
      // Option 1: Depuis un fichier .env (recommandé)
      final envFile = await rootBundle.loadString('assets/.env');
      final lines = envFile.split('\n');
      for (final line in lines) {
        if (line.startsWith('GEMINI_API_KEY=')) {
          _apiKey = line.substring('GEMINI_API_KEY='.length).trim();
          break;
        }
      }
      
      // Option 2: Valeur par défaut pour le développement
      if (_apiKey == null || _apiKey!.isEmpty) {
        // ⚠️ En production, utilisez Firebase Remote Config ou un serveur backend
        print('⚠️ Aucune clé API trouvée dans .env');
      }
      
      return _apiKey;
    } catch (e) {
      print('❌ Erreur chargement .env: $e');
      return null;
    }
  }
}