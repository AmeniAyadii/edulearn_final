// lib/screens/games/animal_writing_game_mlkit.dart

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

// ML Kit Imports
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

// ============================================================================
// MODÈLES
// ============================================================================

class AnimalMLKit {
  final String id;
  final String nameFr;
  final String nameEn;
  final String nameEs;
  final String scientificName;
  final String funFactFr;
  final String emoji;
  final int basePoints;
  Map<String, AnimalTranslationMLKit> translations;
  bool isDiscovered;
  
  AnimalMLKit({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.nameEs,
    required this.scientificName,
    required this.funFactFr,
    required this.emoji,
    this.basePoints = 50,
    Map<String, AnimalTranslationMLKit>? translations,
    this.isDiscovered = false,
  }) : translations = translations ?? {};

  String getNameInLanguage(String languageCode) {
    switch (languageCode) {
      case 'fr': return nameFr;
      case 'en': return nameEn;
      case 'es': return nameEs;
      default: return nameFr;
    }
  }
  
  String getFunFact(String languageCode) {
    if (languageCode == 'fr') return funFactFr;
    return funFactFr;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameFr': nameFr,
      'nameEn': nameEn,
      'nameEs': nameEs,
      'scientificName': scientificName,
      'funFactFr': funFactFr,
      'emoji': emoji,
      'basePoints': basePoints,
      'isDiscovered': isDiscovered,
    };
  }
}

class AnimalTranslationMLKit {
  final String languageCode;
  final String name;
  bool isMastered;
  
  AnimalTranslationMLKit({
    required this.languageCode,
    required this.name,
    this.isMastered = false,
  });
}

// ============================================================================
// BASE DE DONNÉES DES ANIMAUX
// ============================================================================

class AnimalsDatabaseMLKit {
  static final List<AnimalMLKit> animals = [
    AnimalMLKit(
      id: 'lion',
      nameFr: 'Lion',
      nameEn: 'Lion',
      nameEs: 'León',
      scientificName: 'Panthera leo',
      funFactFr: 'Le lion est le seul félin à vivre en groupe, appelé "troupe" ou "clan".',
      emoji: '🦁',
    ),
    AnimalMLKit(
      id: 'elephant',
      nameFr: 'Éléphant',
      nameEn: 'Elephant',
      nameEs: 'Elefante',
      scientificName: 'Loxodonta africana',
      funFactFr: 'Les éléphants sont les plus grands animaux terrestres vivants.',
      emoji: '🐘',
    ),
    AnimalMLKit(
      id: 'giraffe',
      nameFr: 'Girafe',
      nameEn: 'Giraffe',
      nameEs: 'Jirafa',
      scientificName: 'Giraffa camelopardalis',
      funFactFr: 'La girafe est le mammifère le plus grand du monde.',
      emoji: '🦒',
    ),
    AnimalMLKit(
      id: 'tiger',
      nameFr: 'Tigre',
      nameEn: 'Tiger',
      nameEs: 'Tigre',
      scientificName: 'Panthera tigris',
      funFactFr: 'Chaque tigre a des rayures uniques, comme les empreintes digitales humaines.',
      emoji: '🐯',
    ),
    AnimalMLKit(
      id: 'panda',
      nameFr: 'Panda',
      nameEn: 'Panda',
      nameEs: 'Panda',
      scientificName: 'Ailuropoda melanoleuca',
      funFactFr: 'Les pandas passent jusqu\'à 14 heures par jour à manger du bambou.',
      emoji: '🐼',
    ),
    AnimalMLKit(
      id: 'kangaroo',
      nameFr: 'Kangourou',
      nameEn: 'Kangaroo',
      nameEs: 'Canguro',
      scientificName: 'Macropus',
      funFactFr: 'Les kangourous ne peuvent pas reculer, seulement avancer.',
      emoji: '🦘',
    ),
    AnimalMLKit(
      id: 'penguin',
      nameFr: 'Manchot',
      nameEn: 'Penguin',
      nameEs: 'Pingüino',
      scientificName: 'Spheniscidae',
      funFactFr: 'Les manchots peuvent rester sous l\'eau jusqu\'à 20 minutes.',
      emoji: '🐧',
    ),
    AnimalMLKit(
      id: 'dolphin',
      nameFr: 'Dauphin',
      nameEn: 'Dolphin',
      nameEs: 'Delfín',
      scientificName: 'Delphinidae',
      funFactFr: 'Les dauphins peuvent reconnaître leur reflet dans un miroir.',
      emoji: '🐬',
    ),
  ];
}

// ============================================================================
// SERVICE ML KIT UNIFIÉ
// ============================================================================

class MLKitAnimalService {
  // Services ML Kit
  late ImageLabeler _imageLabeler;
  late ObjectDetector _objectDetector;
  late LanguageIdentifier _languageIdentifier;
  OnDeviceTranslator? _translator;
  
  // État
  bool _isInitialized = false;
  String _currentSourceLanguage = 'fr';
  String _currentTargetLanguage = 'en';
  
  MLKitAnimalService() {
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // 1. Image Labeling
      final imageOptions = ImageLabelerOptions(
        confidenceThreshold: 0.7,
      );
      _imageLabeler = ImageLabeler(options: imageOptions);
      
      // 2. Object Detection
      final objectOptions = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: false,
      );
      _objectDetector = ObjectDetector(options: objectOptions);
      
      // 3. Language ID
      _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.6);
      
      _isInitialized = true;
      print('✅ Services ML Kit initialisés');
    } catch (e) {
      print('❌ Erreur initialisation ML Kit: $e');
    }
  }
  
  // ============================================================================
  // 1. IMAGE LABELING - Détection d'animaux par photo
  // ============================================================================
  
  Future<Map<String, dynamic>?> detectAnimalFromImage(File imageFile) async {
    if (!_isInitialized) await _initializeServices();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      
      if (labels.isNotEmpty) {
        final topLabel = labels[0];
        
        // Chercher l'animal correspondant dans la base
        final matchedAnimal = AnimalsDatabaseMLKit.animals.firstWhere(
          (animal) => 
              topLabel.label.toLowerCase().contains(animal.nameEn.toLowerCase()) ||
              animal.nameEn.toLowerCase().contains(topLabel.label.toLowerCase()),
          orElse: () => AnimalsDatabaseMLKit.animals[0],
        );
        
        return {
          'detectedLabel': topLabel.label,
          'confidence': topLabel.confidence,
          'matchedAnimal': matchedAnimal,
        };
      }
      return null;
    } catch (e) {
      print('❌ Erreur détection image: $e');
      return null;
    }
  }
  
  // ============================================================================
  // 2. OBJECT DETECTION - Détection avec localisation
  // ============================================================================
  
  Future<Map<String, dynamic>?> detectAnimalWithLocation(File imageFile) async {
    if (!_isInitialized) await _initializeServices();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final objects = await _objectDetector.processImage(inputImage);
      
      if (objects.isNotEmpty) {
        final topObject = objects[0];
        final label = topObject.labels.isNotEmpty ? topObject.labels[0].text : null;
        
        if (label != null) {
          final matchedAnimal = AnimalsDatabaseMLKit.animals.firstWhere(
            (animal) => label.toLowerCase().contains(animal.nameEn.toLowerCase()),
            orElse: () => AnimalsDatabaseMLKit.animals[0],
          );
          
          return {
            'detectedLabel': label,
            'confidence': topObject.labels[0].confidence,
            'matchedAnimal': matchedAnimal,
            'boundingBox': topObject.boundingBox,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur détection objet: $e');
      return null;
    }
  }
  
  // ============================================================================
  // 3. LANGUAGE ID - Détection automatique de la langue
  // ============================================================================
  
  Future<String?> detectLanguage(String text) async {
    if (text.length < 5) return null;
    if (!_isInitialized) await _initializeServices();
    
    try {
      final detectedLanguages = await _languageIdentifier.identifyLanguage(text);
      if (detectedLanguages.isNotEmpty) {
        return detectedLanguages[0];
      }
      return null;
    } catch (e) {
      print('❌ Erreur détection langue: $e');
      return null;
    }
  }
  
  // ============================================================================
  // 4. TRANSLATION - Traduction dynamique
  // ============================================================================
  
  Future<void> initializeTranslator(String sourceLang, String targetLang) async {
    _currentSourceLanguage = sourceLang;
    _currentTargetLanguage = targetLang;
    
    final source = _getTranslateLanguage(sourceLang);
    final target = _getTranslateLanguage(targetLang);
    
    if (source != null && target != null) {
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      print('✅ Traducteur initialisé: $sourceLang -> $targetLang');
    }
  }
  
  Future<String?> translateText(String text, {String? targetLanguage}) async {
    if (_translator == null) {
      final target = targetLanguage ?? _currentTargetLanguage;
      await initializeTranslator(_currentSourceLanguage, target);
    }
    
    try {
      final translated = await _translator!.translateText(text);
      return translated;
    } catch (e) {
      print('❌ Erreur traduction: $e');
      return null;
    }
  }
  
  TranslateLanguage? _getTranslateLanguage(String code) {
    switch (code) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'es': return TranslateLanguage.spanish;
      case 'ar': return TranslateLanguage.arabic;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      default: return null;
    }
  }
  
  void dispose() {
    _imageLabeler.close();
    _objectDetector.close();
    _languageIdentifier.close();
    _translator?.close();
  }
}

// ============================================================================
// ÉCRAN PRINCIPAL DU JEU
// ============================================================================

class AnimalWritingGameMLKit extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const AnimalWritingGameMLKit({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<AnimalWritingGameMLKit> createState() => _AnimalWritingGameMLKitState();
}

class _AnimalWritingGameMLKitState extends State<AnimalWritingGameMLKit>
    with TickerProviderStateMixin {
  
  // Services
  late MLKitAnimalService _mlKitService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speechToText;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Contrôleurs d'animation
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanAnimationController;
  late TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();
  
  // État du jeu
  List<AnimalMLKit> _availableAnimals = [];
  AnimalMLKit? _currentAnimal;
  int _currentIndex = 0;
  int _score = 0;
  int _totalAnswered = 0;
  bool _isAnswering = false;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;
  String _inputMode = 'write';
  String _selectedLanguage = 'fr';
  
  // État du microphone
  bool _isListening = false;
  String _recognizedText = '';
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  
  // État ML Kit
  bool _isProcessingImage = false;
  bool _isDetectingLanguage = false;
  bool _isTranslating = false;
  String? _detectedLanguage;
  File? _capturedImage;
  String _translatedWord = '';
  bool _showTranslation = false;
  
  // Mode de capture
  String _captureMode = 'camera'; // 'camera' or 'gallery'
  
  // Langues disponibles
  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'color': '#2C3E50'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'color': '#1E5B8A'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'color': '#C60B1E'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'color': '#000000'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'color': '#009246'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'color': '#00732F'},
  ];

  @override
  void initState() {
    super.initState();
    _initServices();
    _initControllers();
    _initGame();
    _loadSavedData();
  }
  
  void _initServices() {
    _mlKitService = MLKitAnimalService();
    _speechToText = stt.SpeechToText();
    _initSpeechToText();
    _initTTS();
  }
  
  void _initControllers() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textController = TextEditingController();
  }
  
  Future<void> _initSpeechToText() async {
    _speechAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
          });
          _processVoiceInput();
        }
      },
    );
  }
  
  Future<void> _initTTS() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }
  
  void _initGame() {
    _availableAnimals = List.from(AnimalsDatabaseMLKit.animals);
    _availableAnimals.shuffle();
    _currentAnimal = _availableAnimals.isNotEmpty ? _availableAnimals[0] : null;
    _score = 0;
    _currentIndex = 0;
    _totalAnswered = 0;
    _textController.clear();
    _feedbackMessage = null;
    _recognizedText = '';
    _capturedImage = null;
    _translatedWord = '';
    _showTranslation = false;
  }
  
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _score = prefs.getInt('score_${widget.childId}') ?? 0;
    setState(() {});
  }
  
  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score_${widget.childId}', _score);
  }
  
  String _getCurrentAnimalName() {
    return _currentAnimal?.getNameInLanguage(_selectedLanguage) ?? '';
  }
  
  // ============================================================================
  // 1. IMAGE LABELING - Prendre une photo et détecter l'animal
  // ============================================================================
  
  Future<void> _takePictureAndDetect() async {
    if (_isAnswering) return;
    
    setState(() {
      _isProcessingImage = true;
      _captureMode = 'camera';
    });
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image == null) {
        setState(() => _isProcessingImage = false);
        return;
      }
      
      _capturedImage = File(image.path);
      await _processDetectedImage();
      
    } catch (e) {
      print('❌ Erreur prise photo: $e');
      setState(() => _isProcessingImage = false);
      _showMessage('Erreur avec la caméra', isError: true);
    }
  }
  
  Future<void> _pickImageFromGallery() async {
    if (_isAnswering) return;
    
    setState(() {
      _isProcessingImage = true;
      _captureMode = 'gallery';
    });
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image == null) {
        setState(() => _isProcessingImage = false);
        return;
      }
      
      _capturedImage = File(image.path);
      await _processDetectedImage();
      
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      setState(() => _isProcessingImage = false);
      _showMessage('Erreur lors de la sélection', isError: true);
    }
  }
  
  Future<void> _processDetectedImage() async {
    if (_capturedImage == null) {
      setState(() => _isProcessingImage = false);
      return;
    }
    
    try {
      // Utiliser Object Detection pour meilleure précision
      final result = await _mlKitService.detectAnimalWithLocation(_capturedImage!);
      
      if (result != null && result['matchedAnimal'] != null) {
        final detectedAnimal = result['matchedAnimal'] as AnimalMLKit;
        final confidence = ((result['confidence'] as double) * 100).toInt();
        
        _showMessage('🔍 Détecté: ${detectedAnimal.nameFr} (confiance $confidence%)');
        
        // Vérifier si c'est l'animal attendu
        if (detectedAnimal.id == _currentAnimal?.id) {
          _handleCorrectAnswer();
        } else {
          setState(() {
            _feedbackMessage = '🔍 Je vois: ${detectedAnimal.nameFr}. Essaie de trouver ${_currentAnimal?.nameFr} !';
            _feedbackColor = Colors.blue;
          });
        }
      } else {
        _showMessage('Je ne reconnais pas cet animal. Essaie avec un autre angle !', isError: true);
      }
    } catch (e) {
      print('❌ Erreur traitement image: $e');
      _showMessage('Erreur de reconnaissance', isError: true);
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }
  
  // ============================================================================
  // 2. OBJECT DETECTION - Choisir entre caméra et galerie
  // ============================================================================
  
  void _handleCorrectAnswer() {
  _score += 10;
  _totalAnswered++;
  _confettiController.play();
  _playSuccessFeedback();
  
  setState(() {
    _feedbackMessage = '✅ Bravo ! C\'est correct ! +10 points';
    _feedbackColor = const Color(0xFF4CAF50);
  });
  
  _saveScore();
  
  Future.delayed(const Duration(milliseconds: 1500), () {
    _nextAnimal();
  });
}
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📸 Scanner un animal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Appareil photo',
                    color: const Color(0xFF6C63FF),
                    onTap: _takePictureAndDetect,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    color: const Color(0xFFFF6B35),
                    onTap: _pickImageFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
  
  // ============================================================================
  // 3. LANGUAGE ID - Détection automatique de la langue
  // ============================================================================
  
  Future<void> _detectAndSetLanguage(String text) async {
    if (text.length < 5) return;
    
    setState(() => _isDetectingLanguage = true);
    
    try {
      final detectedCode = await _mlKitService.detectLanguage(text);
      
      if (detectedCode != null) {
        final isSupported = _languages.any((l) => l['code'] == detectedCode);
        
        if (isSupported && detectedCode != _selectedLanguage) {
          setState(() {
            _selectedLanguage = detectedCode;
            _detectedLanguage = detectedCode;
            _isDetectingLanguage = false;
          });
          
          _showMessage('🌍 Langue détectée: ${_getLanguageName(detectedCode)}');
          await _playSuccessFeedback();
        } else {
          setState(() => _isDetectingLanguage = false);
        }
      } else {
        setState(() => _isDetectingLanguage = false);
      }
    } catch (e) {
      setState(() => _isDetectingLanguage = false);
    }
  }
  
  String _getLanguageName(String code) {
    final languages = {
      'fr': 'Français', 'en': 'Anglais', 'es': 'Espagnol',
      'de': 'Allemand', 'it': 'Italien', 'ar': 'Arabe',
    };
    return languages[code] ?? code;
  }
  
  // ============================================================================
  // 4. TRANSLATION - Traduction dynamique
  // ============================================================================
  
  Future<void> _translateCurrentWord() async {
    if (_currentAnimal == null) return;
    
    setState(() {
      _isTranslating = true;
      _showTranslation = true;
    });
    
    try {
      final currentName = _getCurrentAnimalName();
      await _mlKitService.initializeTranslator(_selectedLanguage, 'en');
      final translated = await _mlKitService.translateText(currentName);
      
      setState(() {
        _translatedWord = translated ?? 'Translation non disponible';
        _isTranslating = false;
      });
    } catch (e) {
      setState(() => _isTranslating = false);
      _showMessage('Erreur de traduction', isError: true);
    }
  }
  
  // ============================================================================
  // LOGIQUE DU JEU
  // ============================================================================
  
  Future<void> _checkAnswer(String userAnswer) async {
    if (_isAnswering || _currentAnimal == null) return;
    
    setState(() => _isAnswering = true);
    
    // Détection automatique de la langue (Language ID)
    await _detectAndSetLanguage(userAnswer);
    
    final correctAnswer = _getCurrentAnimalName();
    final normalizedUser = _normalizeText(userAnswer);
    final normalizedCorrect = _normalizeText(correctAnswer);
    
    bool isCorrect = normalizedUser == normalizedCorrect;
    
    if (!isCorrect && _inputMode == 'speak' && normalizedUser.length > 2) {
      final distance = _levenshteinDistance(normalizedUser, normalizedCorrect);
      final maxLength = max(normalizedUser.length, normalizedCorrect.length);
      if (maxLength > 0) {
        final similarity = 1 - (distance / maxLength);
        isCorrect = similarity > 0.7;
      }
    }
    
    if (isCorrect) {
      _score += 10;
      _totalAnswered++;
      _confettiController.play();
      await _playSuccessFeedback();
      
      setState(() {
        _feedbackMessage = '✅ Bravo ! C\'est correct ! +10 points';
        _feedbackColor = const Color(0xFF4CAF50);
      });
      
      await _saveScore();
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextAnimal();
      });
    } else {
      await _playErrorFeedback();
      
      setState(() {
        _feedbackMessage = '❌ Oups ! La réponse était : $correctAnswer';
        _feedbackColor = const Color(0xFFE53935);
      });
      
      _shakeController.forward().then((_) => _shakeController.reverse());
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        _nextAnimal();
      });
    }
    
    setState(() => _isAnswering = false);
  }
  
  Future<void> _playSuccessFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      await _flutterTts.speak(_getSuccessMessage());
    } catch (e) {}
  }
  
  Future<void> _playErrorFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {}
  }
  
  String _getSuccessMessage() {
    const messages = [
      'Bravo ! Tu as trouvé !',
      'Excellent ! Continue comme ça !',
      'Super ! Tu es un champion !',
      'Magnifique ! +10 points !',
    ];
    return messages[Random().nextInt(messages.length)];
  }
  
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );
    
    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }
  
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i');
  }
  
  Future<void> _pronounceWord() async {
    final word = _getCurrentAnimalName();
    if (word.isNotEmpty) {
      final ttsCode = _selectedLanguage == 'fr' ? 'fr-FR' : 'en-US';
      await _flutterTts.setLanguage(ttsCode);
      await _flutterTts.speak(word);
    }
  }
  
  void _nextAnimal() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _availableAnimals.length) {
        _currentAnimal = _availableAnimals[_currentIndex];
      } else {
        _showGameCompleteDialog();
      }
      _textController.clear();
      _feedbackMessage = null;
      _isAnswering = false;
      _recognizedText = '';
      _capturedImage = null;
      _translatedWord = '';
      _showTranslation = false;
    });
  }
  
  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Félicitations ! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/trophy.json',
              width: 100,
              height: 100,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text(
              'Score final : $_score points',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu as répondu à $_totalAnswered questions',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
              setState(() {});
            },
            child: const Text('Rejouer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Menu principal'),
          ),
        ],
      ),
    );
  }
  
  void _changeLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
      _textController.clear();
      _feedbackMessage = null;
      _recognizedText = '';
      _translatedWord = '';
      _showTranslation = false;
    });
  }
  
  void _submitAnswer() {
    final answer = _textController.text.trim();
    if (answer.isNotEmpty && !_isAnswering) {
      _textController.clear();
      _checkAnswer(answer);
    }
  }
  
  // Microphone
  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    if (_isListening) { await _stopListening(); return; }
    
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });
    _pulseController.repeat(reverse: true);
    
    final language = _languages.firstWhere((l) => l['code'] == _selectedLanguage);
    final speechCode = language['code'] == 'fr' ? 'fr_FR' : 'en_US';
    
    await _speechToText.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
      },
      localeId: speechCode,
      listenFor: const Duration(seconds: 4),
      pauseFor: const Duration(seconds: 1),
      partialResults: true,
      onSoundLevelChange: (level) {
        setState(() => _soundLevel = level.clamp(0.0, 100.0));
      },
    );
  }
  
  Future<void> _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _pulseController.stop();
      });
      _processVoiceInput();
    }
  }
  
  Future<void> _processVoiceInput() async {
    if (_recognizedText.isNotEmpty && !_isAnswering) {
      await _checkAnswer(_recognizedText);
      setState(() => _recognizedText = '');
    }
  }
  
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  String _getAnimalEmoji(String animalId) {
    final animal = AnimalsDatabaseMLKit.animals.firstWhere(
      (a) => a.id == animalId,
      orElse: () => AnimalsDatabaseMLKit.animals[0],
    );
    return animal.emoji;
  }
  
  // ✅ Code corrigé
List<Color> _getLanguageGradientColors() {
  final language = _languages.firstWhere((l) => l['code'] == _selectedLanguage);
  
  // Utiliser des couleurs prédéfinies au lieu de parser
  switch (_selectedLanguage) {
    case 'fr':
      return [const Color(0xFF2C3E50), const Color(0xFF2C3E50).withOpacity(0.7)];
    case 'en':
      return [const Color(0xFF1E5B8A), const Color(0xFF1E5B8A).withOpacity(0.7)];
    case 'es':
      return [const Color(0xFFC60B1E), const Color(0xFFC60B1E).withOpacity(0.7)];
    case 'de':
      return [const Color(0xFF000000), const Color(0xFF000000).withOpacity(0.7)];
    case 'it':
      return [const Color(0xFF009246), const Color(0xFF009246).withOpacity(0.7)];
    case 'ar':
      return [const Color(0xFF00732F), const Color(0xFF00732F).withOpacity(0.7)];
    default:
      return [const Color(0xFF6C63FF), const Color(0xFF6C63FF).withOpacity(0.7)];
  }
}
  
  // ============================================================================
  // BUILD UI
  // ============================================================================
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getLanguageGradientColors(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet),
              _buildProgressBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildMLKitButtonsRow(),
                      const SizedBox(height: 16),
                      _buildLanguageSelector(),
                      const SizedBox(height: 20),
                      _buildAnimalCard(),
                      const SizedBox(height: 24),
                      _buildAnimalNameHint(),
                      const SizedBox(height: 20),
                      _buildInputModeToggle(),
                      const SizedBox(height: 16),
                      if (_inputMode == 'write')
                        _buildWritingInput()
                      else
                        _buildSpeakingInput(),
                      const SizedBox(height: 16),
                      if (_feedbackMessage != null)
                        _buildFeedbackMessage(),
                      const SizedBox(height: 16),
                      if (_showTranslation && _translatedWord.isNotEmpty)
                        _buildTranslationSection(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMLKitButtonsRow() {
    return Row(
      children: [
        // Bouton Scanner (Image Labeling + Object Detection)
        Expanded(
          child: _buildMLKitButton(
            icon: Icons.camera_alt,
            label: 'Scanner',
            color: const Color(0xFF6C63FF),
            onPressed: _showImageSourceDialog,
            isLoading: _isProcessingImage,
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Langue (Language ID)
        Expanded(
          child: _buildMLKitButton(
            icon: Icons.language,
            label: _isDetectingLanguage ? 'Détection...' : 'Auto Langue',
            color: const Color(0xFF4CAF50),
            onPressed: _isDetectingLanguage ? null : () {
              if (_recognizedText.isNotEmpty) {
                _detectAndSetLanguage(_recognizedText);
              } else {
                _showMessage('Parle ou écris d\'abord !', isError: true);
              }
            },
            isLoading: _isDetectingLanguage,
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Traduction (Translation)
        Expanded(
          child: _buildMLKitButton(
            icon: Icons.translate,
            label: _isTranslating ? 'Traduction...' : 'Traduire',
            color: const Color(0xFFFF6B35),
            onPressed: _isTranslating ? null : _translateCurrentWord,
            isLoading: _isTranslating,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMLKitButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: [
              Text(
                'Polyglot Animal ML',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Score: $_score pts',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_currentIndex + 1}/${_availableAnimals.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar() {
    final progress = _availableAnimals.isEmpty 
        ? 0.0 
        : (_currentIndex / _availableAnimals.length).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLanguage == lang['code'];
          return GestureDetector(
            onTap: () => _changeLanguage(lang['code']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAnimalCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: _currentAnimal?.id ?? '',
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentAnimal?.emoji ?? '🐾',
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🐾 Animal ${_currentIndex + 1}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildAnimalNameHint() {
    final name = _getCurrentAnimalName();
    final letterCount = name.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🔍 Indice', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            'Le mot contient $letterCount lettres',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeButton('write', '✏️ Écrire', Icons.edit),
          const SizedBox(width: 8),
          _buildModeButton('speak', '🎤 Parler', Icons.mic),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isSelected = _inputMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _inputMode = mode;
            _recognizedText = '';
            _feedbackMessage = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF6C63FF) : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWritingInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              decoration: InputDecoration(
                hintText: 'Écris le nom de l\'animal...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                suffixIcon: IconButton(
                  onPressed: _submitAnswer,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ),
              onSubmitted: (_) => _submitAnswer(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]')),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSpeakingInput() {
    final normalizedLevel = (_soundLevel / 100).clamp(0.0, 1.0);
    
    return Column(
      children: [
        if (_isListening)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🎤 Je t\'écoute...', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 150 * normalizedLevel,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        if (_recognizedText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Tu as dit :', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        
        GestureDetector(
          onTapDown: (_) => _startListening(),
          onTapUp: (_) => _stopListening(),
          onTapCancel: _stopListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : Colors.white).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: _isListening ? Colors.white : const Color(0xFF6C63FF),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isListening ? '🎤 Relâche pour valider' : '👆 Appuie et maintiens pour parler',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildFeedbackMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _feedbackColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _feedbackColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _feedbackColor == const Color(0xFF4CAF50) 
                ? Icons.check_circle 
                : Icons.error,
            color: _feedbackColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _feedbackMessage!,
              style: TextStyle(color: _feedbackColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTranslationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Traduction en anglais',
                  style: TextStyle(fontSize: 11, color: Colors.purple),
                ),
                Text(
                  _translatedWord,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pronounceWord,
            icon: const Icon(Icons.volume_up),
            label: const Text('Écouter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _textController.clear();
                _recognizedText = '';
                _feedbackMessage = null;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Effacer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _scanAnimationController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _mlKitService.dispose();
    super.dispose();
  }
}