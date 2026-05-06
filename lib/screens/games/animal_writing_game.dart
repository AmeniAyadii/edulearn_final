import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import '../../models/game_animal.dart';

class AnimalWritingGame extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const AnimalWritingGame({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<AnimalWritingGame> createState() => _AnimalWritingGameState();
}

class _AnimalWritingGameState extends State<AnimalWritingGame>
    with TickerProviderStateMixin {
  // Services
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speechToText;
  
  // ML Kit Services
  late ImageLabeler _imageLabeler;
  OnDeviceTranslator? _translator;
  late LanguageIdentifier _languageIdentifier;
  
  // Contrôleurs
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();
  
  // État du jeu
  String _selectedLanguage = 'fr';
  List<GameAnimal> _availableAnimals = [];
  GameAnimal? _currentAnimal;
  int _currentIndex = 0;
  int _score = 0;
  int _totalAnswered = 0;
  bool _isAnswering = false;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;
  String _inputMode = 'write';
  
  // État du microphone
  bool _isListening = false;
  String _recognizedText = '';
  bool _speechAvailable = false;
  String _speechError = '';
  double _soundLevel = 0.0;
  
  // État ML Kit - Image Labeling
  bool _isProcessingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // État ML Kit - Translation
  bool _isTranslating = false;
  final List<Map<String, String>> _mlKitLanguages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
  ];
  
  // État ML Kit - Language ID
  bool _isDetectingLanguage = false;
  
  // Liste des langues originales
  final List<Map<String, dynamic>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'color': const Color(0xFF2C3E50), 'speechCode': 'fr_FR', 'ttsCode': 'fr-FR'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'color': const Color(0xFF1E5B8A), 'speechCode': 'en_US', 'ttsCode': 'en-US'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'color': const Color(0xFFC60B1E), 'speechCode': 'es_ES', 'ttsCode': 'es-ES'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'color': const Color(0xFF000000), 'speechCode': 'de_DE', 'ttsCode': 'de-DE'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'color': const Color(0xFF009246), 'speechCode': 'it_IT', 'ttsCode': 'it-IT'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'color': const Color(0xFF006600), 'speechCode': 'pt_PT', 'ttsCode': 'pt-PT'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'color': const Color(0xFF0039A6), 'speechCode': 'ru_RU', 'ttsCode': 'ru-RU'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'color': const Color(0xFFDE2910), 'speechCode': 'zh_CN', 'ttsCode': 'zh-CN'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇦🇪', 'color': const Color(0xFF00732F), 'speechCode': 'ar_SA', 'ttsCode': 'ar-SA'},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initMLKitServices();
    _initGame();
    _initTTS();
    _initSpeechToText();
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
    _textController = TextEditingController();
  }
  
  // ============================================================================
  // INITIALISATION DES SERVICES ML KIT
  // ============================================================================
  
  Future<void> _initMLKitServices() async {
    // 1. Image Labeling
    final options = ImageLabelerOptions(
      confidenceThreshold: 0.7,
    );
    _imageLabeler = ImageLabeler(options: options);
    
    // 2. Language ID
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.6);
    
    // 3. Translation (initialisé à la demande)
    print('✅ Services ML Kit initialisés');
  }
  
  // ============================================================================
  // 1. IMAGE LABELING - Détection d'animaux par photo
  // ============================================================================
  
  Future<void> _takePictureAndDetect() async {
    if (_isAnswering) return;
    
    setState(() => _isProcessingImage = true);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image == null) {
        setState(() => _isProcessingImage = false);
        return;
      }
      
      final inputImage = InputImage.fromFile(File(image.path));
      final labels = await _imageLabeler.processImage(inputImage);
      
      setState(() => _isProcessingImage = false);
      
      if (labels.isNotEmpty) {
        final topLabel = labels[0];
        final detectedAnimal = topLabel.label.toLowerCase();
        final confidence = (topLabel.confidence * 100).toInt();
        
        print('🔍 Animal détecté: $detectedAnimal (confiance: $confidence%)');
        
        _showMessage('🔍 Je vois: $detectedAnimal (confiance $confidence%)');
        
        // Vérifier si l'animal détecté correspond à l'animal attendu
        final correctAnswer = _getCurrentAnimalName().toLowerCase();
        
        if (detectedAnimal.contains(correctAnswer) || correctAnswer.contains(detectedAnimal)) {
          _handleCorrectAnswer();
        } else {
          _showHintFromLabels(labels);
        }
      } else {
        _showMessage('Je ne vois pas d\'animal. Essaie encore !', isError: true);
      }
    } catch (e) {
      print('Erreur détection: $e');
      setState(() => _isProcessingImage = false);
      _showMessage('Erreur de détection. Réessaie !', isError: true);
    }
  }
  
  void _showHintFromLabels(List<ImageLabel> labels) {
    final hints = labels.take(2).map((l) => l.label).join(' ou ');
    setState(() {
      _feedbackMessage = '🔍 Je vois: $hints. Essaie encore !';
      _feedbackColor = Colors.blue;
    });
  }
  
  // ============================================================================
  // 2. TRANSLATION - Traduction dynamique des noms d'animaux
  // ============================================================================
  
  Future<void> _addNewLanguage(String languageCode) async {
    if (_currentAnimal == null) return;
    
    setState(() => _isTranslating = true);
    
    try {
      final sourceLang = _getTranslateLanguage('fr');
      final targetLang = _getTranslateLanguage(languageCode);
      
      if (sourceLang == null || targetLang == null) {
        _showMessage('Langue non supportée', isError: true);
        return;
      }
      
      final sourceName = _currentAnimal!.translations['fr']?.name ?? '';
      if (sourceName.isEmpty) return;
      
      final translator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );
      
      final translatedName = await translator.translateText(sourceName);
      await translator.close();
      
      // Ajouter la traduction à l'animal actuel
      _currentAnimal!.translations[languageCode] = AnimalTranslation(
        name: translatedName,
        imageUrl: _currentAnimal!.translations['fr']?.imageUrl,
      );
      
      setState(() {});
      _showMessage('✅ ${_getLanguageName(languageCode)} ajoutée !');
      
    } catch (e) {
      print('Erreur traduction: $e');
      _showMessage('Erreur de traduction', isError: true);
    } finally {
      setState(() => _isTranslating = false);
    }
  }
  
  String _getLanguageName(String code) {
    final languages = {
      'fr': 'Français', 'en': 'Anglais', 'es': 'Espagnol',
      'de': 'Allemand', 'it': 'Italien', 'pt': 'Portugais',
      'ru': 'Russe', 'zh': 'Chinois', 'ar': 'Arabe',
      'hi': 'Hindi', 'ja': 'Japonais', 'ko': 'Coréen',
    };
    return languages[code] ?? code;
  }
  
  TranslateLanguage? _getTranslateLanguage(String code) {
    switch (code) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'es': return TranslateLanguage.spanish;
      case 'ar': return TranslateLanguage.arabic;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ru': return TranslateLanguage.russian;
      case 'zh': return TranslateLanguage.chinese;
      case 'ja': return TranslateLanguage.japanese;
      case 'hi': return TranslateLanguage.hindi;
      case 'ko': return TranslateLanguage.korean;
      default: return null;
    }
  }
  
  // ============================================================================
  // 3. LANGUAGE ID - Détection automatique de la langue
  // ============================================================================
  
  Future<void> _detectUserLanguage(String text) async {
    if (text.length < 3) return;
    
    setState(() => _isDetectingLanguage = true);
    
    try {
      final detectedLanguages = await _languageIdentifier.identifyLanguage(text);
      
      if (detectedLanguages.isNotEmpty) {
        final detectedCode = detectedLanguages[0];
        
        // Vérifier si la langue est supportée
        final isSupported = _languages.any((l) => l['code'] == detectedCode);
        
        if (isSupported && detectedCode != _selectedLanguage) {
          setState(() {
            _selectedLanguage = detectedCode;
          });
          
          _showMessage('🌍 Langue détectée: ${_getLanguageName(detectedCode)}');
        }
      }
    } catch (e) {
      print('Erreur détection: $e');
    } finally {
      setState(() => _isDetectingLanguage = false);
    }
  }
  
  // ============================================================================
  // LOGIQUE DU JEU
  // ============================================================================
  
  Future<void> _initSpeechToText() async {
    _speechToText = stt.SpeechToText();
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
      onError: (error) {
        setState(() {
          _speechError = error.errorMsg;
          _isListening = false;
          _pulseController.stop();
        });
      },
    );
  }
  
  Future<void> _initTTS() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }
  
  void _initGame() {
    _availableAnimals = List.from(GameAnimalsDatabase.animals);
    _availableAnimals.shuffle();
    _currentAnimal = _availableAnimals.isNotEmpty ? _availableAnimals[0] : null;
    _score = 0;
    _currentIndex = 0;
    _totalAnswered = 0;
    _textController.clear();
    _feedbackMessage = null;
    _recognizedText = '';
  }
  
  String _getCurrentAnimalName() {
    final translation = _currentAnimal?.translations[_selectedLanguage];
    if (translation != null && translation.name.isNotEmpty) {
      return translation.name;
    }
    return _currentAnimal?.getNameInLanguage(_selectedLanguage) ?? '';
  }
  
  void _handleCorrectAnswer() {
    _score += 10;
    _totalAnswered++;
    _confettiController.play();
    _playSound(true);
    _speakFeedback(true);
    
    setState(() {
      _feedbackMessage = '✅ Bravo ! C\'est correct ! +10 points';
      _feedbackColor = const Color(0xFF4CAF50);
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      _nextAnimal();
    });
  }
  
  Future<void> _checkAnswer(String userAnswer) async {
    if (_isAnswering || _currentAnimal == null) return;
    
    setState(() => _isAnswering = true);
    
    // Détecter la langue automatiquement (Language ID)
    await _detectUserLanguage(userAnswer);
    
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
      _handleCorrectAnswer();
    } else {
      _playSound(false);
      _speakFeedback(false);
      
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
  
  Future<void> _playSound(bool success) async {
    try {
      final sound = success ? 'sounds/success.mp3' : 'sounds/error.mp3';
      await _audioPlayer.play(AssetSource(sound));
    } catch (e) {}
  }
  
  Future<void> _speakFeedback(bool success) async {
    try {
      final message = success 
          ? _getSuccessMessage()
          : _getErrorMessage(_getCurrentAnimalName());
      await _flutterTts.speak(message);
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
  
  String _getErrorMessage(String correctAnswer) {
    const messages = [
      'Essayons encore ! La réponse était ',
      'Presque ! C\'était ',
      'La prochaine fois ! Il fallait dire ',
    ];
    return messages[Random().nextInt(messages.length)] + correctAnswer;
  }
  
  Future<void> _pronounceWord() async {
    final word = _getCurrentAnimalName();
    if (word.isNotEmpty) {
      final language = _languages.firstWhere(
        (l) => l['code'] == _selectedLanguage,
        orElse: () => _languages.first,
      );
      final ttsCode = language['ttsCode'] as String;
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
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
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
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    
    final hasPermission = await _speechToText.hasPermission;
    if (!hasPermission) return;
    
    final language = _languages.firstWhere((l) => l['code'] == _selectedLanguage);
    final speechCode = language['speechCode'] as String;
    
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _speechError = '';
    });
    _pulseController.repeat(reverse: true);
    
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
      ),
    );
  }
  
  String _getAnimalEmoji(String animalId) {
    const emojis = {
      'chat': '🐱', 'chien': '🐕', 'lion': '🦁', 'elephant': '🐘',
      'girafe': '🦒', 'tigre': '🐯', 'ours': '🐻', 'singe': '🐒',
    };
    return emojis[animalId.toLowerCase()] ?? '🐾';
  }
  
  List<Color> _getLanguageGradientColors() {
    final language = _languages.firstWhere((l) => l['code'] == _selectedLanguage);
    final Color baseColor = language['color'] as Color;
    return [baseColor, baseColor.withOpacity(0.7)];
  }
  
  // ============================================================================
  // BUILD
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
                      _buildLanguageSelector(),
                      const SizedBox(height: 20),
                      _buildMLKitButtons(),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      _buildPronounceButton(),
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
  
  Widget _buildMLKitButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildMLKitButton(
              icon: Icons.camera_alt,
              label: 'Photo',
              color: Colors.purple,
              onPressed: _isProcessingImage ? null : _takePictureAndDetect,
              isLoading: _isProcessingImage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMLKitButton(
              icon: Icons.language,
              label: _isTranslating ? 'Traduction...' : 'Nouvelle langue',
              color: Colors.orange,
              onPressed: _isTranslating ? null : () => _showLanguagePicker(),
              isLoading: _isTranslating,
            ),
          ),
        ],
      ),
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
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajouter une langue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _mlKitLanguages.length,
                itemBuilder: (context, index) {
                  final lang = _mlKitLanguages[index];
                  final isAdded = _currentAnimal?.translations.containsKey(lang['code']) ?? false;
                  
                  return ListTile(
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(lang['name']!),
                    subtitle: Text(lang['code']!),
                    trailing: isAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: isAdded
                        ? null
                        : () {
                            Navigator.pop(context);
                            _addNewLanguage(lang['code']!);
                          },
                  );
                },
              ),
            ),
          ],
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
                'Polyglot Animal',
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageSelector() {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLanguage == lang['code'];
          return GestureDetector(
            onTap: () => _changeLanguage(lang['code'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Text(lang['flag'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    lang['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
                  ),
                  child: ClipOval(
                    child: _currentAnimal?.translations[_selectedLanguage]?.imageUrl != null
                        ? Image.asset(
                            _currentAnimal!.translations[_selectedLanguage]!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(_getAnimalEmoji(_currentAnimal!.id), style: const TextStyle(fontSize: 80)),
                            ),
                          )
                        : Center(
                            child: Text(_getAnimalEmoji(_currentAnimal?.id ?? ''), style: const TextStyle(fontSize: 80)),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('🐾 Animal ${_currentIndex + 1}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('🔍 Indice', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Le mot contient $letterCount lettres', style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _buildInputModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(40)),
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
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? const Color(0xFF6C63FF) : Colors.white)),
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
                    decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitAnswer(),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]'))],
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('🎤 Je t\'écoute...', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  child: Row(
                    children: [
                      Container(
                        width: 150 * normalizedLevel,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)),
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('Tu as dit :', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('"$_recognizedText"', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Colors.white,
                    boxShadow: [BoxShadow(color: (_isListening ? Colors.red : Colors.white).withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 50, color: _isListening ? Colors.white : const Color(0xFF6C63FF)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(_isListening ? '🎤 Relâche pour valider' : '👆 Appuie et maintiens pour parler', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
          Icon(_feedbackColor == const Color(0xFF4CAF50) ? Icons.check_circle : Icons.error, color: _feedbackColor),
          const SizedBox(width: 12),
          Expanded(child: Text(_feedbackMessage!, style: TextStyle(color: _feedbackColor, fontSize: 14))),
        ],
      ),
    );
  }
  
  Widget _buildPronounceButton() {
    return GestureDetector(
      onTap: _pronounceWord,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Écouter la prononciation', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _imageLabeler.close();
    _translator?.close();
    _languageIdentifier.close();
    super.dispose();
  }
}