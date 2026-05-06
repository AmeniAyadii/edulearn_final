import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/food_item.dart';
import '../../widgets/game/category_selector.dart';
import '../../services/ml_kit/mlkit_translation_service.dart';
import '../../services/ml_kit/mlkit_image_labeling_service.dart';
import '../../services/ml_kit/mlkit_language_id_service.dart';
import '../../services/ml_kit/mlkit_ocr_service.dart';

class FoodLearningGame extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const FoodLearningGame({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<FoodLearningGame> createState() => _FoodLearningGameState();
}

class _FoodLearningGameState extends State<FoodLearningGame >
    with TickerProviderStateMixin {
  // Services ML Kit
  final MLKitTranslationService _translationService = MLKitTranslationService();
  final MLKitImageLabelingService _imageLabelingService = MLKitImageLabelingService();
  final MLKitLanguageIdService _languageIdService = MLKitLanguageIdService();
  final MLKitOCRService _ocrService = MLKitOCRService();
  
  // Services audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
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
  String _selectedCategory = 'fruit';
  List<FoodItem> _availableFoods = [];
  FoodItem? _currentFood;
  int _currentIndex = 0;
  int _score = 0;
  int _totalAnswered = 0;
  bool _isAnswering = false;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;
  String _inputMode = 'write';
  
  // Mode de jeu
  String _gameMode = 'classic'; // classic, camera, ocr
  
  // État ML Kit
  bool _isTranslating = false;
  bool _isRecognizing = false;
  String? _translatedText;
  String? _detectedLanguage;
  File? _capturedImage;
  
  // Statistiques
  int _fruitsScore = 0;
  int _vegetablesScore = 0;
  int _fruitsAnswered = 0;
  int _vegetablesAnswered = 0;
  
  // Liste des langues
  final List<Map<String, dynamic>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'color': const Color(0xFF2C3E50)},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'color': const Color(0xFF1E5B8A)},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'color': const Color(0xFFC60B1E)},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'color': const Color(0xFF000000)},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'color': const Color(0xFF009246)},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'color': const Color(0xFF006600)},
  ];
  
  @override
  void initState() {
    super.initState();
    _initControllers();
    _initGame();
    _initTTS();
    _initMLKitServices();
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
    await _imageLabelingService.initialize();
    await _languageIdService.initialize();
    await _ocrService.initialize();
    
    // Télécharger le modèle de traduction pour la langue sélectionnée
    await _translationService.downloadModel(_selectedLanguage);
  }
  
  Future<void> _initTTS() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }
  
  void _initGame() {
    _loadCategoryFoods();
    _currentFood = _availableFoods.isNotEmpty ? _availableFoods[0] : null;
    _currentIndex = 0;
    _totalAnswered = 0;
    _textController.clear();
    _feedbackMessage = null;
    _translatedText = null;
    _detectedLanguage = null;
    _capturedImage = null;
  }
  
  void _loadCategoryFoods() {
    if (_selectedCategory == 'fruit') {
      _availableFoods = List.from(FoodDatabase.fruits);
      _availableFoods.shuffle();
      _score = _fruitsScore;
    } else {
      _availableFoods = List.from(FoodDatabase.vegetables);
      _availableFoods.shuffle();
      _score = _vegetablesScore;
    }
  }
  
  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _loadCategoryFoods();
      _currentIndex = 0;
      _totalAnswered = 0;
      _currentFood = _availableFoods.isNotEmpty ? _availableFoods[0] : null;
      _textController.clear();
      _feedbackMessage = null;
    });
  }
  
  void _changeGameMode(String mode) {
    setState(() {
      _gameMode = mode;
      _capturedImage = null;
      _feedbackMessage = null;
    });
  }
  
  String _getCurrentFoodName() {
    return _currentFood?.getNameInLanguage(_selectedLanguage) ?? '';
  }
  
  // ✅ Utilisation de ML Kit Translation
  Future<void> _translateCurrentFood() async {
    if (_currentFood == null) return;
    
    setState(() {
      _isTranslating = true;
    });
    
    final originalName = _currentFood!.getNameInLanguage('fr');
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
  
  // ✅ Utilisation de ML Kit Image Labeling
  Future<void> _takePictureForRecognition() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return;
      
      setState(() {
        _isRecognizing = true;
        _capturedImage = File(image.path);
      });
      
      final result = await _imageLabelingService.recognizeFood(File(image.path));
      
      setState(() {
        _isRecognizing = false;
      });
      
      if (result != null) {
        // Trouver l'aliment correspondant dans la base de données
        final matchedFood = FoodDatabase.allFoods.firstWhere(
          (food) => food.getNameInLanguage('fr') == result.foodName,
          orElse: () => _availableFoods.first,
        );
        
        setState(() {
          _currentFood = matchedFood;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Aliment reconnu: ${result.foodName} (${(result.confidence * 100).toInt()}%)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aliment non reconnu. Réessayez avec une meilleure photo.'),
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
  
  // ✅ Utilisation de ML Kit Language ID
  Future<void> _detectLanguage(String text) async {
    if (text.trim().isEmpty) return;
    
    final result = await _languageIdService.detectLanguage(text);
    
    if (result != null) {
      setState(() {
        _detectedLanguage = '${result.languageName} (${(result.confidence * 100).toInt()}%)';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌐 Langue détectée: ${result.languageName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // ✅ Utilisation de ML Kit OCR
  Future<void> _scanWordWithOCR() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return;
      
      setState(() {
        _isRecognizing = true;
      });
      
      final result = await _ocrService.scanText(File(image.path));
      
      setState(() {
        _isRecognizing = false;
      });
      
      if (result != null && result.firstWord.isNotEmpty) {
        await _checkAnswer(result.firstWord);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucun texte détecté. Assurez-vous que le texte est bien visible.'),
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
    if (_isAnswering || _currentFood == null) return;
    
    setState(() {
      _isAnswering = true;
    });
    
    final correctAnswer = _getCurrentFoodName();
    final normalizedUser = _normalizeText(userAnswer);
    final normalizedCorrect = _normalizeText(correctAnswer);
    
    bool isCorrect = normalizedUser == normalizedCorrect;
    
    // ✅ Utilisation de ML Kit Language ID pour vérifier la langue
    if (!isCorrect && _inputMode == 'speak') {
      final langCheck = await _languageIdService.isCorrectLanguage(userAnswer, _selectedLanguage);
      if (langCheck) {
        // La langue est correcte, vérifier la similarité
        final distance = _levenshteinDistance(normalizedUser, normalizedCorrect);
        final maxLength = max(normalizedUser.length, normalizedCorrect.length);
        if (maxLength > 0) {
          final similarity = 1 - (distance / maxLength);
          isCorrect = similarity > 0.65;
        }
      }
    }
    
    if (isCorrect) {
      _score += _currentFood!.basePoints;
      _totalAnswered++;
      if (_selectedCategory == 'fruit') {
        _fruitsScore = _score;
        _fruitsAnswered++;
      } else {
        _vegetablesScore = _score;
        _vegetablesAnswered++;
      }
      _confettiController.play();
      await _playSound(true);
      
      setState(() {
        _feedbackMessage = '✅ Bravo ! +${_currentFood!.basePoints} points';
        _feedbackColor = const Color(0xFF4CAF50);
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextFood();
      });
    } else {
      await _playSound(false);
      
      setState(() {
        _feedbackMessage = '❌ Oups ! La réponse était : $correctAnswer';
        _feedbackColor = const Color(0xFFE53935);
      });
      
      _shakeController.forward().then((_) => _shakeController.reverse());
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        _nextFood();
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
    final word = _getCurrentFoodName();
    if (word.isNotEmpty) {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.speak(word);
    }
  }
  
  void _nextFood() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _availableFoods.length) {
        _currentFood = _availableFoods[_currentIndex];
      } else {
        _showGameCompleteDialog();
      }
      _textController.clear();
      _feedbackMessage = null;
      _isAnswering = false;
      _translatedText = null;
      _capturedImage = null;
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
            Text('Tu as répondu à $_totalAnswered questions'),
            if (_selectedCategory == 'fruit')
              Text('🍎 Fruits: $_fruitsAnswered/${FoodDatabase.fruits.length}')
            else
              Text('🥕 Légumes: $_vegetablesAnswered/${FoodDatabase.vegetables.length}'),
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
      _detectLanguage(answer); // Utilisation ML Kit Language ID
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
                      CategorySelector(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _changeCategory,
                      ),
                      const SizedBox(height: 20),
                      _buildLanguageSelector(),
                      const SizedBox(height: 20),
                      _buildGameModeSelector(),
                      const SizedBox(height: 20),
                      _buildFoodCard(),
                      const SizedBox(height: 16),
                      
                      // Traduction ML Kit
                      _buildMLKitTranslationButton(),
                      const SizedBox(height: 16),
                      
                      // Mode caméra ML Kit
                      if (_gameMode == 'camera')
                        _buildCameraMode(),
                      
                      // Mode OCR ML Kit
                      if (_gameMode == 'ocr')
                        _buildOCRMode(),
                      
                      // Mode classique
                      if (_gameMode == 'classic') ...[
                        _buildFunFactCard(),
                        const SizedBox(height: 16),
                        _buildHealthBenefitCard(),
                        const SizedBox(height: 20),
                        _buildHintCard(),
                        const SizedBox(height: 20),
                        _buildInputModeToggle(),
                        const SizedBox(height: 16),
                        if (_inputMode == 'write') _buildWritingInput() else _buildSpeakingInputPlaceholder(),
                      ],
                      
                      const SizedBox(height: 16),
                      if (_feedbackMessage != null) _buildFeedbackMessage(),
                      const SizedBox(height: 24),
                      _buildPronounceButton(),
                      
                      // Affichage langue détectée (ML Kit Language ID)
                      if (_detectedLanguage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🌐 Langue détectée: $_detectedLanguage',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      
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
  
  Widget _buildGameModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _buildGameModeButton('classic', '🎮 Classique', Icons.school),
          const SizedBox(width: 8),
          _buildGameModeButton('camera', '📸 Caméra', Icons.camera_alt),
          const SizedBox(width: 8),
          _buildGameModeButton('ocr', '🔍 Scanner', Icons.document_scanner),
        ],
      ),
    );
  }
  
  Widget _buildGameModeButton(String mode, String label, IconData icon) {
    final isSelected = _gameMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeGameMode(mode),
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
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMLKitTranslationButton() {
    return GestureDetector(
      onTap: _translateCurrentFood,
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
        ElevatedButton.icon(
          onPressed: _isRecognizing ? null : _takePictureForRecognition,
          icon: _isRecognizing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt),
          label: Text(_isRecognizing ? 'Reconnaissance en cours...' : '📸 Prendre une photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Prenez une photo d\'un fruit ou légume',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildOCRMode() {
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
        ElevatedButton.icon(
          onPressed: _isRecognizing ? null : _scanWordWithOCR,
          icon: _isRecognizing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner),
          label: Text(_isRecognizing ? 'Scan en cours...' : '🔍 Scanner un mot'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Scannez le nom du fruit/légume écrit',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildSpeakingInputPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Mode vocal à venir',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez le mode "Scanner" pour la reconnaissance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  List<Color> _getLanguageGradientColors() {
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
                'Polyglot Food',
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
                Icon(
                  _selectedCategory == 'fruit' ? Icons.apple : Icons.emoji_food_beverage,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentIndex + 1}/${_availableFoods.length}',
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
    final progress = _availableFoods.isEmpty ? 0.0 : (_currentIndex / _availableFoods.length).clamp(0.0, 1.0);
    
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
  
  Widget _buildFoodCard() {
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
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _capturedImage != null && _gameMode == 'camera' ? '📸' : (_currentFood?.emoji ?? '🍎'),
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_translatedText != null && _gameMode == 'classic')
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
              _selectedCategory == 'fruit' ? '🍎 Fruit ${_currentIndex + 1}' : '🥕 Légume ${_currentIndex + 1}',
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
                const Text('💡 Savais-tu ?', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _currentFood?.getFunFact(_selectedLanguage) ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthBenefitCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌟 Bienfait', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _currentFood?.getHealthBenefit(_selectedLanguage) ?? '',
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
    final name = _getCurrentFoodName();
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
                hintText: 'Écris le nom...',
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
    _translationService.dispose();
    _imageLabelingService.dispose();
    _languageIdService.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}