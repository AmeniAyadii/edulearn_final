import 'package:flutter/foundation.dart';

class AnimalTranslation {
  final String name;
  final String audioUrl;
  final String? imageUrl;  // ⚠️ Optionnel
  bool isUnlocked;
  bool isListened;
  bool isScanned;
  bool isSpoken;
  bool isComplete;  // ✅ Ne pas mettre 'final' pour permettre la modification
  

  AnimalTranslation({
    required this.name,
    this.audioUrl = '',
    this.imageUrl,
    this.isUnlocked = false,
    this.isListened = false,
    this.isScanned = false,
    this.isSpoken = false,
    this.isComplete = false,
  });

  int get masteryLevel {
    int level = 0;
    if (isListened) level++;
    if (isScanned) level++;
    if (isSpoken) level++;
    return level;
  }

  //bool get isComplete => masteryLevel >= 3;
  

  factory AnimalTranslation.fromMap(Map<String, dynamic> map) {
    return AnimalTranslation(
      name: map['name'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
      isListened: map['isListened'] ?? false,
      isScanned: map['isScanned'] ?? false,
      isSpoken: map['isSpoken'] ?? false,
    );
  }

  

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'audioUrl': audioUrl,
      'isUnlocked': isUnlocked,
      'isListened': isListened,
      'isScanned': isScanned,
      'isSpoken': isSpoken,
    };
  }
}



class GameAnimal {
  final String id;
  final String scientificName;
  final String category;
  
  String? imageUrl;  // ⚠️ Rendre nullable ou optionnel
  final String emoji;
  final int difficulty;
  final int basePoints;
  final String funFactFr;
  final String funFactEn;
  final Map<String, AnimalTranslation> translations;
  DateTime? discoveredAt;
  String? photoUrl;

  GameAnimal({
    required this.id,
    required this.scientificName,
    required this.category,
    //required this.imageUrl,
    this.imageUrl,  // Optionnel
    required this.emoji,
    this.difficulty = 1,
    this.basePoints = 15,
    required this.funFactFr,
    required this.funFactEn,
    required this.translations,
    this.discoveredAt,
    this.photoUrl,
  });

  String getNameInLanguage(String languageCode) {
    return translations[languageCode]?.name ?? 
           translations['en']?.name ?? 
           id;
  }

  String getFunFact(String languageCode) {
    if (languageCode == 'fr') return funFactFr;
    return funFactEn;
  }

  int get totalMasteryPoints {
    return translations.values.fold(0, (sum, t) => sum + t.masteryLevel);
  }

  int get unlockedLanguagesCount {
    return translations.values.where((t) => t.isUnlocked).length;
  }

  factory GameAnimal.fromMap(String id, Map<String, dynamic> map) {
    final translationsMap = <String, AnimalTranslation>{};
    if (map['translations'] != null) {
      (map['translations'] as Map<String, dynamic>).forEach((key, value) {
        translationsMap[key] = AnimalTranslation.fromMap(value);
      });
    }

    return GameAnimal(
      id: id,
      scientificName: map['scientificName'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      emoji: map['emoji'] ?? '🐾',
      difficulty: map['difficulty'] ?? 1,
      basePoints: map['basePoints'] ?? 15,
      funFactFr: map['funFactFr'] ?? '',
      funFactEn: map['funFactEn'] ?? '',
      translations: translationsMap,
      discoveredAt: map['discoveredAt'] != null 
          ? DateTime.tryParse(map['discoveredAt']) 
          : null,
      photoUrl: map['photoUrl'],
    );
  }

  

  

  Map<String, dynamic> toMap() {
    return {
      'scientificName': scientificName,
      'category': category,
      'imageUrl': imageUrl,
      'emoji': emoji,
      'difficulty': difficulty,
      'basePoints': basePoints,
      'funFactFr': funFactFr,
      'funFactEn': funFactEn,
      'translations': translations.map((key, value) => MapEntry(key, value.toMap())),
      'discoveredAt': discoveredAt?.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }
}

// ✅ BASE DE DONNÉES UNIFIÉE - CLASSE UNIQUE
class GameAnimalsDatabase {
  static final List<GameAnimal> animals = [
    // ==================== A ====================
    GameAnimal(
      id: 'abeille',
      imageUrl: 'assets/images/animals/abeille.png',
      emoji: '🐝',
      scientificName: 'Apis mellifera',
      category: 'Insecte',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les abeilles produisent du miel et vivent en colonie ! 🍯',
      funFactEn: 'Bees produce honey and live in colonies! 🍯',
      translations: {
        'fr': AnimalTranslation(name: 'abeille'),
        'en': AnimalTranslation(name: 'bee'),
        'es': AnimalTranslation(name: 'abeja'),
        'de': AnimalTranslation(name: 'biene'),
        'it': AnimalTranslation(name: 'ape'),
        'pt': AnimalTranslation(name: 'abelha'),
        'nl': AnimalTranslation(name: 'bij'),
        'ru': AnimalTranslation(name: 'пчела'),
        'zh': AnimalTranslation(name: '蜜蜂'),
        'ja': AnimalTranslation(name: '蜂'),
        'ar': AnimalTranslation(name: 'نحلة'),
        'hi': AnimalTranslation(name: 'मधुमक्खी'),
      },
    ),
    GameAnimal(
      id: 'aigle',
      imageUrl: 'assets/images/animals/aigle.png',
      emoji: '🦅',
      scientificName: 'Aquila chrysaetos',
      category: 'Oiseau',
      difficulty: 2,
      basePoints: 20,
      funFactFr: "L'aigle a une vue exceptionnelle, 8 fois plus puissante que l'humain ! 👁️",
      funFactEn: "Eagles have exceptional vision, 8 times more powerful than humans! 👁️",
      translations: {
        'fr': AnimalTranslation(name: 'aigle'),
        'en': AnimalTranslation(name: 'eagle'),
        'es': AnimalTranslation(name: 'águila'),
        'de': AnimalTranslation(name: 'adler'),
        'it': AnimalTranslation(name: 'aquila'),
        'pt': AnimalTranslation(name: 'águia'),
        'nl': AnimalTranslation(name: 'arend'),
        'ru': AnimalTranslation(name: 'орёл'),
        'zh': AnimalTranslation(name: '鹰'),
        'ja': AnimalTranslation(name: '鷲'),
        'ar': AnimalTranslation(name: 'نسر'),
        'hi': AnimalTranslation(name: 'गरुड़'),
      },
    ),
    GameAnimal(
      id: 'ane',
      imageUrl: 'assets/images/animals/ane.png',
      emoji: '🫏',
      scientificName: 'Equus asinus',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: "L'âne peut entendre les sons jusqu'à 10 km ! 👂",
      funFactEn: "Donkeys can hear sounds up to 10 km away! 👂",
      translations: {
        'fr': AnimalTranslation(name: 'âne'),
        'en': AnimalTranslation(name: 'donkey'),
        'es': AnimalTranslation(name: 'burro'),
        'de': AnimalTranslation(name: 'esel'),
        'it': AnimalTranslation(name: 'asino'),
        'pt': AnimalTranslation(name: 'burro'),
        'nl': AnimalTranslation(name: 'ezel'),
        'ru': AnimalTranslation(name: 'осёл'),
        'zh': AnimalTranslation(name: '驴'),
        'ja': AnimalTranslation(name: 'ロバ'),
        'ar': AnimalTranslation(name: 'حمار'),
        'hi': AnimalTranslation(name: 'गधा'),
      },
    ),
    GameAnimal(
      id: 'antilope',
      imageUrl: 'assets/images/animals/antilope.png',
      emoji: '🦌',
      scientificName: 'Antilopinae',
      category: 'Mammifère',
      difficulty: 2,
      basePoints: 20,
      funFactFr: "L'antilope peut courir jusqu'à 80 km/h pour échapper aux prédateurs ! 💨",
      funFactEn: "Antelopes can run up to 80 km/h to escape predators! 💨",
      translations: {
        'fr': AnimalTranslation(name: 'antilope'),
        'en': AnimalTranslation(name: 'antelope'),
        'es': AnimalTranslation(name: 'antílope'),
        'de': AnimalTranslation(name: 'antilope'),
        'it': AnimalTranslation(name: 'antilope'),
        'pt': AnimalTranslation(name: 'antílope'),
        'nl': AnimalTranslation(name: 'antilope'),
        'ru': AnimalTranslation(name: 'антилопа'),
        'zh': AnimalTranslation(name: '羚羊'),
        'ja': AnimalTranslation(name: 'レイヨウ'),
        'ar': AnimalTranslation(name: 'ظبي'),
        'hi': AnimalTranslation(name: 'मृग'),
      },
    ),
    GameAnimal(
      id: 'araignee',
      imageUrl: 'assets/images/animals/araignee.png',
      emoji: '🕷️',
      scientificName: 'Araneae',
      category: 'Arachnide',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les araignées tissent des toiles plus résistantes que l\'acier ! 🕸️',
      funFactEn: 'Spiders weave webs stronger than steel! 🕸️',
      translations: {
        'fr': AnimalTranslation(name: 'araignée'),
        'en': AnimalTranslation(name: 'spider'),
        'es': AnimalTranslation(name: 'araña'),
        'de': AnimalTranslation(name: 'spinne'),
        'it': AnimalTranslation(name: 'ragno'),
        'pt': AnimalTranslation(name: 'aranha'),
        'nl': AnimalTranslation(name: 'spin'),
        'ru': AnimalTranslation(name: 'паук'),
        'zh': AnimalTranslation(name: '蜘蛛'),
        'ja': AnimalTranslation(name: 'クモ'),
        'ar': AnimalTranslation(name: 'عنكبوت'),
        'hi': AnimalTranslation(name: 'मकड़ी'),
      },
    ),

    // ==================== B ====================
    GameAnimal(
      id: 'baleine',
      imageUrl: 'assets/images/animals/baleine.png',
      emoji: '🐋',
      scientificName: 'Balaenoptera musculus',
      category: 'Mammifère marin',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'La baleine bleue est le plus grand animal du monde ! 🌊',
      funFactEn: 'The blue whale is the largest animal in the world! 🌊',
      translations: {
        'fr': AnimalTranslation(name: 'baleine'),
        'en': AnimalTranslation(name: 'whale'),
        'es': AnimalTranslation(name: 'ballena'),
        'de': AnimalTranslation(name: 'wal'),
        'it': AnimalTranslation(name: 'balena'),
        'pt': AnimalTranslation(name: 'baleia'),
        'nl': AnimalTranslation(name: 'walvis'),
        'ru': AnimalTranslation(name: 'кит'),
        'zh': AnimalTranslation(name: '鲸鱼'),
        'ja': AnimalTranslation(name: 'クジラ'),
        'ar': AnimalTranslation(name: 'حوت'),
        'hi': AnimalTranslation(name: 'व्हेल'),
      },
    ),
    GameAnimal(
      id: 'chat',
      imageUrl: 'assets/images/animals/chat.png',
      emoji: '🐱',
      scientificName: 'Felis catus',
      category: 'Animal domestique',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les chats dorment environ 16 heures par jour ! 😴',
      funFactEn: 'Cats sleep about 16 hours a day! 😴',
      translations: {
        'fr': AnimalTranslation(name: 'chat'),
        'en': AnimalTranslation(name: 'cat'),
        'es': AnimalTranslation(name: 'gato'),
        'de': AnimalTranslation(name: 'katze'),
        'it': AnimalTranslation(name: 'gatto'),
        'pt': AnimalTranslation(name: 'gato'),
        'nl': AnimalTranslation(name: 'kat'),
        'ru': AnimalTranslation(name: 'кот'),
        'zh': AnimalTranslation(name: '猫'),
        'ja': AnimalTranslation(name: '猫'),
        'ar': AnimalTranslation(name: 'قط'),
        'hi': AnimalTranslation(name: 'बिल्ली'),
      },
    ),
    GameAnimal(
      id: 'chien',
      imageUrl: 'assets/images/animals/chien.png',
      emoji: '🐕',
      scientificName: 'Canis familiaris',
      category: 'Animal domestique',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le chien est le meilleur ami de l\'homme depuis 15 000 ans ! 🐕',
      funFactEn: 'The dog has been man\'s best friend for 15,000 years! 🐕',
      translations: {
        'fr': AnimalTranslation(name: 'chien'),
        'en': AnimalTranslation(name: 'dog'),
        'es': AnimalTranslation(name: 'perro'),
        'de': AnimalTranslation(name: 'hund'),
        'it': AnimalTranslation(name: 'cane'),
        'pt': AnimalTranslation(name: 'cão'),
        'nl': AnimalTranslation(name: 'hond'),
        'ru': AnimalTranslation(name: 'собака'),
        'zh': AnimalTranslation(name: '狗'),
        'ja': AnimalTranslation(name: '犬'),
        'ar': AnimalTranslation(name: 'كلب'),
        'hi': AnimalTranslation(name: 'कुत्ता'),
      },
    ),
    GameAnimal(
      id: 'cheval',
      imageUrl: 'assets/images/animals/cheval.png',
      emoji: '🐴',
      scientificName: 'Equus ferus caballus',
      category: 'Animal domestique',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les chevaux peuvent dormir debout ! 🐴',
      funFactEn: 'Horses can sleep standing up! 🐴',
      translations: {
        'fr': AnimalTranslation(name: 'cheval'),
        'en': AnimalTranslation(name: 'horse'),
        'es': AnimalTranslation(name: 'caballo'),
        'de': AnimalTranslation(name: 'pferd'),
        'it': AnimalTranslation(name: 'cavallo'),
        'pt': AnimalTranslation(name: 'cavalo'),
        'nl': AnimalTranslation(name: 'paard'),
        'ru': AnimalTranslation(name: 'лошадь'),
        'zh': AnimalTranslation(name: '马'),
        'ja': AnimalTranslation(name: '馬'),
        'ar': AnimalTranslation(name: 'حصان'),
        'hi': AnimalTranslation(name: 'घोड़ा'),
      },
    ),

    // ==================== D ====================
    GameAnimal(
      id: 'dauphin',
      imageUrl: 'assets/images/animals/dauphin.png',
      emoji: '🐬',
      scientificName: 'Delphinus delphis',
      category: 'Mammifère marin',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Les dauphins sont très intelligents et communiquent avec des sifflements ! 🐬',
      funFactEn: 'Dolphins are very intelligent and communicate with whistles! 🐬',
      translations: {
        'fr': AnimalTranslation(name: 'dauphin'),
        'en': AnimalTranslation(name: 'dolphin'),
        'es': AnimalTranslation(name: 'delfín'),
        'de': AnimalTranslation(name: 'delfin'),
        'it': AnimalTranslation(name: 'delfino'),
        'pt': AnimalTranslation(name: 'golfinho'),
        'nl': AnimalTranslation(name: 'dolfijn'),
        'ru': AnimalTranslation(name: 'дельфин'),
        'zh': AnimalTranslation(name: '海豚'),
        'ja': AnimalTranslation(name: 'イルカ'),
        'ar': AnimalTranslation(name: 'دلفين'),
        'hi': AnimalTranslation(name: 'डॉल्फिन'),
      },
    ),
    GameAnimal(
      id: 'dinosaure',
      imageUrl: 'assets/images/animals/dinosaure.png',
      emoji: '🦕',
      scientificName: 'Dinosauria',
      category: 'Reptile préhistorique',
      difficulty: 3,
      basePoints: 30,
      funFactFr: 'Les dinosaures ont vécu sur Terre pendant 165 millions d\'années ! 🦖',
      funFactEn: 'Dinosaurs lived on Earth for 165 million years! 🦖',
      translations: {
        'fr': AnimalTranslation(name: 'dinosaure'),
        'en': AnimalTranslation(name: 'dinosaur'),
        'es': AnimalTranslation(name: 'dinosaurio'),
        'de': AnimalTranslation(name: 'dinosaurier'),
        'it': AnimalTranslation(name: 'dinosauro'),
        'pt': AnimalTranslation(name: 'dinossauro'),
        'nl': AnimalTranslation(name: 'dinosaurus'),
        'ru': AnimalTranslation(name: 'динозавр'),
        'zh': AnimalTranslation(name: '恐龙'),
        'ja': AnimalTranslation(name: '恐竜'),
        'ar': AnimalTranslation(name: 'ديناصور'),
        'hi': AnimalTranslation(name: 'डायनासोर'),
      },
    ),

    // ==================== E ====================
    GameAnimal(
      id: 'elephant',
      imageUrl: 'assets/images/animals/elephant.png',
      emoji: '🐘',
      scientificName: 'Loxodonta africana',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'L\'éléphant est le plus grand animal terrestre ! 🐘',
      funFactEn: 'The elephant is the largest land animal! 🐘',
      translations: {
        'fr': AnimalTranslation(name: 'éléphant'),
        'en': AnimalTranslation(name: 'elephant'),
        'es': AnimalTranslation(name: 'elefante'),
        'de': AnimalTranslation(name: 'elefant'),
        'it': AnimalTranslation(name: 'elefante'),
        'pt': AnimalTranslation(name: 'elefante'),
        'nl': AnimalTranslation(name: 'olifant'),
        'ru': AnimalTranslation(name: 'слон'),
        'zh': AnimalTranslation(name: '大象'),
        'ja': AnimalTranslation(name: 'ゾウ'),
        'ar': AnimalTranslation(name: 'فيل'),
        'hi': AnimalTranslation(name: 'हाथी'),
      },
    ),
    GameAnimal(
      id: 'escargot',
      imageUrl: 'assets/images/animals/escargot.png',
      emoji: '🐌',
      scientificName: 'Gastropoda',
      category: 'Mollusque',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'L\'escargot peut dormir pendant 3 ans ! 😴',
      funFactEn: 'Snails can sleep for 3 years! 😴',
      translations: {
        'fr': AnimalTranslation(name: 'escargot'),
        'en': AnimalTranslation(name: 'snail'),
        'es': AnimalTranslation(name: 'caracol'),
        'de': AnimalTranslation(name: 'schnecke'),
        'it': AnimalTranslation(name: 'lumaca'),
        'pt': AnimalTranslation(name: 'caracol'),
        'nl': AnimalTranslation(name: 'slak'),
        'ru': AnimalTranslation(name: 'улитка'),
        'zh': AnimalTranslation(name: '蜗牛'),
        'ja': AnimalTranslation(name: 'カタツムリ'),
        'ar': AnimalTranslation(name: 'حلزون'),
        'hi': AnimalTranslation(name: 'घोंघा'),
      },
    ),

    // ==================== G ====================
    GameAnimal(
      id: 'girafe',
      imageUrl: 'assets/images/animals/girafe.png',
      emoji: '🦒',
      scientificName: 'Giraffa camelopardalis',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'La girafe a un cou très long pour atteindre les feuilles ! 🦒',
      funFactEn: 'Giraffes have very long necks to reach leaves! 🦒',
      translations: {
        'fr': AnimalTranslation(name: 'girafe'),
        'en': AnimalTranslation(name: 'giraffe'),
        'es': AnimalTranslation(name: 'jirafa'),
        'de': AnimalTranslation(name: 'giraffe'),
        'it': AnimalTranslation(name: 'giraffa'),
        'pt': AnimalTranslation(name: 'girafa'),
        'nl': AnimalTranslation(name: 'giraf'),
        'ru': AnimalTranslation(name: 'жираф'),
        'zh': AnimalTranslation(name: '长颈鹿'),
        'ja': AnimalTranslation(name: 'キリン'),
        'ar': AnimalTranslation(name: 'زرافة'),
        'hi': AnimalTranslation(name: 'जिराफ'),
      },
    ),
    GameAnimal(
      id: 'gorille',
      imageUrl: 'assets/images/animals/gorille.png',
      emoji: '🦍',
      scientificName: 'Gorilla beringei',
      category: 'Primates',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Les gorilles sont nos plus proches cousins après les chimpanzés ! 🦍',
      funFactEn: 'Gorillas are our closest cousins after chimpanzees! 🦍',
      translations: {
        'fr': AnimalTranslation(name: 'gorille'),
        'en': AnimalTranslation(name: 'gorilla'),
        'es': AnimalTranslation(name: 'gorila'),
        'de': AnimalTranslation(name: 'gorilla'),
        'it': AnimalTranslation(name: 'gorilla'),
        'pt': AnimalTranslation(name: 'gorila'),
        'nl': AnimalTranslation(name: 'gorilla'),
        'ru': AnimalTranslation(name: 'горилла'),
        'zh': AnimalTranslation(name: '大猩猩'),
        'ja': AnimalTranslation(name: 'ゴリラ'),
        'ar': AnimalTranslation(name: 'غوريلا'),
        'hi': AnimalTranslation(name: 'गोरिल्ला'),
      },
    ),

    // ==================== K ====================
    GameAnimal(
      id: 'kangourou',
      imageUrl: 'assets/images/animals/kangourou.png',
      emoji: '🦘',
      scientificName: 'Macropus',
      category: 'Mammifère',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Le kangourou peut sauter jusqu\'à 9 mètres de long ! 🦘',
      funFactEn: 'Kangaroos can jump up to 9 meters long! 🦘',
      translations: {
        'fr': AnimalTranslation(name: 'kangourou'),
        'en': AnimalTranslation(name: 'kangaroo'),
        'es': AnimalTranslation(name: 'canguro'),
        'de': AnimalTranslation(name: 'känguru'),
        'it': AnimalTranslation(name: 'canguro'),
        'pt': AnimalTranslation(name: 'canguru'),
        'nl': AnimalTranslation(name: 'kangoeroe'),
        'ru': AnimalTranslation(name: 'кенгуру'),
        'zh': AnimalTranslation(name: '袋鼠'),
        'ja': AnimalTranslation(name: 'カンガルー'),
        'ar': AnimalTranslation(name: 'كنغر'),
        'hi': AnimalTranslation(name: 'कंगारू'),
      },
    ),
    GameAnimal(
      id: 'koala',
      imageUrl: 'assets/images/animals/koala.png',
      emoji: '🐨',
      scientificName: 'Phascolarctos cinereus',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le koala dort jusqu\'à 20 heures par jour ! 🐨',
      funFactEn: 'Koalas sleep up to 20 hours a day! 🐨',
      translations: {
        'fr': AnimalTranslation(name: 'koala'),
        'en': AnimalTranslation(name: 'koala'),
        'es': AnimalTranslation(name: 'koala'),
        'de': AnimalTranslation(name: 'koala'),
        'it': AnimalTranslation(name: 'koala'),
        'pt': AnimalTranslation(name: 'coala'),
        'nl': AnimalTranslation(name: 'koala'),
        'ru': AnimalTranslation(name: 'коала'),
        'zh': AnimalTranslation(name: '考拉'),
        'ja': AnimalTranslation(name: 'コアラ'),
        'ar': AnimalTranslation(name: 'كوالا'),
        'hi': AnimalTranslation(name: 'कोआला'),
      },
    ),

    // ==================== L ====================
    GameAnimal(
      id: 'lion',
      imageUrl: 'assets/images/animals/lion.png',
      emoji: '🦁',
      scientificName: 'Panthera leo',
      category: 'Félin',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le lion dort jusqu\'à 20 heures par jour ! 🦁',
      funFactEn: 'Lions sleep up to 20 hours a day! 🦁',
      translations: {
        'fr': AnimalTranslation(name: 'lion'),
        'en': AnimalTranslation(name: 'lion'),
        'es': AnimalTranslation(name: 'león'),
        'de': AnimalTranslation(name: 'löwe'),
        'it': AnimalTranslation(name: 'leone'),
        'pt': AnimalTranslation(name: 'leão'),
        'nl': AnimalTranslation(name: 'leeuw'),
        'ru': AnimalTranslation(name: 'лев'),
        'zh': AnimalTranslation(name: '狮子'),
        'ja': AnimalTranslation(name: 'ライオン'),
        'ar': AnimalTranslation(name: 'أسد'),
        'hi': AnimalTranslation(name: 'शेर'),
      },
    ),
    GameAnimal(
      id: 'lapin',
      imageUrl: 'assets/images/animals/lapin.png',
      emoji: '🐰',
      scientificName: 'Oryctolagus cuniculus',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les lapins ont 28 dents qui poussent toute leur vie ! 🦷',
      funFactEn: 'Rabbits have 28 teeth that grow all their lives! 🦷',
      translations: {
        'fr': AnimalTranslation(name: 'lapin'),
        'en': AnimalTranslation(name: 'rabbit'),
        'es': AnimalTranslation(name: 'conejo'),
        'de': AnimalTranslation(name: 'kaninchen'),
        'it': AnimalTranslation(name: 'coniglio'),
        'pt': AnimalTranslation(name: 'coelho'),
        'nl': AnimalTranslation(name: 'konijn'),
        'ru': AnimalTranslation(name: 'кролик'),
        'zh': AnimalTranslation(name: '兔子'),
        'ja': AnimalTranslation(name: 'ウサギ'),
        'ar': AnimalTranslation(name: 'أرنب'),
        'hi': AnimalTranslation(name: 'खरगोश'),
      },
    ),
    GameAnimal(
      id: 'loup',
      imageUrl: 'assets/images/animals/loup.png',
      emoji: '🐺',
      scientificName: 'Canis lupus',
      category: 'Mammifère',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Les loups vivent en meute et hurlent pour communiquer ! 🐺',
      funFactEn: 'Wolves live in packs and howl to communicate! 🐺',
      translations: {
        'fr': AnimalTranslation(name: 'loup'),
        'en': AnimalTranslation(name: 'wolf'),
        'es': AnimalTranslation(name: 'lobo'),
        'de': AnimalTranslation(name: 'wolf'),
        'it': AnimalTranslation(name: 'lupo'),
        'pt': AnimalTranslation(name: 'lobo'),
        'nl': AnimalTranslation(name: 'wolf'),
        'ru': AnimalTranslation(name: 'волк'),
        'zh': AnimalTranslation(name: '狼'),
        'ja': AnimalTranslation(name: 'オオカミ'),
        'ar': AnimalTranslation(name: 'ذئب'),
        'hi': AnimalTranslation(name: 'भेड़िया'),
      },
    ),

    // ==================== M ====================
    GameAnimal(
      id: 'manchot',
      imageUrl: 'assets/images/animals/manchot.png',
      emoji: '🐧',
      scientificName: 'Spheniscidae',
      category: 'Oiseau',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les manchots ne peuvent pas voler mais sont d\'excellents nageurs ! 🐧',
      funFactEn: 'Penguins cannot fly but are excellent swimmers! 🐧',
      translations: {
        'fr': AnimalTranslation(name: 'manchot'),
        'en': AnimalTranslation(name: 'penguin'),
        'es': AnimalTranslation(name: 'pingüino'),
        'de': AnimalTranslation(name: 'pinguin'),
        'it': AnimalTranslation(name: 'pinguino'),
        'pt': AnimalTranslation(name: 'pinguim'),
        'nl': AnimalTranslation(name: 'pinguïn'),
        'ru': AnimalTranslation(name: 'пингвин'),
        'zh': AnimalTranslation(name: '企鹅'),
        'ja': AnimalTranslation(name: 'ペンギン'),
        'ar': AnimalTranslation(name: 'بطريق'),
        'hi': AnimalTranslation(name: 'पेंगुइन'),
      },
    ),
    GameAnimal(
      id: 'mouton',
      imageUrl: 'assets/images/animals/mouton.png',
      emoji: '🐑',
      scientificName: 'Ovis aries',
      category: 'Animal domestique',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les moutons ont une excellente mémoire ! 🐑',
      funFactEn: 'Sheep have excellent memory! 🐑',
      translations: {
        'fr': AnimalTranslation(name: 'mouton'),
        'en': AnimalTranslation(name: 'sheep'),
        'es': AnimalTranslation(name: 'oveja'),
        'de': AnimalTranslation(name: 'schaf'),
        'it': AnimalTranslation(name: 'pecora'),
        'pt': AnimalTranslation(name: 'ovelha'),
        'nl': AnimalTranslation(name: 'schaap'),
        'ru': AnimalTranslation(name: 'овца'),
        'zh': AnimalTranslation(name: '绵羊'),
        'ja': AnimalTranslation(name: '羊'),
        'ar': AnimalTranslation(name: 'خروف'),
        'hi': AnimalTranslation(name: 'भेड़'),
      },
    ),

    // ==================== O ====================
    GameAnimal(
      id: 'ours',
      imageUrl: 'assets/images/animals/ours.png',
      emoji: '🐻',
      scientificName: 'Ursidae',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les ours peuvent courir jusqu\'à 55 km/h ! 🐻',
      funFactEn: 'Bears can run up to 55 km/h! 🐻',
      translations: {
        'fr': AnimalTranslation(name: 'ours'),
        'en': AnimalTranslation(name: 'bear'),
        'es': AnimalTranslation(name: 'oso'),
        'de': AnimalTranslation(name: 'bär'),
        'it': AnimalTranslation(name: 'orso'),
        'pt': AnimalTranslation(name: 'urso'),
        'nl': AnimalTranslation(name: 'beer'),
        'ru': AnimalTranslation(name: 'медведь'),
        'zh': AnimalTranslation(name: '熊'),
        'ja': AnimalTranslation(name: 'クマ'),
        'ar': AnimalTranslation(name: 'دب'),
        'hi': AnimalTranslation(name: 'भालू'),
      },
    ),
    GameAnimal(
      id: 'ornithorynque',
      imageUrl: 'assets/images/animals/ornithorynque.png',
      emoji: '🦫',
      scientificName: 'Ornithorhynchus anatinus',
      category: 'Mammifère',
      difficulty: 3,
      basePoints: 30,
      funFactFr: "L'ornithorynque est un mammifère qui pond des œufs ! 🥚",
      funFactEn: 'The platypus is a mammal that lays eggs! 🥚',
      translations: {
        'fr': AnimalTranslation(name: 'ornithorynque'),
        'en': AnimalTranslation(name: 'platypus'),
        'es': AnimalTranslation(name: 'ornitorrinco'),
        'de': AnimalTranslation(name: 'schnabeltier'),
        'it': AnimalTranslation(name: 'ornitorinco'),
        'pt': AnimalTranslation(name: 'ornitorrinco'),
        'nl': AnimalTranslation(name: 'vogelbekdier'),
        'ru': AnimalTranslation(name: 'утконос'),
        'zh': AnimalTranslation(name: '鸭嘴兽'),
        'ja': AnimalTranslation(name: 'カモノハシ'),
        'ar': AnimalTranslation(name: 'خلد الماء'),
        'hi': AnimalTranslation(name: 'प्लैटिपस'),
      },
    ),

    // ==================== P ====================
    GameAnimal(
      id: 'panda',
      imageUrl: 'assets/images/animals/panda.png',
      emoji: '🐼',
      scientificName: 'Ailuropoda melanoleuca',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le panda mange du bambou pendant 14 heures par jour ! 🎋',
      funFactEn: 'Pandas eat bamboo for 14 hours a day! 🎋',
      translations: {
        'fr': AnimalTranslation(name: 'panda'),
        'en': AnimalTranslation(name: 'panda'),
        'es': AnimalTranslation(name: 'panda'),
        'de': AnimalTranslation(name: 'panda'),
        'it': AnimalTranslation(name: 'panda'),
        'pt': AnimalTranslation(name: 'panda'),
        'nl': AnimalTranslation(name: 'panda'),
        'ru': AnimalTranslation(name: 'панда'),
        'zh': AnimalTranslation(name: '熊猫'),
        'ja': AnimalTranslation(name: 'パンダ'),
        'ar': AnimalTranslation(name: 'باندا'),
        'hi': AnimalTranslation(name: 'पांडा'),
      },
    ),
    GameAnimal(
      id: 'papillon',
      imageUrl: 'assets/images/animals/papillon.png',
      emoji: '🦋',
      scientificName: 'Lepidoptera',
      category: 'Insecte',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les papillons goûtent avec leurs pattes ! 🦋',
      funFactEn: 'Butterflies taste with their feet! 🦋',
      translations: {
        'fr': AnimalTranslation(name: 'papillon'),
        'en': AnimalTranslation(name: 'butterfly'),
        'es': AnimalTranslation(name: 'mariposa'),
        'de': AnimalTranslation(name: 'schmetterling'),
        'it': AnimalTranslation(name: 'farfalla'),
        'pt': AnimalTranslation(name: 'borboleta'),
        'nl': AnimalTranslation(name: 'vlinder'),
        'ru': AnimalTranslation(name: 'бабочка'),
        'zh': AnimalTranslation(name: '蝴蝶'),
        'ja': AnimalTranslation(name: '蝶'),
        'ar': AnimalTranslation(name: 'فراشة'),
        'hi': AnimalTranslation(name: 'तितली'),
      },
    ),
    GameAnimal(
      id: 'perroquet',
      imageUrl: 'assets/images/animals/perroquet.png',
      emoji: '🦜',
      scientificName: 'Psittaciformes',
      category: 'Oiseau',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les perroquets peuvent imiter la voix humaine ! 🗣️',
      funFactEn: 'Parrots can mimic human voice! 🗣️',
      translations: {
        'fr': AnimalTranslation(name: 'perroquet'),
        'en': AnimalTranslation(name: 'parrot'),
        'es': AnimalTranslation(name: 'loro'),
        'de': AnimalTranslation(name: 'papagei'),
        'it': AnimalTranslation(name: 'pappagallo'),
        'pt': AnimalTranslation(name: 'papagaio'),
        'nl': AnimalTranslation(name: 'papegaai'),
        'ru': AnimalTranslation(name: 'попугай'),
        'zh': AnimalTranslation(name: '鹦鹉'),
        'ja': AnimalTranslation(name: 'オウム'),
        'ar': AnimalTranslation(name: 'ببغاء'),
        'hi': AnimalTranslation(name: 'तोता'),
      },
    ),
    GameAnimal(
      id: 'pingouin',
      imageUrl: 'assets/images/animals/pingouin.png',
      emoji: '🐧',
      scientificName: 'Alcidae',
      category: 'Oiseau',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le pingouin vit dans l\'hémisphère nord, pas en Antarctique ! 🌍',
      funFactEn: 'Penguins live in the northern hemisphere, not Antarctica! 🌍',
      translations: {
        'fr': AnimalTranslation(name: 'pingouin'),
        'en': AnimalTranslation(name: 'auk'),
        'es': AnimalTranslation(name: 'pingüino'),
        'de': AnimalTranslation(name: 'alk'),
        'it': AnimalTranslation(name: 'alca'),
        'pt': AnimalTranslation(name: 'pinguim'),
        'nl': AnimalTranslation(name: 'alk'),
        'ru': AnimalTranslation(name: 'чистик'),
        'zh': AnimalTranslation(name: '海雀'),
        'ja': AnimalTranslation(name: 'ウミガラス'),
        'ar': AnimalTranslation(name: 'بطريق'),
        'hi': AnimalTranslation(name: 'पेंगुइन'),
      },
    ),

    // ==================== R ====================
    GameAnimal(
      id: 'renard',
      imageUrl: 'assets/images/animals/renard.png',
      emoji: '🦊',
      scientificName: 'Vulpes vulpes',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le renard est très malin et rusé ! 🦊',
      funFactEn: 'The fox is very clever and cunning! 🦊',
      translations: {
        'fr': AnimalTranslation(name: 'renard'),
        'en': AnimalTranslation(name: 'fox'),
        'es': AnimalTranslation(name: 'zorro'),
        'de': AnimalTranslation(name: 'fuchs'),
        'it': AnimalTranslation(name: 'volpe'),
        'pt': AnimalTranslation(name: 'raposa'),
        'nl': AnimalTranslation(name: 'vos'),
        'ru': AnimalTranslation(name: 'лиса'),
        'zh': AnimalTranslation(name: '狐狸'),
        'ja': AnimalTranslation(name: 'キツネ'),
        'ar': AnimalTranslation(name: 'ثعلب'),
        'hi': AnimalTranslation(name: 'लोमड़ी'),
      },
    ),
    GameAnimal(
      id: 'requin',
      imageUrl: 'assets/images/animals/requin.png',
      emoji: '🦈',
      scientificName: 'Selachimorpha',
      category: 'Poisson',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Les requins ont un odorat très développé ! 👃',
      funFactEn: 'Sharks have a highly developed sense of smell! 👃',
      translations: {
        'fr': AnimalTranslation(name: 'requin'),
        'en': AnimalTranslation(name: 'shark'),
        'es': AnimalTranslation(name: 'tiburón'),
        'de': AnimalTranslation(name: 'hai'),
        'it': AnimalTranslation(name: 'squalo'),
        'pt': AnimalTranslation(name: 'tubarão'),
        'nl': AnimalTranslation(name: 'haai'),
        'ru': AnimalTranslation(name: 'акула'),
        'zh': AnimalTranslation(name: '鲨鱼'),
        'ja': AnimalTranslation(name: 'サメ'),
        'ar': AnimalTranslation(name: 'قرش'),
        'hi': AnimalTranslation(name: 'शार्क'),
      },
    ),
    GameAnimal(
      id: 'rhinoceros',
      imageUrl: 'assets/images/animals/rhinoceros.png',
      emoji: '🦏',
      scientificName: 'Rhinocerotidae',
      category: 'Mammifère',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'La corne du rhinocéros est faite de kératine, comme nos ongles ! 🦏',
      funFactEn: 'The rhino\'s horn is made of keratin, like our nails! 🦏',
      translations: {
        'fr': AnimalTranslation(name: 'rhinocéros'),
        'en': AnimalTranslation(name: 'rhinoceros'),
        'es': AnimalTranslation(name: 'rinoceronte'),
        'de': AnimalTranslation(name: 'nashorn'),
        'it': AnimalTranslation(name: 'rinoceronte'),
        'pt': AnimalTranslation(name: 'rinoceronte'),
        'nl': AnimalTranslation(name: 'neushoorn'),
        'ru': AnimalTranslation(name: 'носорог'),
        'zh': AnimalTranslation(name: '犀牛'),
        'ja': AnimalTranslation(name: 'サイ'),
        'ar': AnimalTranslation(name: 'وحيد القرن'),
        'hi': AnimalTranslation(name: 'गैंडा'),
      },
    ),

    // ==================== S ====================
    GameAnimal(
      id: 'serpent',
      imageUrl: 'assets/images/animals/serpent.png',
      emoji: '🐍',
      scientificName: 'Serpentes',
      category: 'Reptile',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Les serpents n\'ont pas de paupières ! 👀',
      funFactEn: 'Snakes do not have eyelids! 👀',
      translations: {
        'fr': AnimalTranslation(name: 'serpent'),
        'en': AnimalTranslation(name: 'snake'),
        'es': AnimalTranslation(name: 'serpiente'),
        'de': AnimalTranslation(name: 'schlange'),
        'it': AnimalTranslation(name: 'serpente'),
        'pt': AnimalTranslation(name: 'serpente'),
        'nl': AnimalTranslation(name: 'slang'),
        'ru': AnimalTranslation(name: 'змея'),
        'zh': AnimalTranslation(name: '蛇'),
        'ja': AnimalTranslation(name: 'ヘビ'),
        'ar': AnimalTranslation(name: 'ثعبان'),
        'hi': AnimalTranslation(name: 'साँप'),
      },
    ),
    GameAnimal(
      id: 'souris',
      imageUrl: 'assets/images/animals/souris.png',
      emoji: '🐭',
      scientificName: 'Mus musculus',
      category: 'Rongeur',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les souris peuvent avoir jusqu\'à 15 bébés par portée ! 🐭',
      funFactEn: 'Mice can have up to 15 babies per litter! 🐭',
      translations: {
        'fr': AnimalTranslation(name: 'souris'),
        'en': AnimalTranslation(name: 'mouse'),
        'es': AnimalTranslation(name: 'ratón'),
        'de': AnimalTranslation(name: 'maus'),
        'it': AnimalTranslation(name: 'topo'),
        'pt': AnimalTranslation(name: 'rato'),
        'nl': AnimalTranslation(name: 'muis'),
        'ru': AnimalTranslation(name: 'мышь'),
        'zh': AnimalTranslation(name: '老鼠'),
        'ja': AnimalTranslation(name: 'マウス'),
        'ar': AnimalTranslation(name: 'فأر'),
        'hi': AnimalTranslation(name: 'चूहा'),
      },
    ),

    // ==================== T ====================
    GameAnimal(
      id: 'tigre',
      imageUrl: 'assets/images/animals/tigre.png',
      emoji: '🐯',
      scientificName: 'Panthera tigris',
      category: 'Félin',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Le tigre a des rayures uniques comme nos empreintes digitales ! 🐯',
      funFactEn: 'Tigers have unique stripes like our fingerprints! 🐯',
      translations: {
        'fr': AnimalTranslation(name: 'tigre'),
        'en': AnimalTranslation(name: 'tiger'),
        'es': AnimalTranslation(name: 'tigre'),
        'de': AnimalTranslation(name: 'tiger'),
        'it': AnimalTranslation(name: 'tigre'),
        'pt': AnimalTranslation(name: 'tigre'),
        'nl': AnimalTranslation(name: 'tijger'),
        'ru': AnimalTranslation(name: 'тигр'),
        'zh': AnimalTranslation(name: '老虎'),
        'ja': AnimalTranslation(name: 'トラ'),
        'ar': AnimalTranslation(name: 'نمر'),
        'hi': AnimalTranslation(name: 'बाघ'),
      },
    ),
    GameAnimal(
      id: 'tortue',
      imageUrl: 'assets/images/animals/tortue.png',
      emoji: '🐢',
      scientificName: 'Testudines',
      category: 'Reptile',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les tortues peuvent vivre plus de 100 ans ! 🐢',
      funFactEn: 'Turtles can live over 100 years! 🐢',
      translations: {
        'fr': AnimalTranslation(name: 'tortue'),
        'en': AnimalTranslation(name: 'turtle'),
        'es': AnimalTranslation(name: 'tortuga'),
        'de': AnimalTranslation(name: 'schildkröte'),
        'it': AnimalTranslation(name: 'tartaruga'),
        'pt': AnimalTranslation(name: 'tartaruga'),
        'nl': AnimalTranslation(name: 'schildpad'),
        'ru': AnimalTranslation(name: 'черепаха'),
        'zh': AnimalTranslation(name: '乌龟'),
        'ja': AnimalTranslation(name: 'カメ'),
        'ar': AnimalTranslation(name: 'سلحفاة'),
        'hi': AnimalTranslation(name: 'कछुआ'),
      },
    ),
    GameAnimal(
      id: 'toucan',
      imageUrl: 'assets/images/animals/toucan.png',
      emoji: '🦜',
      scientificName: 'Ramphastidae',
      category: 'Oiseau',
      difficulty: 2,
      basePoints: 20,
      funFactFr: 'Le bec du toucan peut être plus long que son corps ! 🦜',
      funFactEn: 'The toucan\'s beak can be longer than its body! 🦜',
      translations: {
        'fr': AnimalTranslation(name: 'toucan'),
        'en': AnimalTranslation(name: 'toucan'),
        'es': AnimalTranslation(name: 'tucán'),
        'de': AnimalTranslation(name: 'tukan'),
        'it': AnimalTranslation(name: 'tucano'),
        'pt': AnimalTranslation(name: 'tucano'),
        'nl': AnimalTranslation(name: 'toekan'),
        'ru': AnimalTranslation(name: 'тукан'),
        'zh': AnimalTranslation(name: '巨嘴鸟'),
        'ja': AnimalTranslation(name: 'オオハシ'),
        'ar': AnimalTranslation(name: 'طوقان'),
        'hi': AnimalTranslation(name: 'टूकैन'),
      },
    ),

    // ==================== V ====================
    GameAnimal(
      id: 'vache',
      imageUrl: 'assets/images/animals/vache.png',
      emoji: '🐮',
      scientificName: 'Bos taurus',
      category: 'Animal domestique',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Les vaches ont un meilleur ami et se sentent stressées sans lui ! 🐮',
      funFactEn: 'Cows have a best friend and feel stressed without them! 🐮',
      translations: {
        'fr': AnimalTranslation(name: 'vache'),
        'en': AnimalTranslation(name: 'cow'),
        'es': AnimalTranslation(name: 'vaca'),
        'de': AnimalTranslation(name: 'kuh'),
        'it': AnimalTranslation(name: 'mucca'),
        'pt': AnimalTranslation(name: 'vaca'),
        'nl': AnimalTranslation(name: 'koe'),
        'ru': AnimalTranslation(name: 'корова'),
        'zh': AnimalTranslation(name: '牛'),
        'ja': AnimalTranslation(name: '牛'),
        'ar': AnimalTranslation(name: 'بقرة'),
        'hi': AnimalTranslation(name: 'गाय'),
      },
    ),

    // ==================== Z ====================
    GameAnimal(
      id: 'zebre',
      imageUrl: 'assets/images/animals/zebre.png',
      emoji: '🦓',
      scientificName: 'Equus quagga',
      category: 'Mammifère',
      difficulty: 1,
      basePoints: 15,
      funFactFr: 'Chaque zèbre a des rayures uniques ! 🦓',
      funFactEn: 'Every zebra has unique stripes! 🦓',
      translations: {
        'fr': AnimalTranslation(name: 'zèbre'),
        'en': AnimalTranslation(name: 'zebra'),
        'es': AnimalTranslation(name: 'cebra'),
        'de': AnimalTranslation(name: 'zebra'),
        'it': AnimalTranslation(name: 'zebra'),
        'pt': AnimalTranslation(name: 'zebra'),
        'nl': AnimalTranslation(name: 'zebra'),
        'ru': AnimalTranslation(name: 'зебра'),
        'zh': AnimalTranslation(name: '斑马'),
        'ja': AnimalTranslation(name: 'シマウマ'),
        'ar': AnimalTranslation(name: 'حمار وحشي'),
        'hi': AnimalTranslation(name: 'ज़ेबरा'),
      },
    ),
  ];

  static List<GameAnimal> get shuffledAnimals {
    final shuffled = List<GameAnimal>.from(animals);
    shuffled.shuffle();
    return shuffled;
  }
  
  static List<GameAnimal> getAnimalsByCategory(String category) {
    return animals.where((animal) => animal.category == category).toList();
  }
  
  static List<String> getAllCategories() {
    return animals.map((e) => e.category).toSet().toList();
  }
  
  static GameAnimal? getAnimalById(String id) {
    try {
      return animals.firstWhere((animal) => animal.id == id);
    } catch (e) {
      return null;
    }
  }
}