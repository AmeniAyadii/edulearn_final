import 'package:flutter/material.dart';

class ColorTranslation {
  final String name;
  final String audioUrl;
  bool isLearned;

  ColorTranslation({
    required this.name,
    this.audioUrl = '',
    this.isLearned = false,
  });

  factory ColorTranslation.fromMap(Map<String, dynamic> map) {
    return ColorTranslation(
      name: map['name'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      isLearned: map['isLearned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'audioUrl': audioUrl,
      'isLearned': isLearned,
    };
  }
}

class ColorItem {
  final String id;
  final Color colorValue;
  final String imageUrl;
  final String emoji;
  final String funFactFr;
  final String funFactEn;
  final String psychologyFr;
  final String psychologyEn;
  final int difficulty;
  final int basePoints;
  final Map<String, ColorTranslation> translations;
  DateTime? discoveredAt;
  int timesLearned;

  ColorItem({
    required this.id,
    required this.colorValue,
    required this.imageUrl,
    required this.emoji,
    required this.funFactFr,
    required this.funFactEn,
    required this.psychologyFr,
    required this.psychologyEn,
    this.difficulty = 1,
    this.basePoints = 15,
    required this.translations,
    this.discoveredAt,
    this.timesLearned = 0,
  });

  String getNameInLanguage(String languageCode) {
    return translations[languageCode]?.name ?? 
           translations['fr']?.name ?? 
           id;
  }

  String getFunFact(String languageCode) {
    if (languageCode == 'fr') return funFactFr;
    return funFactEn;
  }

  String getPsychology(String languageCode) {
    if (languageCode == 'fr') return psychologyFr;
    return psychologyEn;
  }

  factory ColorItem.fromMap(String id, Map<String, dynamic> map) {
    final translationsMap = <String, ColorTranslation>{};
    if (map['translations'] != null) {
      (map['translations'] as Map<String, dynamic>).forEach((key, value) {
        translationsMap[key] = ColorTranslation.fromMap(value);
      });
    }

    return ColorItem(
      id: id,
      colorValue: Color(map['colorValue'] ?? 0xFF000000),
      imageUrl: map['imageUrl'] ?? '',
      emoji: map['emoji'] ?? '🎨',
      funFactFr: map['funFactFr'] ?? '',
      funFactEn: map['funFactEn'] ?? '',
      psychologyFr: map['psychologyFr'] ?? '',
      psychologyEn: map['psychologyEn'] ?? '',
      difficulty: map['difficulty'] ?? 1,
      basePoints: map['basePoints'] ?? 15,
      translations: translationsMap,
      discoveredAt: map['discoveredAt'] != null 
          ? DateTime.tryParse(map['discoveredAt']) 
          : null,
      timesLearned: map['timesLearned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'colorValue': colorValue.value,
      'imageUrl': imageUrl,
      'emoji': emoji,
      'funFactFr': funFactFr,
      'funFactEn': funFactEn,
      'psychologyFr': psychologyFr,
      'psychologyEn': psychologyEn,
      'difficulty': difficulty,
      'basePoints': basePoints,
      'translations': translations.map((key, value) => MapEntry(key, value.toMap())),
      'discoveredAt': discoveredAt?.toIso8601String(),
      'timesLearned': timesLearned,
    };
  }
}

// ✅ BASE DE DONNÉES DES COULEURS
class ColorDatabase {
  static final List<ColorItem> allColors = [
    ColorItem(
      id: 'rouge',
      colorValue: Colors.red,
      imageUrl: 'assets/images/colors/red.png',
      emoji: '🔴',
      funFactFr: 'Le rouge est la première couleur que les bébés voient ! 👶',
      funFactEn: 'Red is the first color babies see! 👶',
      psychologyFr: 'Évoque la passion, l\'énergie et l\'amour ❤️',
      psychologyEn: 'Evokes passion, energy and love ❤️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': ColorTranslation(name: 'rouge'),
        'en': ColorTranslation(name: 'red'),
        'es': ColorTranslation(name: 'rojo'),
        'de': ColorTranslation(name: 'rot'),
        'it': ColorTranslation(name: 'rosso'),
        'pt': ColorTranslation(name: 'vermelho'),
        'nl': ColorTranslation(name: 'rood'),
        'ru': ColorTranslation(name: 'красный'),
        'zh': ColorTranslation(name: '红色'),
        'ja': ColorTranslation(name: '赤'),
        'ar': ColorTranslation(name: 'أحمر'),
        'hi': ColorTranslation(name: 'लाल'),
      },
    ),
    ColorItem(
      id: 'bleu',
      colorValue: Colors.blue,
      imageUrl: 'assets/images/colors/blue.png',
      emoji: '🔵',
      funFactFr: 'Le bleu est la couleur préférée dans le monde ! 🌍',
      funFactEn: 'Blue is the world\'s favorite color! 🌍',
      psychologyFr: 'Évoque la confiance, la sérénité et la paix ☁️',
      psychologyEn: 'Evokes trust, serenity and peace ☁️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': ColorTranslation(name: 'bleu'),
        'en': ColorTranslation(name: 'blue'),
        'es': ColorTranslation(name: 'azul'),
        'de': ColorTranslation(name: 'blau'),
        'it': ColorTranslation(name: 'blu'),
        'pt': ColorTranslation(name: 'azul'),
        'nl': ColorTranslation(name: 'blauw'),
        'ru': ColorTranslation(name: 'синий'),
        'zh': ColorTranslation(name: '蓝色'),
        'ja': ColorTranslation(name: '青'),
        'ar': ColorTranslation(name: 'أزرق'),
        'hi': ColorTranslation(name: 'नीला'),
      },
    ),
    ColorItem(
      id: 'vert',
      colorValue: Colors.green,
      imageUrl: 'assets/images/colors/green.png',
      emoji: '🟢',
      funFactFr: 'Les yeux verts sont les plus rares au monde ! 👀',
      funFactEn: 'Green eyes are the rarest in the world! 👀',
      psychologyFr: 'Évoque la nature, l\'espoir et la santé 🌿',
      psychologyEn: 'Evokes nature, hope and health 🌿',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': ColorTranslation(name: 'vert'),
        'en': ColorTranslation(name: 'green'),
        'es': ColorTranslation(name: 'verde'),
        'de': ColorTranslation(name: 'grün'),
        'it': ColorTranslation(name: 'verde'),
        'pt': ColorTranslation(name: 'verde'),
        'nl': ColorTranslation(name: 'groen'),
        'ru': ColorTranslation(name: 'зеленый'),
        'zh': ColorTranslation(name: '绿色'),
        'ja': ColorTranslation(name: '緑'),
        'ar': ColorTranslation(name: 'أخضر'),
        'hi': ColorTranslation(name: 'हरा'),
      },
    ),
    ColorItem(
      id: 'jaune',
      colorValue: Colors.yellow,
      imageUrl: 'assets/images/colors/yellow.png',
      emoji: '🟡',
      funFactFr: 'Le jaune est la couleur la plus visible à l\'œil nu ! 👁️',
      funFactEn: 'Yellow is the most visible color to the naked eye! 👁️',
      psychologyFr: 'Évoque la joie, l\'optimisme et la chaleur ☀️',
      psychologyEn: 'Evokes joy, optimism and warmth ☀️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': ColorTranslation(name: 'jaune'),
        'en': ColorTranslation(name: 'yellow'),
        'es': ColorTranslation(name: 'amarillo'),
        'de': ColorTranslation(name: 'gelb'),
        'it': ColorTranslation(name: 'giallo'),
        'pt': ColorTranslation(name: 'amarelo'),
        'nl': ColorTranslation(name: 'geel'),
        'ru': ColorTranslation(name: 'желтый'),
        'zh': ColorTranslation(name: '黄色'),
        'ja': ColorTranslation(name: '黄'),
        'ar': ColorTranslation(name: 'أصفر'),
        'hi': ColorTranslation(name: 'पीला'),
      },
    ),
    ColorItem(
      id: 'orange',
      colorValue: Colors.orange,
      imageUrl: 'assets/images/colors/orange.png',
      emoji: '🟠',
      funFactFr: 'L\'orange était autrefois appelée "jaune-rouge" ! 🍊',
      funFactEn: 'Orange was once called "yellow-red"! 🍊',
      psychologyFr: 'Évoque la créativité, l\'enthousiasme et l\'énergie 🎨',
      psychologyEn: 'Evokes creativity, enthusiasm and energy 🎨',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'orange'),
        'en': ColorTranslation(name: 'orange'),
        'es': ColorTranslation(name: 'naranja'),
        'de': ColorTranslation(name: 'orange'),
        'it': ColorTranslation(name: 'arancione'),
        'pt': ColorTranslation(name: 'laranja'),
        'nl': ColorTranslation(name: 'oranje'),
        'ru': ColorTranslation(name: 'оранжевый'),
        'zh': ColorTranslation(name: '橙色'),
        'ja': ColorTranslation(name: 'オレンジ'),
        'ar': ColorTranslation(name: 'برتقالي'),
        'hi': ColorTranslation(name: 'नारंगी'),
      },
    ),
    ColorItem(
      id: 'violet',
      colorValue: Colors.purple,
      imageUrl: 'assets/images/colors/purple.png',
      emoji: '🟣',
      funFactFr: 'Le violet était la couleur des empereurs romains ! 👑',
      funFactEn: 'Purple was the color of Roman emperors! 👑',
      psychologyFr: 'Évoque la royauté, la spiritualité et la créativité ✨',
      psychologyEn: 'Evokes royalty, spirituality and creativity ✨',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'violet'),
        'en': ColorTranslation(name: 'purple'),
        'es': ColorTranslation(name: 'morado'),
        'de': ColorTranslation(name: 'lila'),
        'it': ColorTranslation(name: 'viola'),
        'pt': ColorTranslation(name: 'roxo'),
        'nl': ColorTranslation(name: 'paars'),
        'ru': ColorTranslation(name: 'фиолетовый'),
        'zh': ColorTranslation(name: '紫色'),
        'ja': ColorTranslation(name: '紫'),
        'ar': ColorTranslation(name: 'بنفسجي'),
        'hi': ColorTranslation(name: 'बैंगनी'),
      },
    ),
    ColorItem(
      id: 'rose',
      colorValue: Colors.pink,
      imageUrl: 'assets/images/colors/pink.png',
      emoji: '💗',
      funFactFr: 'Le rose n\'existait pas dans les langues anciennes ! 🌸',
      funFactEn: 'Pink didn\'t exist in ancient languages! 🌸',
      psychologyFr: 'Évoque la douceur, l\'amour et la tendresse 💕',
      psychologyEn: 'Evokes softness, love and tenderness 💕',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'rose'),
        'en': ColorTranslation(name: 'pink'),
        'es': ColorTranslation(name: 'rosa'),
        'de': ColorTranslation(name: 'rosa'),
        'it': ColorTranslation(name: 'rosa'),
        'pt': ColorTranslation(name: 'rosa'),
        'nl': ColorTranslation(name: 'roze'),
        'ru': ColorTranslation(name: 'розовый'),
        'zh': ColorTranslation(name: '粉色'),
        'ja': ColorTranslation(name: 'ピンク'),
        'ar': ColorTranslation(name: 'وردي'),
        'hi': ColorTranslation(name: 'गुलाबी'),
      },
    ),
    ColorItem(
      id: 'marron',
      colorValue: Colors.brown,
      imageUrl: 'assets/images/colors/brown.png',
      emoji: '🟤',
      funFactFr: 'Le marron est la couleur la plus courante dans la nature ! 🌳',
      funFactEn: 'Brown is the most common color in nature! 🌳',
      psychologyFr: 'Évoque la stabilité, la fiabilité et le confort 🏠',
      psychologyEn: 'Evokes stability, reliability and comfort 🏠',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'marron'),
        'en': ColorTranslation(name: 'brown'),
        'es': ColorTranslation(name: 'marrón'),
        'de': ColorTranslation(name: 'braun'),
        'it': ColorTranslation(name: 'marrone'),
        'pt': ColorTranslation(name: 'marrom'),
        'nl': ColorTranslation(name: 'bruin'),
        'ru': ColorTranslation(name: 'коричневый'),
        'zh': ColorTranslation(name: '棕色'),
        'ja': ColorTranslation(name: '茶色'),
        'ar': ColorTranslation(name: 'بني'),
        'hi': ColorTranslation(name: 'भूरा'),
      },
    ),
    ColorItem(
      id: 'noir',
      colorValue: Colors.black,
      imageUrl: 'assets/images/colors/black.png',
      emoji: '⚫',
      funFactFr: 'Le noir absorbe toute la lumière ! 🌑',
      funFactEn: 'Black absorbs all light! 🌑',
      psychologyFr: 'Évoque l\'élégance, la puissance et le mystère 🌙',
      psychologyEn: 'Evokes elegance, power and mystery 🌙',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'noir'),
        'en': ColorTranslation(name: 'black'),
        'es': ColorTranslation(name: 'negro'),
        'de': ColorTranslation(name: 'schwarz'),
        'it': ColorTranslation(name: 'nero'),
        'pt': ColorTranslation(name: 'preto'),
        'nl': ColorTranslation(name: 'zwart'),
        'ru': ColorTranslation(name: 'черный'),
        'zh': ColorTranslation(name: '黑色'),
        'ja': ColorTranslation(name: '黒'),
        'ar': ColorTranslation(name: 'أسود'),
        'hi': ColorTranslation(name: 'काला'),
      },
    ),
    ColorItem(
      id: 'blanc',
      colorValue: Colors.white,
      imageUrl: 'assets/images/colors/white.png',
      emoji: '⚪',
      funFactFr: 'Le blanc est la somme de toutes les couleurs ! 🌈',
      funFactEn: 'White is the sum of all colors! 🌈',
      psychologyFr: 'Évoque la pureté, la simplicité et la paix 🕊️',
      psychologyEn: 'Evokes purity, simplicity and peace 🕊️',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': ColorTranslation(name: 'blanc'),
        'en': ColorTranslation(name: 'white'),
        'es': ColorTranslation(name: 'blanco'),
        'de': ColorTranslation(name: 'weiß'),
        'it': ColorTranslation(name: 'bianco'),
        'pt': ColorTranslation(name: 'branco'),
        'nl': ColorTranslation(name: 'wit'),
        'ru': ColorTranslation(name: 'белый'),
        'zh': ColorTranslation(name: '白色'),
        'ja': ColorTranslation(name: '白'),
        'ar': ColorTranslation(name: 'أبيض'),
        'hi': ColorTranslation(name: 'सफेद'),
      },
    ),
  ];

  static List<ColorItem> get shuffledColors {
    final shuffled = List<ColorItem>.from(allColors);
    shuffled.shuffle();
    return shuffled;
  }
}