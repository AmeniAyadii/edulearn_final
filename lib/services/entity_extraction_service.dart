import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:flutter/material.dart';

class EntityExtractionService {
  late final EntityExtractor _entityExtractor;
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  
  EntityExtractionService() {
    _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);
  }

  Future<String?> detectLanguage(String text) async {
    try {
      return await _languageIdentifier.identifyLanguage(text);
    } catch (e) {
      return null;
    }
  }

  Future<List<EntityAnnotation>> extractEntities(String text) async {
    try {
      return await _entityExtractor.annotateText(text);
    } catch (e) {
      return [];
    }
  }

  String getEntityTypeName(String type) {
    final types = {
      'address': '📍 Adresse',
      'date-time': '📅 Date/Heure',
      'email': '📧 Email',
      'phone-number': '📞 Téléphone',
      'url': '🔗 URL',
      'amount-of-money': '💰 Montant',
      'person': '👤 Personne',
      'location': '🌍 Lieu',
      'organization': '🏢 Organisation',
    };
    return types[type] ?? '❓ Inconnu';
  }

  IconData getEntityIcon(String type) {
    final icons = {
      'address': Icons.location_on,
      'date-time': Icons.calendar_today,
      'email': Icons.email,
      'phone-number': Icons.phone,
      'url': Icons.link,
      'amount-of-money': Icons.attach_money,
      'person': Icons.person,
      'location': Icons.place,
      'organization': Icons.business,
    };
    return icons[type] ?? Icons.help_outline;
  }

  Color getEntityColor(String type) {
    final colors = {
      'address': Colors.orange,
      'date-time': Colors.green,
      'email': Colors.blue,
      'phone-number': Colors.purple,
      'url': Colors.teal,
      'amount-of-money': Colors.amber,
      'person': Colors.red,
      'location': Colors.indigo,
      'organization': Colors.brown,
    };
    return colors[type] ?? Colors.grey;
  }

  String getLanguageName(String languageCode) {
    final names = {
      'fr': 'Français',
      'en': 'Anglais',
      'ar': 'Arabe',
      'es': 'Espagnol',
      'de': 'Allemand',
      'it': 'Italien',
      'pt': 'Portugais',
      'ru': 'Russe',
      'zh': 'Chinois',
      'ja': 'Japonais',
    };
    return names[languageCode] ?? languageCode.toUpperCase();
  }

  void dispose() {
    _entityExtractor.close();
    _languageIdentifier.close();
  }
}