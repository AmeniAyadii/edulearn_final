import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/colorS_item.dart';
import '../../services/ml_kit/mlkit_translation_service.dart';
import '../../services/ml_kit/mlkit_color_detection_service.dart';
import '../../services/ml_kit/mlkit_language_id_service.dart';
import '../../widgets/game/theme_selector.dart';

class ColorLearningGame extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const ColorLearningGame({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<ColorLearningGame> createState() => _ColorLearningGameState();
}

class _ColorLearningGameState extends State<ColorLearningGame>
    with TickerProviderStateMixin {
  // Services ML Kit
  final MLKitTranslationService _translationService = MLKitTranslationService();
  final MLKitColorDetectionService _colorDetectionService = MLKitColorDetectionService();
  final MLKitLanguageIdService _languageIdService = MLKitLanguageIdService();
  
  // Services audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  
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
  String _gameTheme = 'classic'; // classic, camera, quiz
  List<ColorItem> _availableColors = [];
  ColorItem? _currentColor;
  int _currentIndex = 0;
  int _score = 0;
  int _totalAnswered = 0;
  bool _isAnswering = false;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;
  String _inputMode = 'write';
  
  // État ML Kit
  bool _isTranslating = false;
  bool _isRecognizing = false;
  String? _translatedText;
  String? _detectedLanguage;
  File? _capturedImage;
  String? _cameraDetectedColor;
  
  // État du microphone
  bool _isListening = false;
  String _recognizedText = "";
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  
  // Quiz state
  List<ColorItem> _quizOptions = [];
  String _quizQuestion = '';
  
  // Statistiques
  int _totalColors = 0;
  
  // Liste des langues
  final List<Map<String, dynamic>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'color': const Color(0xFFE74C3C)},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'color': const Color(0xFF3498DB)},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'color': const Color(0xFFE67E22)},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'color': const Color(0xFF000000)},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'color': const Color(0xFF27AE60)},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'color': const Color(0xFF2980B9)},
  ];
  
  @override
  void initState() {
    super.initState();
    _initControllers();
    _initGame();
    _initTTS();
    _initMLKitServices();
    _initSpeech();
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
  
  Future<void> _initMLKitServices() async {
    await _colorDetectionService.initialize();
    await _languageIdService.initialize();
    await _translationService.downloadModel(_selectedLanguage);
  }
  
 
  
  // ==================== MÉTHODES DE RECONNAISSANCE VOCALE ====================

Future<void> _initSpeech() async {
  _speech = stt.SpeechToText();
  _speechAvailable = await _speech.initialize();
  print('🎤 Speech initialized: $_speechAvailable');
}

Future<void> _startListening() async {
  if (!_speechAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reconnaissance vocale non disponible'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  if (_isListening) {
    await _stopListening();
    return;
  }
  
  bool hasPermission = await _speech.hasPermission;
  if (!hasPermission) {
    hasPermission = await _speech.initialize();
  }
  
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez autoriser le microphone'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  setState(() {
    _isListening = true;
    _recognizedText = "";
    _soundLevel = 0.0;
  });
  _pulseController.repeat(reverse: true);
  
  await _speech.listen(
    onResult: (result) {
      print('🎤 Résultat: ${result.recognizedWords}');
      setState(() {
        _recognizedText = result.recognizedWords;
      });
    },
    listenFor: const Duration(seconds: 5),
    pauseFor: const Duration(seconds: 2),
    partialResults: true,
    onSoundLevelChange: (level) {
      setState(() {
        _soundLevel = level;
      });
    },
  );
}

Future<void> _stopListening() async {
  if (_isListening) {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _pulseController.stop();
    });
    
    if (_recognizedText.isNotEmpty) {
      final textToCheck = _recognizedText;
      setState(() {
        _recognizedText = "";
      });
      await _checkAnswer(textToCheck);
    } else if (_recognizedText.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je n\'ai rien entendu. Essaie de parler plus fort !'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
  Future<void> _initTTS() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }
  
  void _initGame() {
    _availableColors = ColorDatabase.shuffledColors;
    _currentColor = _availableColors.isNotEmpty ? _availableColors[0] : null;
    _totalColors = _availableColors.length;
    _currentIndex = 0;
    _totalAnswered = 0;
    _textController.clear();
    _feedbackMessage = null;
    _translatedText = null;
    _capturedImage = null;
    _cameraDetectedColor = null;
    _generateQuiz();
  }
  
  void _generateQuiz() {
    if (_availableColors.isEmpty) return;
    
    // Choisir 4 couleurs aléatoires
    final List<ColorItem> tempColors = List.from(_availableColors);
    tempColors.shuffle();
    _quizOptions = tempColors.take(4).toList();
    
    // Choisir une couleur cible
    final target = _quizOptions[Random().nextInt(_quizOptions.length)];
    _currentColor = target;
    _quizQuestion = 'Quelle est cette couleur ?';
  }
  
  void _changeTheme(String theme) {
    setState(() {
      _gameTheme = theme;
      _capturedImage = null;
      _cameraDetectedColor = null;
      _feedbackMessage = null;
    });
  }
  
  String _getCurrentColorName() {
    return _currentColor?.getNameInLanguage(_selectedLanguage) ?? '';
  }
  
  Color _getCurrentColorValue() {
    return _currentColor?.colorValue ?? Colors.black;
  }
  
  Future<void> _translateColor() async {
    if (_currentColor == null) return;
    
    setState(() {
      _isTranslating = true;
    });
    
    final originalName = _currentColor!.getNameInLanguage('fr');
    final translated = await _translationService.translateText(
      originalName,
      'fr',
      _selectedLanguage,
    );
    
    setState(() {
      _translatedText = translated;
      _isTranslating = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔤 Traduction: "$originalName" → "$translated"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _takePictureForColorDetection() async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;
    
    setState(() {
      _isRecognizing = true;
      _capturedImage = File(image.path);
    });
    
    // Utiliser la nouvelle méthode combinée
    final result = await _colorDetectionService.detectColor(File(image.path));
    
    setState(() {
      _isRecognizing = false;
    });
    
    if (result != null) {
      // Trouver la couleur correspondante dans la base de données
      final matchedColor = ColorDatabase.allColors.firstWhere(
        (color) => color.id == result.colorName,
        orElse: () => ColorDatabase.allColors.firstWhere(
          (color) => color.getNameInLanguage('fr') == result.colorName,
          orElse: () => _availableColors.first,
        ),
      );
      
      setState(() {
        _currentColor = matchedColor;
        _cameraDetectedColor = result.colorName;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📸 Couleur détectée: ${result.colorName} (${(result.confidence * 100).toInt()}%)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucune couleur détectée. Prenez une photo d\'un objet coloré.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isRecognizing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
    );
  }
}
  
  Future<void> _checkAnswer(String userAnswer) async {
    if (_isAnswering || _currentColor == null) return;
    
    setState(() {
      _isAnswering = true;
    });
    
    final correctAnswer = _getCurrentColorName();
    final normalizedUser = _normalizeText(userAnswer);
    final normalizedCorrect = _normalizeText(correctAnswer);
    
    bool isCorrect = normalizedUser == normalizedCorrect;
    
    if (!isCorrect && _inputMode == 'speak' && normalizedUser.isNotEmpty && normalizedCorrect.isNotEmpty) {
      if (normalizedUser.contains(normalizedCorrect) || normalizedCorrect.contains(normalizedUser)) {
        isCorrect = true;
      } else {
        final distance = _levenshteinDistance(normalizedUser, normalizedCorrect);
        final maxLength = max(normalizedUser.length, normalizedCorrect.length);
        if (maxLength > 0) {
          final similarity = 1 - (distance / maxLength);
          isCorrect = similarity > 0.65;
        }
      }
    }
    
    if (isCorrect) {
      _score += _currentColor!.basePoints;
      _totalAnswered++;
      _confettiController.play();
      await _playSound(true);
      
      setState(() {
        _feedbackMessage = '✅ Bravo ! +${_currentColor!.basePoints} points';
        _feedbackColor = const Color(0xFF4CAF50);
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextColor();
      });
    } else {
      await _playSound(false);
      
      setState(() {
        _feedbackMessage = '❌ Oups ! La réponse était : $correctAnswer';
        _feedbackColor = const Color(0xFFE53935);
      });
      
      _shakeController.forward().then((_) => _shakeController.reverse());
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        _nextColor();
      });
    }
    
    setState(() {
      _isAnswering = false;
    });
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
        .replaceAll('ç', 'c')
        .replaceAll(' ', '')
        .replaceAll('-', '');
  }
  
  Future<void> _playSound(bool success) async {
    try {
      final sound = success ? 'sounds/success.mp3' : 'sounds/error.mp3';
      await _audioPlayer.play(AssetSource(sound));
    } catch (e) {}
  }
  
  Future<void> _pronounceWord() async {
    final word = _getCurrentColorName();
    if (word.isNotEmpty) {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.speak(word);
    }
  }
  
  void _nextColor() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _availableColors.length) {
        _currentColor = _availableColors[_currentIndex];
        if (_gameTheme == 'quiz') {
          _generateQuiz();
        }
      } else {
        _showGameCompleteDialog();
      }
      _textController.clear();
      _feedbackMessage = null;
      _isAnswering = false;
      _recognizedText = "";
      _capturedImage = null;
      _cameraDetectedColor = null;
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
            Text('Score final : $_score points', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tu as appris $_totalAnswered couleurs !'),
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
            child: const Text('Menu'),
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
    });
    _translationService.downloadModel(code);
  }
  
  void _submitAnswer() {
    final answer = _textController.text.trim();
    if (answer.isNotEmpty && !_isAnswering) {
      _textController.clear();
      _checkAnswer(answer);
    }
  }
  
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
            colors: _getThemeGradientColors(),
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
                      ThemeSelector(
                        selectedTheme: _gameTheme,
                        onThemeSelected: _changeTheme,
                      ),
                      const SizedBox(height: 20),
                      _buildLanguageSelector(),
                      const SizedBox(height: 20),
                      _buildColorCard(),
                      const SizedBox(height: 16),
                      
                      // Traduction ML Kit
                      _buildTranslationButton(),
                      const SizedBox(height: 16),
                      
                      // Mode caméra
                      if (_gameTheme == 'camera')
                        _buildCameraMode(),
                      
                      // Mode quiz
                      if (_gameTheme == 'quiz')
                        _buildQuizMode(),
                      
                      // Mode classique
                      if (_gameTheme == 'classic') ...[
                        _buildFunFactCard(),
                        const SizedBox(height: 16),
                        _buildPsychologyCard(),
                        const SizedBox(height: 20),
                        _buildHintCard(),
                        const SizedBox(height: 20),
                        _buildInputModeToggle(),
                        const SizedBox(height: 16),
                        if (_inputMode == 'write') _buildWritingInput() else _buildSpeakingInput(),
                      ],
                      
                      const SizedBox(height: 16),
                      if (_feedbackMessage != null) _buildFeedbackMessage(),
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
  
  Widget _buildTranslationButton() {
    return GestureDetector(
      onTap: _translateColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isTranslating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.translate, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isTranslating ? 'Traduction en cours...' : '🔤 Traduire avec ML Kit',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraMode() {
    return Column(
      children: [
        if (_capturedImage != null)
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_capturedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (_cameraDetectedColor != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCurrentColorValue().withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🔍 Couleur détectée: $_cameraDetectedColor',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isRecognizing ? null : _takePictureForColorDetection,
          icon: _isRecognizing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt),
          label: Text(_isRecognizing ? 'Analyse en cours...' : '📸 Détecter une couleur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Prenez une photo d\'un objet coloré',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildQuizMode() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                _quizQuestion,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _quizOptions.map((color) {
                  return GestureDetector(
                    onTap: () => _checkAnswer(color.getNameInLanguage(_selectedLanguage)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: color.colorValue,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        color.getNameInLanguage(_selectedLanguage),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  List<Color> _getThemeGradientColors() {
    if (_currentColor != null && _gameTheme != 'quiz') {
      final color = _getCurrentColorValue();
      return [color, color.withOpacity(0.7)];
    }
    final language = _languages.firstWhere((l) => l['code'] == _selectedLanguage);
    final Color baseColor = language['color'] as Color;
    return [baseColor, baseColor.withOpacity(0.7)];
  }
  
  Widget _buildHeader(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'Polyglot Colors',
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
                const Icon(Icons.color_lens, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_currentIndex + 1}/$_totalColors',
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
    final progress = _availableColors.isEmpty ? 0.0 : (_currentIndex / _availableColors.length).clamp(0.0, 1.0);
    
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
      height: 50,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Text(lang['flag'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    lang['name'] as String,
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
  
  Widget _buildColorCard() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: _getCurrentColorValue(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentColorValue().withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentColor?.emoji ?? '🎨',
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_translatedText != null && _gameTheme == 'classic')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Traduction: $_translatedText',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🎨 Couleur ${_currentIndex + 1}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildFunFactCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡Savais-tu ?', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _currentColor?.getFunFact(_selectedLanguage) ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPsychologyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧠 Psychologie des couleurs', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _currentColor?.getPsychology(_selectedLanguage) ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHintCard() {
    final name = _getCurrentColorName();
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
          Text('Le mot contient $letterCount lettres', style: const TextStyle(color: Colors.white, fontSize: 14)),
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
            _feedbackMessage = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF6C63FF) : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            ),
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              decoration: InputDecoration(
                hintText: 'Écris la couleur...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                suffixIcon: IconButton(
                  onPressed: _submitAnswer,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitAnswer(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSpeakingInput() {
  return Column(
    children: [
      if (_isListening)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.mic, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text('🎤 Je t\'écoute...', style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _soundLevel,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  color: Colors.green,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      
      if (_recognizedText.isNotEmpty && !_isListening)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('📝 Tu as dit :', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
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
                  size: 45,
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
        style: const TextStyle(color: Colors.white70, fontSize: 13),
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
          Icon(_feedbackColor == const Color(0xFF4CAF50) ? Icons.check_circle : Icons.error, color: _feedbackColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_feedbackMessage!, style: TextStyle(color: _feedbackColor, fontSize: 13))),
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Écouter', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
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
    _speech.stop();
    _translationService.dispose();
    _colorDetectionService.dispose();
    _languageIdService.dispose();
    super.dispose();
  }
}