// lib/services/advanced_landmark_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// MODÈLES DE DONNÉES AVANCÉS
// ============================================================================

class LandmarkInfo {
  final String id;
  final String name;
  final String nameEn;
  final String location;
  final GeoCoordinates coordinates;
  final List<String> facts;
  final String shortDescription;
  final String longDescription;
  final String question;
  final String answer;
  final String funFact;
  final String funFactEn;
  final List<String> images;
  final String videoUrl;
  final int yearBuilt;
  final String architect;
  final double height;
  final int visitorsPerYear;
  final List<String> tags;
  final List<Review> reviews;
  final double rating;
  final bool isUNESCO;
  final String openingHours;
  final double ticketPrice;
  final String currency;
  final List<String> nearbyAttractions;
  
  LandmarkInfo({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.coordinates,
    required this.facts,
    required this.shortDescription,
    required this.longDescription,
    required this.question,
    required this.answer,
    required this.funFact,
    required this.funFactEn,
    required this.images,
    required this.videoUrl,
    required this.yearBuilt,
    required this.architect,
    required this.height,
    required this.visitorsPerYear,
    required this.tags,
    required this.reviews,
    required this.rating,
    required this.isUNESCO,
    required this.openingHours,
    required this.ticketPrice,
    required this.currency,
    required this.nearbyAttractions,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'location': location,
    'coordinates': coordinates.toJson(),
    'facts': facts,
    'shortDescription': shortDescription,
    'longDescription': longDescription,
    'question': question,
    'answer': answer,
    'funFact': funFact,
    'funFactEn': funFactEn,
    'images': images,
    'videoUrl': videoUrl,
    'yearBuilt': yearBuilt,
    'architect': architect,
    'height': height,
    'visitorsPerYear': visitorsPerYear,
    'tags': tags,
    'reviews': reviews.map((r) => r.toJson()).toList(),
    'rating': rating,
    'isUNESCO': isUNESCO,
    'openingHours': openingHours,
    'ticketPrice': ticketPrice,
    'currency': currency,
    'nearbyAttractions': nearbyAttractions,
  };
}

class GeoCoordinates {
  final double latitude;
  final double longitude;
  
  GeoCoordinates({required this.latitude, required this.longitude});
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class Review {
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  
  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'date': date.toIso8601String(),
  };
}

class DetectionResult {
  final bool success;
  final List<DetectedLandmark> landmarks;
  final double processingTime;
  final String? error;
  final DateTime timestamp;
  
  DetectionResult({
    required this.success,
    required this.landmarks,
    required this.processingTime,
    this.error,
    required this.timestamp,
  });
}

class DetectedLandmark {
  final LandmarkInfo? landmark;
  final String detectedLabel;
  final double confidence;
  final Rect boundingBox;
  final String detectionMethod; // 'object_detection', 'image_labeling', 'custom'
  
  DetectedLandmark({
    this.landmark,
    required this.detectedLabel,
    required this.confidence,
    required this.boundingBox,
    required this.detectionMethod,
  });
}

class DetectionStatistics {
  int totalDetections;
  int successfulDetections;
  int failedDetections;
  double averageConfidence;
  double averageProcessingTime;
  Map<String, int> landmarksCount;
  List<DateTime> detectionHistory;
  
  DetectionStatistics({
    this.totalDetections = 0,
    this.successfulDetections = 0,
    this.failedDetections = 0,
    this.averageConfidence = 0.0,
    this.averageProcessingTime = 0.0,
    this.landmarksCount = const {},
    this.detectionHistory = const [],
  });
  
  double get successRate => totalDetections > 0 
      ? successfulDetections / totalDetections 
      : 0.0;
}

// ============================================================================
// SERVICE PRINCIPAL
// ============================================================================

class AdvancedLandmarkService {
  late ObjectDetector _objectDetector;
  late ImageLabeler _imageLabeler;
  
  // Base de données complète des monuments
  static final Map<String, LandmarkInfo> _landmarkDatabase = _buildDatabase();
  
  // Cache pour les résultats
  final Map<String, DetectionResult> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  // Statistiques
  DetectionStatistics _stats = DetectionStatistics();
  
  // Configuration
  double _minConfidence = 0.5;
  bool _useCache = true;
  bool _useImageLabeling = true;
  
  AdvancedLandmarkService() {
    _initializeDetectors();
    _loadSettings();
  }
  
  static Map<String, LandmarkInfo> _buildDatabase() {
    return {
      // Tour Eiffel - Version complète
      'eiffel_tower': LandmarkInfo(
        id: 'eiffel_tower',
        name: 'Tour Eiffel',
        nameEn: 'Eiffel Tower',
        location: 'Paris, France',
        coordinates: GeoCoordinates(latitude: 48.8584, longitude: 2.2945),
        facts: [
          'Construite entre 1887 et 1889',
          'Hauteur: 330 mètres',
          'Poids: 10 100 tonnes',
          '18 038 pièces métalliques',
          '2 500 000 rivets',
          '60 tonnes de peinture tous les 7 ans',
          '300 millions de visiteurs depuis son inauguration',
          'Antenne radio et TV de 60 mètres'
        ],
        shortDescription: 'Symbole emblématique de Paris et chef-d\'œuvre de Gustave Eiffel.',
        longDescription: '''La Tour Eiffel est une tour de fer puddlé de 330 mètres de hauteur située à Paris, à l’extrémité nord-ouest du parc du Champ-de-Mars en bordure de la Seine. Construite par Gustave Eiffel et ses collaborateurs pour l'Exposition universelle de 1889, elle est devenue le symbole de la capitale française et un monument emblématique du tourisme mondial.

Initialement nommée "tour de 300 mètres", elle a été construite pour célébrer le centenaire de la Révolution française. Bien que critiquée à ses débuts par certains artistes, elle est aujourd'hui considérée comme une prouesse technique et artistique.''',
        question: 'Pourquoi la Tour Eiffel a-t-elle été construite ?',
        answer: 'Pour l\'Exposition Universelle de 1889 et le centenaire de la Révolution française.',
        funFact: 'Elle grandit l\'été ! Sous l\'effet de la chaleur, elle peut mesurer jusqu\'à 18 cm de plus 🌞',
        funFactEn: 'It grows in summer! Due to heat, it can be up to 18 cm taller 🌞',
        images: [
          'https://upload.wikimedia.org/wikipedia/commons/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg',
          'https://www.paris-zein.fr/wp-content/uploads/2019/10/tour-eiffel-paris.jpg',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=9vqR6bJklw8',
        yearBuilt: 1889,
        architect: 'Gustave Eiffel',
        height: 330.0,
        visitorsPerYear: 7000000,
        tags: ['monument', 'tour', 'paris', 'france', 'patrimoine'],
        reviews: [],
        rating: 4.8,
        isUNESCO: true,
        openingHours: '09:30 - 23:45 quotidien',
        ticketPrice: 25.0,
        currency: 'EUR',
        nearbyAttractions: ['Arc de Triomphe', 'Louvre Museum', 'Notre-Dame', 'Champs-Élysées'],
      ),
      
      // Colisée
      'colosseum': LandmarkInfo(
        id: 'colosseum',
        name: 'Colisée',
        nameEn: 'Colosseum',
        location: 'Rome, Italie',
        coordinates: GeoCoordinates(latitude: 41.8902, longitude: 12.4922),
        facts: [
          'Construit entre 70-80 après J.-C.',
          'Capacité: 50 000 à 80 000 spectateurs',
          '80 entrées',
          'Hauteur: 48 mètres',
          'Matériaux: travertin, tuf et brique',
          'Superficie: 24 000 m²',
          'Période de construction: 8 ans',
          'Classé au patrimoine mondial de l\'UNESCO depuis 1980'
        ],
        shortDescription: 'Le plus grand amphithéâtre jamais construit dans l\'Empire romain.',
        longDescription: '''Le Colisée est un amphithéâtre situé dans le centre de Rome. Construit à l'époque de l'Empire romain, il était destiné aux combats de gladiateurs et aux spectacles publics. Il pouvait accueillir jusqu'à 80 000 spectateurs.

Son nom officiel était "Amphithéâtre Flavien". Il est considéré comme l'une des plus grandes œuvres de l'architecture et de l'ingénierie romaines.''',
        question: 'Quel était le nom antique du Colisée ?',
        answer: 'L\'Amphithéâtre Flavien',
        funFact: 'Il pouvait être rempli d\'eau pour des batailles navales simulées ! 🌊',
        funFactEn: 'It could be flooded for simulated naval battles! 🌊',
        images: [
          'https://upload.wikimedia.org/wikipedia/commons/d/dd/Colosseo_2020.jpg',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=GXoRZl7zK0A',
        yearBuilt: 80,
        architect: 'Vespasien et Titus',
        height: 48.0,
        visitorsPerYear: 7600000,
        tags: ['amphitheatre', 'rome', 'italy', 'gladiators'],
        reviews: [],
        rating: 4.9,
        isUNESCO: true,
        openingHours: '08:30 - 19:00',
        ticketPrice: 16.0,
        currency: 'EUR',
        nearbyAttractions: ['Roman Forum', 'Palatine Hill', 'Trevi Fountain'],
      ),
      
      // Pyramides de Gizeh
      'pyramids': LandmarkInfo(
        id: 'pyramids',
        name: 'Pyramides de Gizeh',
        nameEn: 'Pyramids of Giza',
        location: 'Gizeh, Égypte',
        coordinates: GeoCoordinates(latitude: 29.9792, longitude: 31.1342),
        facts: [
          'Construites vers 2560 av. J.-C.',
          'Hauteur originale de Khéops: 146.6 mètres',
          'Hauteur actuelle: 138.8 mètres',
          '2 300 000 blocs de pierre',
          'Poids total: 6 millions de tonnes',
          'Chaque bloc pèse 2.5 tonnes',
          'Construction sur 20 ans',
          '100 000 travailleurs'
        ],
        shortDescription: 'La seule merveille du monde antique encore debout.',
        longDescription: '''Les pyramides de Gizeh sont un ensemble de pyramides égyptiennes situées à Gizeh, sur le plateau de Gizeh, à la périphérie du Caire. Les trois pyramides principales sont celles de Khéops, Khéphren et Mykérinos.

Elles servaient de tombeaux aux pharaons et sont considérées comme l'un des symboles les plus emblématiques de la civilisation égyptienne antique.''',
        question: 'Combien de pyramides y a-t-il à Gizeh ?',
        answer: '3 pyramides principales (Khéops, Khéphren, Mykérinos)',
        funFact: 'Les pyramides sont parfaitement alignées avec les étoiles de la ceinture d\'Orion ✨',
        funFactEn: 'The pyramids are perfectly aligned with the stars of Orion\'s Belt ✨',
        images: [
          'https://upload.wikimedia.org/wikipedia/commons/e/e3/Kheops-Pyramid.jpg',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=vf9I1_R9I7o',
        yearBuilt: -2560,
        architect: 'Hémiounou',
        height: 138.8,
        visitorsPerYear: 14800000,
        tags: ['pyramid', 'egypt', 'ancient', 'pharaoh'],
        reviews: [],
        rating: 4.7,
        isUNESCO: true,
        openingHours: '08:00 - 17:00',
        ticketPrice: 200.0,
        currency: 'EGP',
        nearbyAttractions: ['Sphinx', 'Cairo Museum', 'Nile River'],
      ),
      
      // Taj Mahal
      'taj_mahal': LandmarkInfo(
        id: 'taj_mahal',
        name: 'Taj Mahal',
        nameEn: 'Taj Mahal',
        location: 'Agra, Inde',
        coordinates: GeoCoordinates(latitude: 27.1751, longitude: 78.0421),
        facts: [
          'Construit entre 1631 et 1653',
          '22 ans de construction',
          '22 000 ouvriers',
          '1 000 éléphants',
          'Marbre blanc du Rajasthan',
          'Pierres précieuses incrustées',
          'Coût: environ 32 millions de roupies',
          'Jardins de 300 mètres'
        ],
        shortDescription: 'Mausolée de marbre blanc, symbole d\'amour éternel.',
        longDescription: '''Le Taj Mahal est un mausolée de marbre blanc situé à Agra, en Inde. Il a été commandé par l'empereur moghol Shah Jahan en mémoire de son épouse préférée, Mumtaz Mahal.

Reconnu comme "joyau de l'art musulman en Inde", il est l'un des exemples les plus célèbres d'architecture moghole.''',
        question: 'Pourquoi le Taj Mahal a-t-il été construit ?',
        answer: 'Par l\'empereur Shah Jahan pour son épouse Mumtaz Mahal',
        funFact: 'Il change de couleur selon l\'heure de la journée ! 🌅',
        funFactEn: 'It changes color according to the time of day! 🌅',
        images: [
          'https://upload.wikimedia.org/wikipedia/commons/6/62/Taj_Mahal_%28Edited%29.jpeg',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=49HTIodjM1Q',
        yearBuilt: 1653,
        architect: 'Ustad Ahmad Lahauri',
        height: 73.0,
        visitorsPerYear: 8000000,
        tags: ['mausoleum', 'india', 'marble', 'love'],
        reviews: [],
        rating: 4.9,
        isUNESCO: true,
        openingHours: '06:00 - 19:00 (fermé vendredi)',
        ticketPrice: 1100.0,
        currency: 'INR',
        nearbyAttractions: ['Agra Fort', 'Fatehpur Sikri', 'Mehtab Bagh'],
      ),
    };
  }
  
  Future<void> _initializeDetectors() async {
    // Object Detector pour détection précise
    final objectOptions = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectOptions);
    
    // Image Labeler pour reconnaissance générale
    final labelOptions = ImageLabelerOptions(
      confidenceThreshold: 0.6,
    );
    _imageLabeler = ImageLabeler(options: labelOptions);
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _minConfidence = prefs.getDouble('min_confidence') ?? 0.5;
      _useCache = prefs.getBool('use_cache') ?? true;
      _useImageLabeling = prefs.getBool('use_image_labeling') ?? true;
    } catch (e) {
      print('Erreur chargement settings: $e');
    }
  }
  
  /// Méthode principale de détection
  Future<DetectionResult> detectLandmarks(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    final imageHash = await _computeImageHash(imageFile);
    
    // Vérifier le cache
    if (_useCache && _cache.containsKey(imageHash)) {
      final cached = _cache[imageHash]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        stopwatch.stop();
        return cached;
      }
    }
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      
      // Détection parallèle
      final results = await Future.wait([
        _objectDetector.processImage(inputImage),
        if (_useImageLabeling) _imageLabeler.processImage(inputImage),
      ]);
      
      final detectedObjects = results[0] as List<DetectedObject>;
      final imageLabels = _useImageLabeling 
          ? results[1] as List<ImageLabel>? 
          : null;
      
      // Traitement des résultats
      final landmarks = <DetectedLandmark>[];
      
      // 1. Traitement Object Detection
      for (final obj in detectedObjects) {
        for (final label in obj.labels) {
          if (label.confidence >= _minConfidence) {
            final landmark = _findLandmarkByName(label.text);
            if (landmark != null) {
              landmarks.add(DetectedLandmark(
                landmark: landmark,
                detectedLabel: label.text,
                confidence: label.confidence,
                boundingBox: obj.boundingBox,
                detectionMethod: 'object_detection',
              ));
            }
          }
        }
      }
      
      // 2. Traitement Image Labeling (fallback)
      if (landmarks.isEmpty && imageLabels != null) {
        for (final label in imageLabels) {
          if (label.confidence >= _minConfidence) {
            final landmark = _findLandmarkByName(label.label);
            if (landmark != null) {
              landmarks.add(DetectedLandmark(
                landmark: landmark,
                detectedLabel: label.label,
                confidence: label.confidence,
                boundingBox: Rect.zero,
                detectionMethod: 'image_labeling',
              ));
            }
          }
        }
      }
      
      // 3. Si rien trouvé, suggestions par mots-clés
      if (landmarks.isEmpty && imageLabels != null) {
        for (final label in imageLabels) {
          final suggestion = _suggestLandmarksByKeyword(label.label);
          if (suggestion != null) {
            landmarks.add(DetectedLandmark(
              landmark: suggestion,
              detectedLabel: label.label,
              confidence: label.confidence * 0.7, // Pénalité pour suggestion
              boundingBox: Rect.zero,
              detectionMethod: 'custom_suggestion',
            ));
          }
        }
      }
      
      // Trier par confiance
      landmarks.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Mettre à jour les statistiques
      _updateStatistics(landmarks.isNotEmpty, stopwatch.elapsedMilliseconds / 1000);
      
      // Mettre en cache
      final result = DetectionResult(
        success: landmarks.isNotEmpty,
        landmarks: landmarks,
        processingTime: stopwatch.elapsedMilliseconds / 1000,
        timestamp: DateTime.now(),
      );
      
      if (_useCache) {
        _cache[imageHash] = result;
      }
      
      stopwatch.stop();
      return result;
      
    } catch (e) {
      print('❌ Erreur détection: $e');
      _updateStatistics(false, stopwatch.elapsedMilliseconds / 1000);
      
      return DetectionResult(
        success: false,
        landmarks: [],
        processingTime: stopwatch.elapsedMilliseconds / 1000,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
  
  LandmarkInfo? _findLandmarkByName(String name) {
    final lowerName = name.toLowerCase();
    
    // Recherche directe
    for (final landmark in _landmarkDatabase.values) {
      if (landmark.name.toLowerCase().contains(lowerName) ||
          landmark.nameEn.toLowerCase().contains(lowerName)) {
        return landmark;
      }
    }
    
    // Recherche par tags
    for (final landmark in _landmarkDatabase.values) {
      if (landmark.tags.any((tag) => lowerName.contains(tag))) {
        return landmark;
      }
    }
    
    return null;
  }
  
  LandmarkInfo? _suggestLandmarksByKeyword(String keyword) {
    final keywordMap = {
      'tower': 'eiffel_tower',
      'tour': 'eiffel_tower',
      'eiffel': 'eiffel_tower',
      'coliseum': 'colosseum',
      'colosseum': 'colosseum',
      'amphitheatre': 'colosseum',
      'pyramid': 'pyramids',
      'pyramide': 'pyramids',
      'taj': 'taj_mahal',
      'mausoleum': 'taj_mahal',
    };
    
    final lowerKeyword = keyword.toLowerCase();
    for (final entry in keywordMap.entries) {
      if (lowerKeyword.contains(entry.key)) {
        return _landmarkDatabase[entry.value];
      }
    }
    return null;
  }
  
  // Remplacer la méthode _computeImageHash par celle-ci :

Future<String> _computeImageHash(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    // CORRECTION: Convertir Iterable<int> en List<int>
    final List<int> firstBytes = bytes.take(1000).toList();
    return base64.encode(firstBytes);
  } catch (e) {
    return DateTime.now().toString();
  }
}
  
  void _updateStatistics(bool success, double processingTime) {
    _stats.totalDetections++;
    if (success) {
      _stats.successfulDetections++;
    } else {
      _stats.failedDetections++;
    }
    
    // Mise à jour moyenne temps
    _stats.averageProcessingTime = 
        (_stats.averageProcessingTime * (_stats.totalDetections - 1) + processingTime) 
        / _stats.totalDetections;
    
    _stats.detectionHistory = [..._stats.detectionHistory, DateTime.now()];
    if (_stats.detectionHistory.length > 100) {
      _stats.detectionHistory = _stats.detectionHistory.sublist(_stats.detectionHistory.length - 100);
    }
  }
  
  /// Obtenir les statistiques de détection
  DetectionStatistics getStatistics() => _stats;
  
  /// Réinitialiser les statistiques
  void resetStatistics() {
    _stats = DetectionStatistics();
  }
  
  /// Configurer la confiance minimale
  Future<void> setMinConfidence(double confidence) async {
    _minConfidence = confidence.clamp(0.3, 0.9);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('min_confidence', _minConfidence);
  }
  
  /// Vider le cache
  void clearCache() {
    _cache.clear();
  }
  
  /// Obtenir tous les monuments disponibles
  List<LandmarkInfo> getAllLandmarks() {
    return _landmarkDatabase.values.toList();
  }
  
  /// Obtenir un monument par ID
  LandmarkInfo? getLandmarkById(String id) {
    return _landmarkDatabase[id];
  }
  
  /// Rechercher des monuments par tag
  List<LandmarkInfo> searchLandmarksByTag(String tag) {
    return _landmarkDatabase.values
        .where((l) => l.tags.contains(tag.toLowerCase()))
        .toList();
  }
  
  /// Obtenir les monuments à proximité (simulation)
  List<LandmarkInfo> getNearbyLandmarks(GeoCoordinates location, {double radius = 10}) {
    // Simulation - retourne tous les monuments
    return _landmarkDatabase.values.toList();
  }
  
  /// Nettoyage
  void dispose() {
    _objectDetector.close();
    _imageLabeler.close();
    _cache.clear();
  }
}

// ============================================================================
// EXTENSIONS UTILES
// ============================================================================

extension LandmarkInfoExtension on LandmarkInfo {
  String get formattedHeight {
    if (height > 0) {
      return '${height.toStringAsFixed(0)} mètres';
    }
    return 'Inconnue';
  }
  
  String get formattedVisitors {
    if (visitorsPerYear > 1000000) {
      return '${(visitorsPerYear / 1000000).toStringAsFixed(1)} millions/an';
    }
    return '$visitorsPerYear/an';
  }
  
  String get ratingStars {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    return '⭐' * fullStars + (hasHalfStar ? '½' : '');
  }
}