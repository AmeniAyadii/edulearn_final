class AnimalData {
  final String id;
  final String imageUrl;
  final Map<String, String> names; // code langue -> nom
  
  const AnimalData({
    required this.id,
    required this.imageUrl,
    required this.names,
  });
}

class GameAnimalsDatabase {
  static const List<AnimalData> animals = [
    AnimalData(
      id: 'lion',
      imageUrl: 'assets/images/animals/lion.png',
      names: {
        'fr': 'lion',
        'en': 'lion',
        'es': 'león',
        'de': 'löwe',
        'it': 'leone',
        'pt': 'leão',
        'nl': 'leeuw',
        'ru': 'лев',
        'zh': '狮子',
        'ja': 'ライオン',
        'ar': 'أسد',
        'hi': 'शेर',
      },
    ),
    AnimalData(
      id: 'elephant',
      imageUrl: 'assets/images/animals/elephant.png',
      names: {
        'fr': 'éléphant',
        'en': 'elephant',
        'es': 'elefante',
        'de': 'elefant',
        'it': 'elefante',
        'pt': 'elefante',
        'nl': 'olifant',
        'ru': 'слон',
        'zh': '大象',
        'ja': 'ゾウ',
        'ar': 'فيل',
        'hi': 'हाथी',
      },
    ),
    AnimalData(
      id: 'giraffe',
      imageUrl: 'assets/images/animals/giraffe.png',
      names: {
        'fr': 'girafe',
        'en': 'giraffe',
        'es': 'jirafa',
        'de': 'giraffe',
        'it': 'giraffa',
        'pt': 'girafa',
        'nl': 'giraf',
        'ru': 'жираф',
        'zh': '长颈鹿',
        'ja': 'キリン',
        'ar': 'زرافة',
        'hi': 'जिराफ',
      },
    ),
    AnimalData(
      id: 'panda',
      imageUrl: 'assets/images/animals/panda.png',
      names: {
        'fr': 'panda',
        'en': 'panda',
        'es': 'panda',
        'de': 'panda',
        'it': 'panda',
        'pt': 'panda',
        'nl': 'panda',
        'ru': 'панда',
        'zh': '熊猫',
        'ja': 'パンダ',
        'ar': 'باندا',
        'hi': 'पांडा',
      },
    ),
    AnimalData(
      id: 'tiger',
      imageUrl: 'assets/images/animals/tiger.png',
      names: {
        'fr': 'tigre',
        'en': 'tiger',
        'es': 'tigre',
        'de': 'tiger',
        'it': 'tigre',
        'pt': 'tigre',
        'nl': 'tijger',
        'ru': 'тигр',
        'zh': '老虎',
        'ja': 'トラ',
        'ar': 'نمر',
        'hi': 'बाघ',
      },
    ),
    AnimalData(
      id: 'zebra',
      imageUrl: 'assets/images/animals/zebra.png',
      names: {
        'fr': 'zèbre',
        'en': 'zebra',
        'es': 'cebra',
        'de': 'zebra',
        'it': 'zebra',
        'pt': 'zebra',
        'nl': 'zebra',
        'ru': 'зебра',
        'zh': '斑马',
        'ja': 'シマウマ',
        'ar': 'حمار وحشي',
        'hi': 'ज़ेबरा',
      },
    ),
    AnimalData(
      id: 'monkey',
      imageUrl: 'assets/images/animals/monkey.png',
      names: {
        'fr': 'singe',
        'en': 'monkey',
        'es': 'mono',
        'de': 'affe',
        'it': 'scimmia',
        'pt': 'macaco',
        'nl': 'aap',
        'ru': 'обезьяна',
        'zh': '猴子',
        'ja': 'サル',
        'ar': 'قرد',
        'hi': 'बंदर',
      },
    ),
    AnimalData(
      id: 'dolphin',
      imageUrl: 'assets/images/animals/dolphin.png',
      names: {
        'fr': 'dauphin',
        'en': 'dolphin',
        'es': 'delfín',
        'de': 'delfin',
        'it': 'delfino',
        'pt': 'golfinho',
        'nl': 'dolfijn',
        'ru': 'дельфин',
        'zh': '海豚',
        'ja': 'イルカ',
        'ar': 'دلفين',
        'hi': 'डॉल्फिन',
      },
    ),
  ];
  
  static List<AnimalData> get shuffledAnimals {
    final shuffled = List<AnimalData>.from(animals);
    shuffled.shuffle();
    return shuffled;
  }
}