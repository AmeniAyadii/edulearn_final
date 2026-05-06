import 'package:flutter/foundation.dart';

class FoodTranslation {
  final String name;
  final String audioUrl;
  bool isLearned;

  FoodTranslation({
    required this.name,
    this.audioUrl = '',
    this.isLearned = false,
  });

  factory FoodTranslation.fromMap(Map<String, dynamic> map) {
    return FoodTranslation(
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

class FoodItem {
  final String id;
  final String category; // 'fruit' ou 'vegetable'
  final String imageUrl;
  final String emoji;
  final String funFactFr;
  final String funFactEn;
  final String healthBenefitFr;
  final String healthBenefitEn;
  final int difficulty;
  final int basePoints;
  final Map<String, FoodTranslation> translations;
  DateTime? discoveredAt;
  int timesLearned;

  FoodItem({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.emoji,
    required this.funFactFr,
    required this.funFactEn,
    required this.healthBenefitFr,
    required this.healthBenefitEn,
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

  String getHealthBenefit(String languageCode) {
    if (languageCode == 'fr') return healthBenefitFr;
    return healthBenefitEn;
  }

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    final translationsMap = <String, FoodTranslation>{};
    if (map['translations'] != null) {
      (map['translations'] as Map<String, dynamic>).forEach((key, value) {
        translationsMap[key] = FoodTranslation.fromMap(value);
      });
    }

    return FoodItem(
      id: id,
      category: map['category'] ?? 'fruit',
      imageUrl: map['imageUrl'] ?? '',
      emoji: map['emoji'] ?? '🍎',
      funFactFr: map['funFactFr'] ?? '',
      funFactEn: map['funFactEn'] ?? '',
      healthBenefitFr: map['healthBenefitFr'] ?? '',
      healthBenefitEn: map['healthBenefitEn'] ?? '',
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
      'category': category,
      'imageUrl': imageUrl,
      'emoji': emoji,
      'funFactFr': funFactFr,
      'funFactEn': funFactEn,
      'healthBenefitFr': healthBenefitFr,
      'healthBenefitEn': healthBenefitEn,
      'difficulty': difficulty,
      'basePoints': basePoints,
      'translations': translations.map((key, value) => MapEntry(key, value.toMap())),
      'discoveredAt': discoveredAt?.toIso8601String(),
      'timesLearned': timesLearned,
    };
  }
}

// ✅ BASE DE DONNÉES DES FRUITS ET LÉGUMES
class FoodDatabase {
  static final List<FoodItem> allFoods = [
    // ==================== FRUITS ====================
    FoodItem(
      id: 'pomme',
      category: 'fruit',
      imageUrl: 'assets/images/foods/pomme.png',
      emoji: '🍎',
      funFactFr: 'Les pommes flottent dans l\'eau car 25% de leur volume est de l\'air ! 🍎',
      funFactEn: 'Apples float in water because 25% of their volume is air! 🍎',
      healthBenefitFr: 'Riche en fibres et vitamine C, bonne pour le cœur ❤️',
      healthBenefitEn: 'Rich in fiber and vitamin C, good for the heart ❤️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'pomme'),
        'en': FoodTranslation(name: 'apple'),
        'es': FoodTranslation(name: 'manzana'),
        'de': FoodTranslation(name: 'apfel'),
        'it': FoodTranslation(name: 'mela'),
        'pt': FoodTranslation(name: 'maçã'),
        'nl': FoodTranslation(name: 'appel'),
        'ru': FoodTranslation(name: 'яблоко'),
        'zh': FoodTranslation(name: '苹果'),
        'ja': FoodTranslation(name: 'リンゴ'),
        'ar': FoodTranslation(name: 'تفاح'),
        'hi': FoodTranslation(name: 'सेब'),
      },
    ),
    FoodItem(
      id: 'banane',
      category: 'fruit',
      imageUrl: 'assets/images/foods/banane.png',
      emoji: '🍌',
      funFactFr: 'La banane est techniquement une baie ! 🍌',
      funFactEn: 'Bananas are technically berries! 🍌',
      healthBenefitFr: 'Riche en potassium, bonne pour les muscles 💪',
      healthBenefitEn: 'Rich in potassium, good for muscles 💪',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'banane'),
        'en': FoodTranslation(name: 'banana'),
        'es': FoodTranslation(name: 'plátano'),
        'de': FoodTranslation(name: 'banane'),
        'it': FoodTranslation(name: 'banana'),
        'pt': FoodTranslation(name: 'banana'),
        'nl': FoodTranslation(name: 'banaan'),
        'ru': FoodTranslation(name: 'банан'),
        'zh': FoodTranslation(name: '香蕉'),
        'ja': FoodTranslation(name: 'バナナ'),
        'ar': FoodTranslation(name: 'موز'),
        'hi': FoodTranslation(name: 'केला'),
      },
    ),
    FoodItem(
      id: 'orange',
      category: 'fruit',
      imageUrl: 'assets/images/foods/orange.png',
      emoji: '🍊',
      funFactFr: 'L\'orange contient plus de 170 phytonutriments ! 🍊',
      funFactEn: 'Oranges contain over 170 phytonutrients! 🍊',
      healthBenefitFr: 'Riche en vitamine C, booste l\'immunité 🛡️',
      healthBenefitEn: 'Rich in vitamin C, boosts immunity 🛡️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'orange'),
        'en': FoodTranslation(name: 'orange'),
        'es': FoodTranslation(name: 'naranja'),
        'de': FoodTranslation(name: 'orange'),
        'it': FoodTranslation(name: 'arancia'),
        'pt': FoodTranslation(name: 'laranja'),
        'nl': FoodTranslation(name: 'sinaasappel'),
        'ru': FoodTranslation(name: 'апельсин'),
        'zh': FoodTranslation(name: '橙子'),
        'ja': FoodTranslation(name: 'オレンジ'),
        'ar': FoodTranslation(name: 'برتقال'),
        'hi': FoodTranslation(name: 'संतरा'),
      },
    ),
    FoodItem(
      id: 'fraise',
      category: 'fruit',
      imageUrl: 'assets/images/foods/fraise.png',
      emoji: '🍓',
      funFactFr: 'La fraise est le seul fruit avec ses graines à l\'extérieur ! 🍓',
      funFactEn: 'Strawberries are the only fruit with seeds on the outside! 🍓',
      healthBenefitFr: 'Riche en vitamine C et antioxydants 💖',
      healthBenefitEn: 'Rich in vitamin C and antioxidants 💖',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'fraise'),
        'en': FoodTranslation(name: 'strawberry'),
        'es': FoodTranslation(name: 'fresa'),
        'de': FoodTranslation(name: 'erdbeere'),
        'it': FoodTranslation(name: 'fragola'),
        'pt': FoodTranslation(name: 'morango'),
        'nl': FoodTranslation(name: 'aardbei'),
        'ru': FoodTranslation(name: 'клубника'),
        'zh': FoodTranslation(name: '草莓'),
        'ja': FoodTranslation(name: 'イチゴ'),
        'ar': FoodTranslation(name: 'فراولة'),
        'hi': FoodTranslation(name: 'स्ट्रॉबेरी'),
      },
    ),
    FoodItem(
      id: 'raisin',
      category: 'fruit',
      imageUrl: 'assets/images/foods/raisin.png',
      emoji: '🍇',
      funFactFr: 'Les raisins peuvent exploser au micro-ondes ! 🍇',
      funFactEn: 'Grapes can explode in the microwave! 🍇',
      healthBenefitFr: 'Riche en resvératrol, bon pour le cœur ❤️',
      healthBenefitEn: 'Rich in resveratrol, good for the heart ❤️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'raisin'),
        'en': FoodTranslation(name: 'grape'),
        'es': FoodTranslation(name: 'uva'),
        'de': FoodTranslation(name: 'traube'),
        'it': FoodTranslation(name: 'uva'),
        'pt': FoodTranslation(name: 'uva'),
        'nl': FoodTranslation(name: 'druif'),
        'ru': FoodTranslation(name: 'виноград'),
        'zh': FoodTranslation(name: '葡萄'),
        'ja': FoodTranslation(name: 'ブドウ'),
        'ar': FoodTranslation(name: 'عنب'),
        'hi': FoodTranslation(name: 'अंगूर'),
      },
    ),
    FoodItem(
      id: 'cerise',
      category: 'fruit',
      imageUrl: 'assets/images/foods/cerise.png',
      emoji: '🍒',
      funFactFr: 'Les cerises étaient appelées "baies de Drupes" dans l\'antiquité ! 🍒',
      funFactEn: 'Cherries were called "Drupe berries" in ancient times! 🍒',
      healthBenefitFr: 'Riche en mélatonine, aide à dormir 😴',
      healthBenefitEn: 'Rich in melatonin, helps sleep 😴',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'cerise'),
        'en': FoodTranslation(name: 'cherry'),
        'es': FoodTranslation(name: 'cereza'),
        'de': FoodTranslation(name: 'kirsche'),
        'it': FoodTranslation(name: 'ciliegia'),
        'pt': FoodTranslation(name: 'cereja'),
        'nl': FoodTranslation(name: 'kers'),
        'ru': FoodTranslation(name: 'вишня'),
        'zh': FoodTranslation(name: '樱桃'),
        'ja': FoodTranslation(name: 'チェリー'),
        'ar': FoodTranslation(name: 'كرز'),
        'hi': FoodTranslation(name: 'चेरी'),
      },
    ),
    FoodItem(
      id: 'poire',
      category: 'fruit',
      imageUrl: 'assets/images/foods/poire.png',
      emoji: '🍐',
      funFactFr: 'La poire mûrit de l\'intérieur vers l\'extérieur ! 🍐',
      funFactEn: 'Pears ripen from the inside out! 🍐',
      healthBenefitFr: 'Riche en fibres, bonne pour la digestion 🌿',
      healthBenefitEn: 'Rich in fiber, good for digestion 🌿',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'poire'),
        'en': FoodTranslation(name: 'pear'),
        'es': FoodTranslation(name: 'pera'),
        'de': FoodTranslation(name: 'birne'),
        'it': FoodTranslation(name: 'pera'),
        'pt': FoodTranslation(name: 'pera'),
        'nl': FoodTranslation(name: 'peer'),
        'ru': FoodTranslation(name: 'груша'),
        'zh': FoodTranslation(name: '梨'),
        'ja': FoodTranslation(name: '梨'),
        'ar': FoodTranslation(name: 'كمثرى'),
        'hi': FoodTranslation(name: 'नाशपाती'),
      },
    ),
    FoodItem(
      id: 'peche',
      category: 'fruit',
      imageUrl: 'assets/images/foods/peche.png',
      emoji: '🍑',
      funFactFr: 'La pêche est originaire de Chine il y a 8000 ans ! 🍑',
      funFactEn: 'Peaches originated in China 8000 years ago! 🍑',
      healthBenefitFr: 'Riche en vitamines A et C, bonne pour la peau ✨',
      healthBenefitEn: 'Rich in vitamins A and C, good for skin ✨',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'pêche'),
        'en': FoodTranslation(name: 'peach'),
        'es': FoodTranslation(name: 'melocotón'),
        'de': FoodTranslation(name: 'pfirsich'),
        'it': FoodTranslation(name: 'pesca'),
        'pt': FoodTranslation(name: 'pêssego'),
        'nl': FoodTranslation(name: 'perzik'),
        'ru': FoodTranslation(name: 'персик'),
        'zh': FoodTranslation(name: '桃子'),
        'ja': FoodTranslation(name: '桃'),
        'ar': FoodTranslation(name: 'خوخ'),
        'hi': FoodTranslation(name: 'आड़ू'),
      },
    ),
    FoodItem(
      id: 'ananas',
      category: 'fruit',
      imageUrl: 'assets/images/foods/ananas.png',
      emoji: '🍍',
      funFactFr: 'L\'ananas met 2 ans à pousser ! 🍍',
      funFactEn: 'Pineapples take 2 years to grow! 🍍',
      healthBenefitFr: 'Riche en bromélaïne, aide la digestion 🩺',
      healthBenefitEn: 'Rich in bromelain, helps digestion 🩺',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'ananas'),
        'en': FoodTranslation(name: 'pineapple'),
        'es': FoodTranslation(name: 'piña'),
        'de': FoodTranslation(name: 'ananas'),
        'it': FoodTranslation(name: 'ananas'),
        'pt': FoodTranslation(name: 'abacaxi'),
        'nl': FoodTranslation(name: 'ananas'),
        'ru': FoodTranslation(name: 'ананас'),
        'zh': FoodTranslation(name: '菠萝'),
        'ja': FoodTranslation(name: 'パイナップル'),
        'ar': FoodTranslation(name: 'أناناس'),
        'hi': FoodTranslation(name: 'अनानास'),
      },
    ),
    FoodItem(
      id: 'kiwi',
      category: 'fruit',
      imageUrl: 'assets/images/foods/kiwi.png',
      emoji: '🥝',
      funFactFr: 'Le kiwi contient plus de vitamine C que l\'orange ! 🥝',
      funFactEn: 'Kiwi contains more vitamin C than an orange! 🥝',
      healthBenefitFr: 'Bouffe l\'immunité, riche en vitamine C 💪',
      healthBenefitEn: 'Boosts immunity, rich in vitamin C 💪',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'kiwi'),
        'en': FoodTranslation(name: 'kiwi'),
        'es': FoodTranslation(name: 'kiwi'),
        'de': FoodTranslation(name: 'kiwi'),
        'it': FoodTranslation(name: 'kiwi'),
        'pt': FoodTranslation(name: 'kiwi'),
        'nl': FoodTranslation(name: 'kiwi'),
        'ru': FoodTranslation(name: 'киви'),
        'zh': FoodTranslation(name: '猕猴桃'),
        'ja': FoodTranslation(name: 'キウイ'),
        'ar': FoodTranslation(name: 'كيوي'),
        'hi': FoodTranslation(name: 'कीवी'),
      },
    ),
    FoodItem(
      id: 'mangue',
      category: 'fruit',
      imageUrl: 'assets/images/foods/mangue.png',
      emoji: '🥭',
      funFactFr: 'La mangue est le fruit le plus consommé dans le monde ! 🥭',
      funFactEn: 'Mango is the most consumed fruit in the world! 🥭',
      healthBenefitFr: 'Riche en vitamines A et C, bonne pour les yeux 👁️',
      healthBenefitEn: 'Rich in vitamins A and C, good for eyes 👁️',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'mangue'),
        'en': FoodTranslation(name: 'mango'),
        'es': FoodTranslation(name: 'mango'),
        'de': FoodTranslation(name: 'mango'),
        'it': FoodTranslation(name: 'mango'),
        'pt': FoodTranslation(name: 'manga'),
        'nl': FoodTranslation(name: 'mango'),
        'ru': FoodTranslation(name: 'манго'),
        'zh': FoodTranslation(name: '芒果'),
        'ja': FoodTranslation(name: 'マンゴー'),
        'ar': FoodTranslation(name: 'مانجو'),
        'hi': FoodTranslation(name: 'आम'),
      },
    ),
    FoodItem(
      id: 'pasteque',
      category: 'fruit',
      imageUrl: 'assets/images/foods/pasteque.png',
      emoji: '🍉',
      funFactFr: 'La pastèque est composée à 92% d\'eau ! 💧',
      funFactEn: 'Watermelon is 92% water! 💧',
      healthBenefitFr: 'Hydrate et riche en lycopène 💚',
      healthBenefitEn: 'Hydrating and rich in lycopene 💚',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'pastèque'),
        'en': FoodTranslation(name: 'watermelon'),
        'es': FoodTranslation(name: 'sandía'),
        'de': FoodTranslation(name: 'wassermelone'),
        'it': FoodTranslation(name: 'anguria'),
        'pt': FoodTranslation(name: 'melancia'),
        'nl': FoodTranslation(name: 'watermeloen'),
        'ru': FoodTranslation(name: 'арбуз'),
        'zh': FoodTranslation(name: '西瓜'),
        'ja': FoodTranslation(name: 'スイカ'),
        'ar': FoodTranslation(name: 'بطيخ'),
        'hi': FoodTranslation(name: 'तरबूज'),
      },
    ),

    // ==================== LÉGUMES ====================
    FoodItem(
      id: 'carotte',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/carotte.png',
      emoji: '🥕',
      funFactFr: 'Les premières carottes étaient violettes, pas oranges ! 🥕',
      funFactEn: 'The first carrots were purple, not orange! 🥕',
      healthBenefitFr: 'Riche en bêta-carotène, bonne pour la vue 👁️',
      healthBenefitEn: 'Rich in beta-carotene, good for eyesight 👁️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'carotte'),
        'en': FoodTranslation(name: 'carrot'),
        'es': FoodTranslation(name: 'zanahoria'),
        'de': FoodTranslation(name: 'karotte'),
        'it': FoodTranslation(name: 'carota'),
        'pt': FoodTranslation(name: 'cenoura'),
        'nl': FoodTranslation(name: 'wortel'),
        'ru': FoodTranslation(name: 'морковь'),
        'zh': FoodTranslation(name: '胡萝卜'),
        'ja': FoodTranslation(name: 'ニンジン'),
        'ar': FoodTranslation(name: 'جزر'),
        'hi': FoodTranslation(name: 'गाजर'),
      },
    ),
    FoodItem(
      id: 'brocoli',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/brocoli.png',
      emoji: '🥦',
      funFactFr: 'Le brocoli contient plus de protéines que le steak ! 🥦',
      funFactEn: 'Broccoli contains more protein than steak! 🥦',
      healthBenefitFr: 'Riche en fibres et anticancéreux 💪',
      healthBenefitEn: 'Rich in fiber and anti-cancer properties 💪',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'brocoli'),
        'en': FoodTranslation(name: 'broccoli'),
        'es': FoodTranslation(name: 'brócoli'),
        'de': FoodTranslation(name: 'brokkoli'),
        'it': FoodTranslation(name: 'broccolo'),
        'pt': FoodTranslation(name: 'brócolis'),
        'nl': FoodTranslation(name: 'broccoli'),
        'ru': FoodTranslation(name: 'брокколи'),
        'zh': FoodTranslation(name: '西兰花'),
        'ja': FoodTranslation(name: 'ブロッコリー'),
        'ar': FoodTranslation(name: 'بروكلي'),
        'hi': FoodTranslation(name: 'ब्रोकोली'),
      },
    ),
    FoodItem(
      id: 'tomate',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/tomate.png',
      emoji: '🍅',
      funFactFr: 'La tomate est botaniquement un fruit, mais culinairement un légume ! 🍅',
      funFactEn: 'Tomatoes are botanically a fruit, but culinarily a vegetable! 🍅',
      healthBenefitFr: 'Riche en lycopène, bon pour le cœur ❤️',
      healthBenefitEn: 'Rich in lycopene, good for the heart ❤️',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'tomate'),
        'en': FoodTranslation(name: 'tomato'),
        'es': FoodTranslation(name: 'tomate'),
        'de': FoodTranslation(name: 'tomate'),
        'it': FoodTranslation(name: 'pomodoro'),
        'pt': FoodTranslation(name: 'tomate'),
        'nl': FoodTranslation(name: 'tomaat'),
        'ru': FoodTranslation(name: 'помидор'),
        'zh': FoodTranslation(name: '番茄'),
        'ja': FoodTranslation(name: 'トマト'),
        'ar': FoodTranslation(name: 'طماطم'),
        'hi': FoodTranslation(name: 'टमाटर'),
      },
    ),
    FoodItem(
      id: 'concombre',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/concombre.png',
      emoji: '🥒',
      funFactFr: 'Le concombre est composé à 96% d\'eau ! 💧',
      funFactEn: 'Cucumbers are 96% water! 💧',
      healthBenefitFr: 'Hydrate et riche en vitamines K 💚',
      healthBenefitEn: 'Hydrating and rich in vitamin K 💚',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'concombre'),
        'en': FoodTranslation(name: 'cucumber'),
        'es': FoodTranslation(name: 'pepino'),
        'de': FoodTranslation(name: 'gurke'),
        'it': FoodTranslation(name: 'cetriolo'),
        'pt': FoodTranslation(name: 'pepino'),
        'nl': FoodTranslation(name: 'komkommer'),
        'ru': FoodTranslation(name: 'огурец'),
        'zh': FoodTranslation(name: '黄瓜'),
        'ja': FoodTranslation(name: 'キュウリ'),
        'ar': FoodTranslation(name: 'خيار'),
        'hi': FoodTranslation(name: 'खीरा'),
      },
    ),
    FoodItem(
      id: 'epinard',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/epinard.png',
      emoji: '🥬',
      funFactFr: 'Les épinards sont riches en fer et en vitamines ! 🥬',
      funFactEn: 'Spinach is rich in iron and vitamins! 🥬',
      healthBenefitFr: 'Riche en fer, bonne pour l\'énergie ⚡',
      healthBenefitEn: 'Rich in iron, good for energy ⚡',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'épinard'),
        'en': FoodTranslation(name: 'spinach'),
        'es': FoodTranslation(name: 'espinaca'),
        'de': FoodTranslation(name: 'spinat'),
        'it': FoodTranslation(name: 'spinaci'),
        'pt': FoodTranslation(name: 'espinafre'),
        'nl': FoodTranslation(name: 'spinazie'),
        'ru': FoodTranslation(name: 'шпинат'),
        'zh': FoodTranslation(name: '菠菜'),
        'ja': FoodTranslation(name: 'ホウレンソウ'),
        'ar': FoodTranslation(name: 'سبانخ'),
        'hi': FoodTranslation(name: 'पालक'),
      },
    ),
    FoodItem(
      id: 'poivron',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/poivron.png',
      emoji: '🫑',
      funFactFr: 'Les poivrons verts sont des poivrons rouges non mûrs ! 🫑',
      funFactEn: 'Green bell peppers are unripe red peppers! 🫑',
      healthBenefitFr: 'Riche en vitamine C, booste l\'immunité 🛡️',
      healthBenefitEn: 'Rich in vitamin C, boosts immunity 🛡️',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'poivron'),
        'en': FoodTranslation(name: 'bell pepper'),
        'es': FoodTranslation(name: 'pimiento'),
        'de': FoodTranslation(name: 'paprika'),
        'it': FoodTranslation(name: 'peperone'),
        'pt': FoodTranslation(name: 'pimentão'),
        'nl': FoodTranslation(name: 'paprika'),
        'ru': FoodTranslation(name: 'перец'),
        'zh': FoodTranslation(name: '甜椒'),
        'ja': FoodTranslation(name: 'ピーマン'),
        'ar': FoodTranslation(name: 'فلفل رومي'),
        'hi': FoodTranslation(name: 'शिमला मिर्च'),
      },
    ),
    FoodItem(
      id: 'chou-fleur',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/chou_fleur.png',
      emoji: '🥦',
      funFactFr: 'Le chou-fleur est une fleur ! 🌸',
      funFactEn: 'Cauliflower is a flower! 🌸',
      healthBenefitFr: 'Riche en antioxydants, bon pour la santé 🩺',
      healthBenefitEn: 'Rich in antioxidants, good for health 🩺',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'chou-fleur'),
        'en': FoodTranslation(name: 'cauliflower'),
        'es': FoodTranslation(name: 'coliflor'),
        'de': FoodTranslation(name: 'blumenkohl'),
        'it': FoodTranslation(name: 'cavolfiore'),
        'pt': FoodTranslation(name: 'couve-flor'),
        'nl': FoodTranslation(name: 'bloemkool'),
        'ru': FoodTranslation(name: 'цветная капуста'),
        'zh': FoodTranslation(name: '菜花'),
        'ja': FoodTranslation(name: 'カリフラワー'),
        'ar': FoodTranslation(name: 'قرنبيط'),
        'hi': FoodTranslation(name: 'फूलगोभी'),
      },
    ),
    FoodItem(
      id: 'aubergine',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/aubergine.png',
      emoji: '🍆',
      funFactFr: 'L\'aubergine est techniquement une baie ! 🍆',
      funFactEn: 'Eggplant is technically a berry! 🍆',
      healthBenefitFr: 'Riche en fibres, bonne pour la digestion 🌿',
      healthBenefitEn: 'Rich in fiber, good for digestion 🌿',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'aubergine'),
        'en': FoodTranslation(name: 'eggplant'),
        'es': FoodTranslation(name: 'berenjena'),
        'de': FoodTranslation(name: 'aubergine'),
        'it': FoodTranslation(name: 'melanzana'),
        'pt': FoodTranslation(name: 'berinjela'),
        'nl': FoodTranslation(name: 'aubergine'),
        'ru': FoodTranslation(name: 'баклажан'),
        'zh': FoodTranslation(name: '茄子'),
        'ja': FoodTranslation(name: 'ナス'),
        'ar': FoodTranslation(name: 'باذنجان'),
        'hi': FoodTranslation(name: 'बैंगन'),
      },
    ),
    FoodItem(
      id: 'courgette',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/courgette.png',
      emoji: '🥒',
      funFactFr: 'La courgette est une courge récoltée avant maturité ! 🥒',
      funFactEn: 'Zucchini is a squash harvested before maturity! 🥒',
      healthBenefitFr: 'Riche en eau et pauvre en calories 💧',
      healthBenefitEn: 'Rich in water and low in calories 💧',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'courgette'),
        'en': FoodTranslation(name: 'zucchini'),
        'es': FoodTranslation(name: 'calabacín'),
        'de': FoodTranslation(name: 'zucchini'),
        'it': FoodTranslation(name: 'zucchina'),
        'pt': FoodTranslation(name: 'abobrinha'),
        'nl': FoodTranslation(name: 'courgette'),
        'ru': FoodTranslation(name: 'кабачок'),
        'zh': FoodTranslation(name: '西葫芦'),
        'ja': FoodTranslation(name: 'ズッキーニ'),
        'ar': FoodTranslation(name: 'كوسة'),
        'hi': FoodTranslation(name: 'तोरी'),
      },
    ),
    FoodItem(
      id: 'radis',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/radis.png',
      emoji: '🥬',
      funFactFr: 'Le radis est de la famille du chou ! 🥬',
      funFactEn: 'Radishes are in the cabbage family! 🥬',
      healthBenefitFr: 'Riche en vitamine C et potassium 💪',
      healthBenefitEn: 'Rich in vitamin C and potassium 💪',
      difficulty: 1,
      basePoints: 15,
      translations: {
        'fr': FoodTranslation(name: 'radis'),
        'en': FoodTranslation(name: 'radish'),
        'es': FoodTranslation(name: 'rábano'),
        'de': FoodTranslation(name: 'rettich'),
        'it': FoodTranslation(name: 'ravanello'),
        'pt': FoodTranslation(name: 'rabanete'),
        'nl': FoodTranslation(name: 'radijs'),
        'ru': FoodTranslation(name: 'редис'),
        'zh': FoodTranslation(name: '萝卜'),
        'ja': FoodTranslation(name: 'ラディッシュ'),
        'ar': FoodTranslation(name: 'فجل'),
        'hi': FoodTranslation(name: 'मूली'),
      },
    ),
    FoodItem(
      id: 'oignon',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/oignon.png',
      emoji: '🧅',
      funFactFr: 'Couper un oignon fait pleurer à cause de l\'acide sulfénique ! 😢',
      funFactEn: 'Cutting an onion makes you cry because of sulfenic acid! 😢',
      healthBenefitFr: 'Antibactérien naturel, bon pour le cœur ❤️',
      healthBenefitEn: 'Natural antibacterial, good for the heart ❤️',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'oignon'),
        'en': FoodTranslation(name: 'onion'),
        'es': FoodTranslation(name: 'cebolla'),
        'de': FoodTranslation(name: 'zwiebel'),
        'it': FoodTranslation(name: 'cipolla'),
        'pt': FoodTranslation(name: 'cebola'),
        'nl': FoodTranslation(name: 'ui'),
        'ru': FoodTranslation(name: 'лук'),
        'zh': FoodTranslation(name: '洋葱'),
        'ja': FoodTranslation(name: 'タマネギ'),
        'ar': FoodTranslation(name: 'بصل'),
        'hi': FoodTranslation(name: 'प्याज'),
      },
    ),
    FoodItem(
      id: 'ail',
      category: 'vegetable',
      imageUrl: 'assets/images/foods/ail.png',
      emoji: '🧄',
      funFactFr: 'L\'ail était utilisé comme remède dans l\'Égypte ancienne ! 🧄',
      funFactEn: 'Garlic was used as medicine in ancient Egypt! 🧄',
      healthBenefitFr: 'Antibactérien et bon pour le système immunitaire 🛡️',
      healthBenefitEn: 'Antibacterial and good for the immune system 🛡️',
      difficulty: 2,
      basePoints: 20,
      translations: {
        'fr': FoodTranslation(name: 'ail'),
        'en': FoodTranslation(name: 'garlic'),
        'es': FoodTranslation(name: 'ajo'),
        'de': FoodTranslation(name: 'knoblauch'),
        'it': FoodTranslation(name: 'aglio'),
        'pt': FoodTranslation(name: 'alho'),
        'nl': FoodTranslation(name: 'knoflook'),
        'ru': FoodTranslation(name: 'чеснок'),
        'zh': FoodTranslation(name: '大蒜'),
        'ja': FoodTranslation(name: 'ニンニク'),
        'ar': FoodTranslation(name: 'ثوم'),
        'hi': FoodTranslation(name: 'लहसुन'),
      },
    ),
  ];

  // Getters
  static List<FoodItem> get fruits => allFoods.where((f) => f.category == 'fruit').toList();
  static List<FoodItem> get vegetables => allFoods.where((f) => f.category == 'vegetable').toList();
  
  static List<FoodItem> get shuffledFruits {
    final shuffled = List<FoodItem>.from(fruits);
    shuffled.shuffle();
    return shuffled;
  }
  
  static List<FoodItem> get shuffledVegetables {
    final shuffled = List<FoodItem>.from(vegetables);
    shuffled.shuffle();
    return shuffled;
  }
  
  static List<FoodItem> getFoodsByCategory(String category) {
    return allFoods.where((food) => food.category == category).toList();
  }
  
  static FoodItem? getFoodById(String id) {
    try {
      return allFoods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }
}