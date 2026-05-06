// lib/models/language_mystery.dart
import 'package:flutter/material.dart';

class MysteryLanguage {
  final String code;
  final String name;
  final String flag;
  final Color color;
  final int difficulty;
  final int points;

  MysteryLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.color,
    required this.difficulty,
    required this.points,
  });

  static List<MysteryLanguage> getLanguages() {
    return [
      // Niveau 1 - Langues européennes courantes
      MysteryLanguage(code: 'es', name: 'Espagnol', flag: '🇪🇸', color: Colors.red, difficulty: 1, points: 20),
      MysteryLanguage(code: 'fr', name: 'Français', flag: '🇫🇷', color: Colors.blue, difficulty: 1, points: 20),
      MysteryLanguage(code: 'de', name: 'Allemand', flag: '🇩🇪', color: Colors.orange, difficulty: 1, points: 20),
      MysteryLanguage(code: 'it', name: 'Italien', flag: '🇮🇹', color: Colors.green, difficulty: 1, points: 20),
      MysteryLanguage(code: 'pt', name: 'Portugais', flag: '🇵🇹', color: Colors.teal, difficulty: 1, points: 20),
      MysteryLanguage(code: 'nl', name: 'Néerlandais', flag: '🇳🇱', color: Colors.orange, difficulty: 1, points: 20),
      
      // Niveau 2 - Langues nordiques et slaves
      MysteryLanguage(code: 'sv', name: 'Suédois', flag: '🇸🇪', color: Colors.blue, difficulty: 2, points: 30),
      MysteryLanguage(code: 'da', name: 'Danois', flag: '🇩🇰', color: Colors.red, difficulty: 2, points: 30),
      MysteryLanguage(code: 'no', name: 'Norvégien', flag: '🇳🇴', color: Colors.blue, difficulty: 2, points: 30),
      MysteryLanguage(code: 'ru', name: 'Russe', flag: '🇷🇺', color: Colors.purple, difficulty: 2, points: 30),
      MysteryLanguage(code: 'pl', name: 'Polonais', flag: '🇵🇱', color: Colors.red, difficulty: 2, points: 30),
      MysteryLanguage(code: 'cs', name: 'Tchèque', flag: '🇨🇿', color: Colors.blue, difficulty: 2, points: 30),
      
      // Niveau 3 - Langues asiatiques
      MysteryLanguage(code: 'ja', name: 'Japonais', flag: '🇯🇵', color: Colors.pink, difficulty: 3, points: 40),
      MysteryLanguage(code: 'ko', name: 'Coréen', flag: '🇰🇷', color: Colors.cyan, difficulty: 3, points: 40),
      MysteryLanguage(code: 'zh', name: 'Chinois', flag: '🇨🇳', color: Colors.red, difficulty: 3, points: 40),
      MysteryLanguage(code: 'th', name: 'Thaïlandais', flag: '🇹🇭', color: Colors.pink, difficulty: 3, points: 40),
      MysteryLanguage(code: 'vi', name: 'Vietnamien', flag: '🇻🇳', color: Colors.red, difficulty: 3, points: 40),
      MysteryLanguage(code: 'ms', name: 'Malaisien', flag: '🇲🇾', color: Colors.blue, difficulty: 3, points: 40),
      
      // Niveau 4 - Langues du Moyen-Orient et Asie du Sud
      MysteryLanguage(code: 'ar', name: 'Arabe', flag: '🇸🇦', color: Colors.blue, difficulty: 4, points: 50),
      MysteryLanguage(code: 'he', name: 'Hébreu', flag: '🇮🇱', color: Colors.blue, difficulty: 4, points: 50),
      MysteryLanguage(code: 'hi', name: 'Hindi', flag: '🇮🇳', color: Colors.orange, difficulty: 4, points: 50),
      MysteryLanguage(code: 'ur', name: 'Ourdou', flag: '🇵🇰', color: Colors.green, difficulty: 4, points: 50),
      MysteryLanguage(code: 'fa', name: 'Persan', flag: '🇮🇷', color: Colors.teal, difficulty: 4, points: 50),
      MysteryLanguage(code: 'tr', name: 'Turc', flag: '🇹🇷', color: Colors.teal, difficulty: 4, points: 50),
      
      // Niveau 5 - Langues africaines
      MysteryLanguage(code: 'sw', name: 'Swahili', flag: '🇹🇿', color: Colors.green, difficulty: 5, points: 60),
      MysteryLanguage(code: 'ha', name: 'Haoussa', flag: '🇳🇬', color: Colors.green, difficulty: 5, points: 60),
      MysteryLanguage(code: 'yo', name: 'Yoruba', flag: '🇳🇬', color: Colors.orange, difficulty: 5, points: 60),
      MysteryLanguage(code: 'ig', name: 'Igbo', flag: '🇳🇬', color: Colors.blue, difficulty: 5, points: 60),
      MysteryLanguage(code: 'am', name: 'Amharique', flag: '🇪🇹', color: Colors.red, difficulty: 5, points: 60),
      MysteryLanguage(code: 'zu', name: 'Zoulou', flag: '🇿🇦', color: Colors.blue, difficulty: 5, points: 60),
      
      // Niveau 6 - Langues rares
      MysteryLanguage(code: 'el', name: 'Grec', flag: '🇬🇷', color: Colors.indigo, difficulty: 6, points: 70),
      MysteryLanguage(code: 'la', name: 'Latin', flag: '🏛️', color: Colors.brown, difficulty: 6, points: 70),
      MysteryLanguage(code: 'ga', name: 'Irlandais', flag: '🇮🇪', color: Colors.green, difficulty: 6, points: 70),
      MysteryLanguage(code: 'cy', name: 'Gallois', flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿', color: Colors.red, difficulty: 6, points: 70),
      MysteryLanguage(code: 'mt', name: 'Maltais', flag: '🇲🇹', color: Colors.white, difficulty: 6, points: 70),
      MysteryLanguage(code: 'sq', name: 'Albanais', flag: '🇦🇱', color: Colors.red, difficulty: 6, points: 70),
      
      // Niveau 7 - Langues complexes
      MysteryLanguage(code: 'hu', name: 'Hongrois', flag: '🇭🇺', color: Colors.red, difficulty: 7, points: 80),
      MysteryLanguage(code: 'fi', name: 'Finnois', flag: '🇫🇮', color: Colors.blue, difficulty: 7, points: 80),
      MysteryLanguage(code: 'et', name: 'Estonien', flag: '🇪🇪', color: Colors.blue, difficulty: 7, points: 80),
      MysteryLanguage(code: 'is', name: 'Islandais', flag: '🇮🇸', color: Colors.blue, difficulty: 7, points: 80),
      MysteryLanguage(code: 'ka', name: 'Géorgien', flag: '🇬🇪', color: Colors.red, difficulty: 7, points: 80),
      MysteryLanguage(code: 'hy', name: 'Arménien', flag: '🇦🇲', color: Colors.red, difficulty: 7, points: 80),
    ];
  }
}

class MysteryPhrase {
  final String id;
  final String text;
  final String translation;
  final String languageCode;
  final String languageName;
  final String flag;
  final String hint;
  final int points;
  final int difficulty;

  MysteryPhrase({
    required this.id,
    required this.text,
    required this.translation,
    required this.languageCode,
    required this.languageName,
    required this.flag,
    required this.hint,
    required this.points,
    required this.difficulty,
  });

  static List<MysteryPhrase> getAllPhrases() {
    return [
      // ==================== NIVEAU 1 ====================
      // Espagnol
      MysteryPhrase(id: 'es_1', text: 'Buenos días', translation: 'Bonjour', languageCode: 'es', languageName: 'Espagnol', flag: '🇪🇸', hint: 'Langue de la paella', points: 20, difficulty: 1),
      MysteryPhrase(id: 'es_2', text: 'Gracias', translation: 'Merci', languageCode: 'es', languageName: 'Espagnol', flag: '🇪🇸', hint: 'Politesse en Espagne', points: 20, difficulty: 1),
      MysteryPhrase(id: 'es_3', text: 'Por favor', translation: 'S\'il vous plaît', languageCode: 'es', languageName: 'Espagnol', flag: '🇪🇸', hint: 'Formule de politesse', points: 20, difficulty: 1),
      MysteryPhrase(id: 'es_4', text: 'Hola', translation: 'Bonjour', languageCode: 'es', languageName: 'Espagnol', flag: '🇪🇸', hint: 'Salutation simple', points: 20, difficulty: 1),
      
      // Français
      MysteryPhrase(id: 'fr_1', text: 'Bonjour', translation: 'Bonjour', languageCode: 'fr', languageName: 'Français', flag: '🇫🇷', hint: 'Langue de la baguette', points: 20, difficulty: 1),
      MysteryPhrase(id: 'fr_2', text: 'Merci', translation: 'Merci', languageCode: 'fr', languageName: 'Français', flag: '🇫🇷', hint: 'Remerciement', points: 20, difficulty: 1),
      MysteryPhrase(id: 'fr_3', text: 'Au revoir', translation: 'Au revoir', languageCode: 'fr', languageName: 'Français', flag: '🇫🇷', hint: 'Quand on part', points: 20, difficulty: 1),
      
      // Allemand
      MysteryPhrase(id: 'de_1', text: 'Guten Morgen', translation: 'Bonjour', languageCode: 'de', languageName: 'Allemand', flag: '🇩🇪', hint: 'Pays de la bière', points: 20, difficulty: 1),
      MysteryPhrase(id: 'de_2', text: 'Danke', translation: 'Merci', languageCode: 'de', languageName: 'Allemand', flag: '🇩🇪', hint: 'Langue des frères Grimm', points: 20, difficulty: 1),
      MysteryPhrase(id: 'de_3', text: 'Bitte', translation: 'S\'il vous plaît', languageCode: 'de', languageName: 'Allemand', flag: '🇩🇪', hint: 'Formule de politesse', points: 20, difficulty: 1),
      
      // Italien
      MysteryPhrase(id: 'it_1', text: 'Buongiorno', translation: 'Bonjour', languageCode: 'it', languageName: 'Italien', flag: '🇮🇹', hint: 'Pays de la pizza', points: 20, difficulty: 1),
      MysteryPhrase(id: 'it_2', text: 'Grazie', translation: 'Merci', languageCode: 'it', languageName: 'Italien', flag: '🇮🇹', hint: 'Langue de la musique', points: 20, difficulty: 1),
      MysteryPhrase(id: 'it_3', text: 'Prego', translation: 'De rien', languageCode: 'it', languageName: 'Italien', flag: '🇮🇹', hint: 'Réponse à merci', points: 20, difficulty: 1),
      
      // Portugais
      MysteryPhrase(id: 'pt_1', text: 'Bom dia', translation: 'Bonjour', languageCode: 'pt', languageName: 'Portugais', flag: '🇵🇹', hint: 'Pays de la morue', points: 20, difficulty: 1),
      MysteryPhrase(id: 'pt_2', text: 'Obrigado', translation: 'Merci', languageCode: 'pt', languageName: 'Portugais', flag: '🇵🇹', hint: 'Remerciement', points: 20, difficulty: 1),
      
      // Néerlandais
      MysteryPhrase(id: 'nl_1', text: 'Goedemorgen', translation: 'Bonjour', languageCode: 'nl', languageName: 'Néerlandais', flag: '🇳🇱', hint: 'Pays des tulipes', points: 20, difficulty: 1),
      MysteryPhrase(id: 'nl_2', text: 'Dank je wel', translation: 'Merci', languageCode: 'nl', languageName: 'Néerlandais', flag: '🇳🇱', hint: 'Langue des moulins', points: 20, difficulty: 1),
      
      // ==================== NIVEAU 2 ====================
      // Suédois
      MysteryPhrase(id: 'sv_1', text: 'God morgon', translation: 'Bonjour', languageCode: 'sv', languageName: 'Suédois', flag: '🇸🇪', hint: 'Pays des Vikings', points: 30, difficulty: 2),
      MysteryPhrase(id: 'sv_2', text: 'Tack', translation: 'Merci', languageCode: 'sv', languageName: 'Suédois', flag: '🇸🇪', hint: 'Langue scandinave', points: 30, difficulty: 2),
      
      // Russe
      MysteryPhrase(id: 'ru_1', text: 'Здравствуйте', translation: 'Bonjour', languageCode: 'ru', languageName: 'Russe', flag: '🇷🇺', hint: 'Alphabet cyrillique', points: 30, difficulty: 2),
      MysteryPhrase(id: 'ru_2', text: 'Спасибо', translation: 'Merci', languageCode: 'ru', languageName: 'Russe', flag: '🇷🇺', hint: 'Langue des tsars', points: 30, difficulty: 2),
      MysteryPhrase(id: 'ru_3', text: 'До свидания', translation: 'Au revoir', languageCode: 'ru', languageName: 'Russe', flag: '🇷🇺', hint: 'Pays des matriochkas', points: 30, difficulty: 2),
      
      // Polonais
      MysteryPhrase(id: 'pl_1', text: 'Dzień dobry', translation: 'Bonjour', languageCode: 'pl', languageName: 'Polonais', flag: '🇵🇱', hint: 'Pays de Chopin', points: 30, difficulty: 2),
      MysteryPhrase(id: 'pl_2', text: 'Dziękuję', translation: 'Merci', languageCode: 'pl', languageName: 'Polonais', flag: '🇵🇱', hint: 'Langue difficile', points: 30, difficulty: 2),
      
      // ==================== NIVEAU 3 ====================
      // Japonais
      MysteryPhrase(id: 'ja_1', text: 'こんにちは', translation: 'Bonjour', languageCode: 'ja', languageName: 'Japonais', flag: '🇯🇵', hint: 'Pays du soleil levant', points: 40, difficulty: 3),
      MysteryPhrase(id: 'ja_2', text: 'ありがとう', translation: 'Merci', languageCode: 'ja', languageName: 'Japonais', flag: '🇯🇵', hint: 'Langue des mangas', points: 40, difficulty: 3),
      MysteryPhrase(id: 'ja_3', text: 'さようなら', translation: 'Au revoir', languageCode: 'ja', languageName: 'Japonais', flag: '🇯🇵', hint: 'Pays des sushis', points: 40, difficulty: 3),
      
      // Coréen
      MysteryPhrase(id: 'ko_1', text: '안녕하세요', translation: 'Bonjour', languageCode: 'ko', languageName: 'Coréen', flag: '🇰🇷', hint: 'Pays du kimchi', points: 40, difficulty: 3),
      MysteryPhrase(id: 'ko_2', text: '감사합니다', translation: 'Merci', languageCode: 'ko', languageName: 'Coréen', flag: '🇰🇷', hint: 'Alphabet Hangul', points: 40, difficulty: 3),
      
      // Chinois
      MysteryPhrase(id: 'zh_1', text: '你好', translation: 'Bonjour', languageCode: 'zh', languageName: 'Chinois', flag: '🇨🇳', hint: 'Langue la plus parlée', points: 40, difficulty: 3),
      MysteryPhrase(id: 'zh_2', text: '谢谢', translation: 'Merci', languageCode: 'zh', languageName: 'Chinois', flag: '🇨🇳', hint: 'Caractères chinois', points: 40, difficulty: 3),
      MysteryPhrase(id: 'zh_3', text: '再见', translation: 'Au revoir', languageCode: 'zh', languageName: 'Chinois', flag: '🇨🇳', hint: 'Pays de la Grande Muraille', points: 40, difficulty: 3),
      
      // Thaïlandais
      MysteryPhrase(id: 'th_1', text: 'สวัสดี', translation: 'Bonjour', languageCode: 'th', languageName: 'Thaïlandais', flag: '🇹🇭', hint: 'Pays des temples', points: 40, difficulty: 3),
      MysteryPhrase(id: 'th_2', text: 'ขอบคุณ', translation: 'Merci', languageCode: 'th', languageName: 'Thaïlandais', flag: '🇹🇭', hint: 'Alphabet arrondi', points: 40, difficulty: 3),
      
      // ==================== NIVEAU 4 ====================
      // Arabe
      MysteryPhrase(id: 'ar_1', text: 'السلام عليكم', translation: 'Bonjour', languageCode: 'ar', languageName: 'Arabe', flag: '🇸🇦', hint: 'Écrit de droite à gauche', points: 50, difficulty: 4),
      MysteryPhrase(id: 'ar_2', text: 'شكرا', translation: 'Merci', languageCode: 'ar', languageName: 'Arabe', flag: '🇸🇦', hint: 'Langue du Coran', points: 50, difficulty: 4),
      MysteryPhrase(id: 'ar_3', text: 'مع السلامة', translation: 'Au revoir', languageCode: 'ar', languageName: 'Arabe', flag: '🇸🇦', hint: 'Pays du désert', points: 50, difficulty: 4),
      
      // Hébreu
      MysteryPhrase(id: 'he_1', text: 'שלום', translation: 'Bonjour', languageCode: 'he', languageName: 'Hébreu', flag: '🇮🇱', hint: 'Langue de la Bible', points: 50, difficulty: 4),
      MysteryPhrase(id: 'he_2', text: 'תודה', translation: 'Merci', languageCode: 'he', languageName: 'Hébreu', flag: '🇮🇱', hint: 'Écrit de droite à gauche', points: 50, difficulty: 4),
      
      // Hindi
      MysteryPhrase(id: 'hi_1', text: 'नमस्ते', translation: 'Bonjour', languageCode: 'hi', languageName: 'Hindi', flag: '🇮🇳', hint: 'Pays du Taj Mahal', points: 50, difficulty: 4),
      MysteryPhrase(id: 'hi_2', text: 'धन्यवाद', translation: 'Merci', languageCode: 'hi', languageName: 'Hindi', flag: '🇮🇳', hint: 'Langue de Bollywood', points: 50, difficulty: 4),
      
      // Turc
      MysteryPhrase(id: 'tr_1', text: 'Merhaba', translation: 'Bonjour', languageCode: 'tr', languageName: 'Turc', flag: '🇹🇷', hint: 'Pont entre l\'Europe et l\'Asie', points: 50, difficulty: 4),
      MysteryPhrase(id: 'tr_2', text: 'Teşekkür ederim', translation: 'Merci', languageCode: 'tr', languageName: 'Turc', flag: '🇹🇷', hint: 'Langue des bazars', points: 50, difficulty: 4),
      
      // ==================== NIVEAU 5 ====================
      // Swahili
      MysteryPhrase(id: 'sw_1', text: 'Jambo', translation: 'Bonjour', languageCode: 'sw', languageName: 'Swahili', flag: '🇹🇿', hint: 'Langue d\'Afrique de l\'Est', points: 60, difficulty: 5),
      MysteryPhrase(id: 'sw_2', text: 'Asante', translation: 'Merci', languageCode: 'sw', languageName: 'Swahili', flag: '🇹🇿', hint: 'Pays des safaris', points: 60, difficulty: 5),
      
      // Grec
      MysteryPhrase(id: 'el_1', text: 'Γειά σου', translation: 'Bonjour', languageCode: 'el', languageName: 'Grec', flag: '🇬🇷', hint: 'Berceau de la démocratie', points: 60, difficulty: 5),
      MysteryPhrase(id: 'el_2', text: 'Ευχαριστώ', translation: 'Merci', languageCode: 'el', languageName: 'Grec', flag: '🇬🇷', hint: 'Alphabet mythologique', points: 60, difficulty: 5),
      MysteryPhrase(id: 'el_3', text: 'Γειά σας', translation: 'Au revoir', languageCode: 'el', languageName: 'Grec', flag: '🇬🇷', hint: 'Pays des olives', points: 60, difficulty: 5),
      
      // ==================== NIVEAU 6 ====================
      // Latin
      MysteryPhrase(id: 'la_1', text: 'Salve', translation: 'Bonjour', languageCode: 'la', languageName: 'Latin', flag: '🏛️', hint: 'Langue des Romains', points: 70, difficulty: 6),
      MysteryPhrase(id: 'la_2', text: 'Gratias tibi', translation: 'Merci', languageCode: 'la', languageName: 'Latin', flag: '🏛️', hint: 'Langue morte', points: 70, difficulty: 6),
      MysteryPhrase(id: 'la_3', text: 'Vale', translation: 'Au revoir', languageCode: 'la', languageName: 'Latin', flag: '🏛️', hint: 'Langue de l\'Empire', points: 70, difficulty: 6),
      
      // Irlandais
      MysteryPhrase(id: 'ga_1', text: 'Dia dhuit', translation: 'Bonjour', languageCode: 'ga', languageName: 'Irlandais', flag: '🇮🇪', hint: 'Langue celtique', points: 70, difficulty: 6),
      MysteryPhrase(id: 'ga_2', text: 'Go raibh maith agat', translation: 'Merci', languageCode: 'ga', languageName: 'Irlandais', flag: '🇮🇪', hint: 'Pays des leprechauns', points: 70, difficulty: 6),
      
      // Hongrois
      MysteryPhrase(id: 'hu_1', text: 'Jó reggelt', translation: 'Bonjour', languageCode: 'hu', languageName: 'Hongrois', flag: '🇭🇺', hint: 'Langue très difficile', points: 80, difficulty: 7),
      MysteryPhrase(id: 'hu_2', text: 'Köszönöm', translation: 'Merci', languageCode: 'hu', languageName: 'Hongrois', flag: '🇭🇺', hint: 'Pays du Danube', points: 80, difficulty: 7),
      MysteryPhrase(id: 'hu_3', text: 'Viszontlátásra', translation: 'Au revoir', languageCode: 'hu', languageName: 'Hongrois', flag: '🇭🇺', hint: 'Langue unique en Europe', points: 80, difficulty: 7),
    ];
  }

  static List<MysteryPhrase> getPhrasesByDifficulty(int difficulty) {
    return getAllPhrases().where((p) => p.difficulty == difficulty).toList();
  }
  
  static int getMaxDifficulty() {
    return 7;
  }
}